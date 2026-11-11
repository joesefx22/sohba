-- ============================================
-- SOHBA — Migration 018
-- حماية الستريك بالهمّة
-- ============================================

create table if not exists public.streak_protections (
  user_id uuid references public.profiles(id) on delete cascade,
  date date not null,
  cost int not null,
  protected_at timestamptz default now(),
  primary key (user_id, date)
);

create index if not exists streak_protections_user_idx
  on public.streak_protections(user_id, date desc);

alter table public.streak_protections enable row level security;
drop policy if exists "Users see own protections" on public.streak_protections;
create policy "Users see own protections"
  on public.streak_protections for select using (auth.uid() = user_id);

-- RPC: protect_streak
create or replace function public.protect_streak(
  p_user_id uuid,
  p_date date default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_date date := coalesce(p_date, current_date - 1);
  v_cost int := 1;
  v_balance int;
  v_has_activity boolean;
  v_last_active date;
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  -- حماية يوم أمس فقط
  if v_date != (current_date - 1) then
    raise exception 'يمكن حماية يوم أمس فقط';
  end if;

  -- هل يوجد نشاط فعلي في ذلك اليوم؟
  select exists(
    select 1 from public.prayer_logs
    where user_id = p_user_id and date = v_date
      and status in ('congregation','individual','qada')
  ) into v_has_activity;

  if v_has_activity then
    raise exception 'اليوم فيه نشاط فعلي — لا حاجة للحماية';
  end if;

  -- الحماية معقولة فقط إن كان آخر نشاط = قبل أمس
  select last_active_date into v_last_active
  from public.profiles where id = p_user_id;

  if v_last_active is null or v_last_active != (current_date - 2) then
    raise exception 'الحماية لا تُمدّد الستريك في هذه الحالة';
  end if;

  if exists (
    select 1 from public.streak_protections
    where user_id = p_user_id and date = v_date
  ) then
    raise exception 'اليوم محمي مسبقاً';
  end if;

  select coalesce(himmah, 0) into v_balance
  from public.profiles where id = p_user_id;

  if v_balance < v_cost then
    raise exception 'رصيد الهمّة غير كافٍ (% مطلوبة)', v_cost;
  end if;

  perform set_config('app.allow_protected_update', 'true', true);

  -- خصم الهمّة
  insert into public.himmah_transactions
    (user_id, amount, reason, reference_id)
  values
    (p_user_id, -v_cost, 'protect_streak', 'protect_' || v_date::text);

  -- تسجيل الحماية
  insert into public.streak_protections (user_id, date, cost)
  values (p_user_id, v_date, v_cost);

  -- إعادة حساب الستريك
  perform public.recompute_streak(p_user_id);

  return jsonb_build_object(
    'success', true,
    'date', v_date,
    'cost', v_cost
  );
end;
$$;
grant execute on function public.protect_streak(uuid, date) to authenticated;

-- إعادة تعريف recompute_streak لتضمين الأيام المحمية
create or replace function public.recompute_streak(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_dates date[];
  v_today date := current_date;
  v_streak int := 0;
  v_longest int;
  v_cursor date;
  v_has_today boolean;
  v_has_yesterday boolean;
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  select array_agg(distinct d order by d desc)
  into v_dates
  from (
    select date as d from public.prayer_logs
     where user_id = p_user_id
       and status in ('congregation', 'individual', 'qada')
    union
    select date as d from public.streak_protections
     where user_id = p_user_id
  ) sub;

  if v_dates is null then
    perform set_config('app.allow_protected_update', 'true', true);
    update public.profiles
    set current_streak = 0, updated_at = now()
    where id = p_user_id;
    return jsonb_build_object('streak', 0, 'longest', 0);
  end if;

  v_has_today := v_today = any(v_dates);
  v_has_yesterday := (v_today - 1) = any(v_dates);

  if not v_has_today and not v_has_yesterday then
    perform set_config('app.allow_protected_update', 'true', true);
    update public.profiles
    set current_streak = 0, updated_at = now()
    where id = p_user_id;
    select coalesce(longest_streak, 0) into v_longest
    from public.profiles where id = p_user_id;
    return jsonb_build_object('streak', 0, 'longest', v_longest);
  end if;

  v_cursor := case when v_has_today then v_today else v_today - 1 end;
  while v_cursor = any(v_dates) loop
    v_streak := v_streak + 1;
    v_cursor := v_cursor - 1;
  end loop;

  select coalesce(longest_streak, 0) into v_longest
  from public.profiles where id = p_user_id;
  v_longest := greatest(v_longest, v_streak);

  perform set_config('app.allow_protected_update', 'true', true);
  update public.profiles
  set current_streak = v_streak,
      longest_streak = v_longest,
      last_active_date = case
        when v_has_today then v_today
        else v_today - 1
      end,
      updated_at = now()
  where id = p_user_id;

  return jsonb_build_object('streak', v_streak, 'longest', v_longest);
end;
$$;