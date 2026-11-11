-- ============================================
-- SOHBA — Migration 019
-- حسنات لكل نشاط (قيام، أذكار، سنن) عبر transactions
-- ============================================

-- 1. أضف عمود dua_count لـ qiyam_logs
alter table public.qiyam_logs
  add column if not exists dua_count int default 0;

-- 2. unique على transactions(user_id, reference_id) لمنع التكرار
create unique index if not exists transactions_user_ref_uniq
  on public.transactions(user_id, reference_id)
  where reference_id is not null;

-- 3. helper: إعادة حساب إجماليات المستخدم
create or replace function public._recompute_user_totals(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  h bigint;
  s bigint;
  i numeric(10,2);
begin
  if p_user_id is null then return; end if;

  h := coalesce((
    select sum(hasanat) from public.prayer_logs where user_id = p_user_id
  ), 0) + coalesce((
    select sum(amount) from public.transactions
    where user_id = p_user_id and amount > 0
  ), 0);

  s := coalesce((
    select sum(sayyiat) from public.prayer_logs
    where user_id = p_user_id and sayyiat_repented = false
  ), 0);

  i := (h::numeric / 100.0) - (s::numeric / 50.0);

  perform set_config('app.allow_protected_update', 'true', true);

  update public.profiles
  set total_hasanat = h,
      total_sayyiat_unrepented = s::int,
      iman = i,
      updated_at = now()
  where id = p_user_id;
end;
$$;

-- 4. trigger على prayer_logs يستخدم الـ helper
create or replace function public.recompute_totals_on_prayer_log()
returns trigger
language plpgsql
as $$
begin
  perform public._recompute_user_totals(coalesce(new.user_id, old.user_id));
  return coalesce(new, old);
end;
$$;

drop trigger if exists on_prayer_log_change on public.prayer_logs;
create trigger on_prayer_log_change
  after insert or update or delete on public.prayer_logs
  for each row execute function public.recompute_totals_on_prayer_log();

-- 5. trigger على transactions يستخدم نفس الـ helper
create or replace function public.recompute_totals_on_transaction()
returns trigger
language plpgsql
as $$
begin
  perform public._recompute_user_totals(coalesce(new.user_id, old.user_id));
  return coalesce(new, old);
end;
$$;

drop trigger if exists on_transaction_change on public.transactions;
create trigger on_transaction_change
  after insert or update or delete on public.transactions
  for each row execute function public.recompute_totals_on_transaction();

-- 6. RPC: award_hasanat — idempotent + updatable by reference
create or replace function public.award_hasanat(
  p_user_id uuid,
  p_amount int,
  p_type text,
  p_reference_id text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  if p_amount < 0 or p_amount > 1000 then
    raise exception 'Invalid amount: %', p_amount;
  end if;

  if p_type not in (
    'prayer_congregation','prayer_individual','sunnah','qiyam','dhikr',
    'missed_prayer','tawbah','bonus','badge_unlock'
  ) then
    raise exception 'Invalid type: %', p_type;
  end if;

  perform set_config('app.allow_protected_update', 'true', true);

  insert into public.transactions (user_id, type, amount, reference_id)
  values (p_user_id, p_type, p_amount, p_reference_id)
  on conflict (user_id, reference_id) do update
    set amount = excluded.amount;
end;
$$;
grant execute on function public.award_hasanat(uuid, int, text, text) to authenticated;

-- 7. log_qiyam — أضف dua_count
drop function if exists public.log_qiyam(uuid, date, boolean, boolean, boolean, int, int);

create or replace function public.log_qiyam(
  p_user_id uuid,
  p_date date,
  p_witr boolean default null,
  p_shaf boolean default null,
  p_duha boolean default null,
  p_sunnah_rakat int default null,
  p_tahajjud_rakat int default null,
  p_dua_count int default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.qiyam_logs;
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  if p_date < current_date - 1 or p_date > current_date then
    raise exception 'Invalid date: %', p_date;
  end if;

  insert into public.qiyam_logs
    (user_id, date, prayed_witr, prayed_shaf, prayed_duha,
     sunnah_rakat, tahajjud_rakat, dua_count, updated_at)
  values
    (p_user_id, p_date,
     coalesce(p_witr, false), coalesce(p_shaf, false), coalesce(p_duha, false),
     coalesce(p_sunnah_rakat, 0), coalesce(p_tahajjud_rakat, 0),
     coalesce(p_dua_count, 0), now())
  on conflict (user_id, date) do update
    set prayed_witr = coalesce(p_witr, qiyam_logs.prayed_witr),
        prayed_shaf = coalesce(p_shaf, qiyam_logs.prayed_shaf),
        prayed_duha = coalesce(p_duha, qiyam_logs.prayed_duha),
        sunnah_rakat = coalesce(p_sunnah_rakat, qiyam_logs.sunnah_rakat),
        tahajjud_rakat = coalesce(p_tahajjud_rakat, qiyam_logs.tahajjud_rakat),
        dua_count = coalesce(p_dua_count, qiyam_logs.dua_count),
        updated_at = now()
  returning * into v_row;

  return jsonb_build_object(
    'user_id', v_row.user_id,
    'date', v_row.date,
    'witr', v_row.prayed_witr,
    'shaf', v_row.prayed_shaf,
    'duha', v_row.prayed_duha,
    'sunnah_rakat', v_row.sunnah_rakat,
    'tahajjud_rakat', v_row.tahajjud_rakat,
    'dua_count', v_row.dua_count
  );
end;
$$;
grant execute on function public.log_qiyam(uuid, date, boolean, boolean, boolean, int, int, int) to authenticated;

-- 8. trigger: يمنح حسنات القيام + السنن
create or replace function public.on_qiyam_logged()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Witr + Shaf = 30 حسنة
  if new.prayed_witr and new.prayed_shaf then
    perform public.award_hasanat(
      new.user_id, 30, 'qiyam',
      'qiyam_' || new.date::text
    );
  end if;

  -- الدعاء في القيام = 10 لكل دعوة
  if new.dua_count > 0 then
    perform public.award_hasanat(
      new.user_id, new.dua_count * 10, 'qiyam',
      'qiyam_dua_' || new.date::text
    );
  end if;

  -- سنن = 15 لكل ركعتين
  if new.sunnah_rakat >= 2 then
    perform public.award_hasanat(
      new.user_id, (new.sunnah_rakat / 2) * 15, 'sunnah',
      'sunnah_' || new.date::text
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_on_qiyam_logged on public.qiyam_logs;
create trigger trg_on_qiyam_logged
  after insert or update on public.qiyam_logs
  for each row execute function public.on_qiyam_logged();

-- 9. trigger: يمنح حسنات عند إكمال فئة أذكار
create or replace function public.on_athkar_completion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_category_id text;
  v_completed_count int;
  v_total_count int;
  v_row public.athkar_unlock_state;
begin
  if new.completed != true then return new; end if;
  if tg_op = 'UPDATE' and old.completed = true then return new; end if;

  select category_id into v_category_id
  from public.athkar_items where id = new.athkar_item_id;

  if v_category_id is null then return new; end if;

  select count(*) into v_completed_count
  from public.user_athkar_logs ual
  join public.athkar_items ai on ai.id = ual.athkar_item_id
  where ual.user_id = new.user_id
    and ual.date = new.date
    and ual.completed = true
    and ai.category_id = v_category_id;

  select count(*) into v_total_count
  from public.athkar_items where category_id = v_category_id;

  if v_total_count = 0 or v_completed_count < v_total_count then
    return new;
  end if;

  -- ✅ الفئة كاملة → امنح 10 حسنات
  perform public.award_hasanat(
    new.user_id, 10, 'dhikr',
    'athkar_' || v_category_id || '_' || new.date::text
  );

  -- تحديث unlock state
  select * into v_row
  from public.athkar_unlock_state
  where user_id = new.user_id and category_id = v_category_id;

  if v_row is null then
    insert into public.athkar_unlock_state
      (user_id, category_id, current_level, consecutive_days, last_completed_date)
    values (new.user_id, v_category_id, 5, 1, new.date);
  else
    if v_row.last_completed_date = new.date then
      return new;
    elsif v_row.last_completed_date = new.date - 1 then
      if v_row.consecutive_days >= 2 then
        update public.athkar_unlock_state
        set current_level = current_level + 1,
            consecutive_days = 0,
            last_completed_date = new.date,
            updated_at = now()
        where user_id = new.user_id and category_id = v_category_id;
      else
        update public.athkar_unlock_state
        set consecutive_days = consecutive_days + 1,
            last_completed_date = new.date,
            updated_at = now()
        where user_id = new.user_id and category_id = v_category_id;
      end if;
    else
      update public.athkar_unlock_state
      set consecutive_days = 1,
          last_completed_date = new.date,
          updated_at = now()
      where user_id = new.user_id and category_id = v_category_id;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_on_athkar_completion on public.user_athkar_logs;
create trigger trg_on_athkar_completion
  after insert or update on public.user_athkar_logs
  for each row execute function public.on_athkar_completion();

-- 10. RPC: قراءة unlock state
create or replace function public.get_athkar_unlock_state(p_user_id uuid)
returns setof public.athkar_unlock_state
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;
  return query
    select * from public.athkar_unlock_state where user_id = p_user_id;
end;
$$;
grant execute on function public.get_athkar_unlock_state(uuid) to authenticated;