-- ============================================
-- SOHBA — Migration 013
-- حماية حقول profiles + إغلاق prayer_logs + RPCs بديلة
-- ============================================

-- 1. helper: مضاعف الستريك (server-side)
create or replace function public.streak_bonus_multiplier(p_streak int)
returns numeric
language sql immutable
as $$
  select case
    when p_streak >= 100 then 1.5
    when p_streak >= 30  then 1.25
    when p_streak >= 14  then 1.15
    when p_streak >= 7   then 1.10
    else 1.00
  end::numeric;
$$;

-- 2. trigger يحمي الحقول الحساسة في profiles
create or replace function public.protect_profile_fields()
returns trigger
language plpgsql
as $$
begin
  if auth.role() = 'service_role' then
    return new;
  end if;

  if coalesce(current_setting('app.allow_protected_update', true), '') = 'true' then
    return new;
  end if;

  if new.iman                    is distinct from old.iman                    then
    raise exception 'لا يمكن تعديل رصيد الإيمان مباشرة'; end if;
  if new.total_hasanat           is distinct from old.total_hasanat           then
    raise exception 'لا يمكن تعديل الحسنات مباشرة'; end if;
  if new.total_sayyiat_unrepented is distinct from old.total_sayyiat_unrepented then
    raise exception 'لا يمكن تعديل السيئات مباشرة'; end if;
  if new.himmah                  is distinct from old.himmah                  then
    raise exception 'لا يمكن تعديل الهمّة مباشرة'; end if;
  if new.current_streak          is distinct from old.current_streak          then
    raise exception 'لا يمكن تعديل الستريك مباشرة'; end if;
  if new.longest_streak          is distinct from old.longest_streak          then
    raise exception 'لا يمكن تعديل الستريك مباشرة'; end if;
  if new.is_locked               is distinct from old.is_locked               then
    raise exception 'لا يمكن تعديل حالة القفل مباشرة'; end if;

  return new;
end;
$$;

drop trigger if exists trg_protect_profile_fields on public.profiles;
create trigger trg_protect_profile_fields
  before update on public.profiles
  for each row execute function public.protect_profile_fields();

-- 3. prayer_logs: قراءة فقط للعميل
drop policy if exists "Users see own prayer logs" on public.prayer_logs;
create policy "Users see own prayer logs"
  on public.prayer_logs for select using (auth.uid() = user_id);

-- 4. RPC: mark_repented
create or replace function public.mark_repented(
  p_user_id uuid,
  p_prayer text,
  p_date date
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.prayer_logs;
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  perform set_config('app.allow_protected_update', 'true', true);

  update public.prayer_logs
  set sayyiat_repented = true,
      repented_at = now()
  where user_id = p_user_id
    and date = p_date
    and prayer = p_prayer
    and sayyiat_repented = false
    and sayyiat > 0
  returning * into v_row;

  if v_row.id is null then
    return jsonb_build_object('success', false, 'message', 'لا توجد سيئات للتوبة');
  end if;

  return jsonb_build_object('success', true, 'id', v_row.id);
end;
$$;

grant execute on function public.mark_repented(uuid, text, date) to authenticated;

-- 5. RPC: record_historical_qada (للقضاء من أيام سابقة)
create or replace function public.record_historical_qada(
  p_user_id uuid,
  p_prayer text,
  p_date date
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.prayer_logs;
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  if p_prayer not in ('fajr','dhuhr','asr','maghrib','isha') then
    raise exception 'Invalid prayer: %', p_prayer;
  end if;

  if p_date > current_date then
    raise exception 'Cannot record qada for a future date';
  end if;

  perform set_config('app.allow_protected_update', 'true', true);

  update public.prayer_logs
  set status = 'qada',
      hasanat = 0,
      sayyiat = 0,
      sayyiat_repented = true,
      recorded_at = now(),
      repented_at = now()
  where user_id = p_user_id
    and date = p_date
    and prayer = p_prayer
    and status in ('missed', 'pending')
  returning * into v_row;

  if v_row.id is null then
    raise exception 'No missed prayer found for % on %', p_prayer, p_date;
  end if;

  update public.profiles
  set is_locked = false,
      locked_at = null,
      locked_reason = null,
      locked_prayer = null,
      locked_date = null,
      updated_at = now()
  where id = p_user_id
    and is_locked = true
    and (locked_prayer = p_prayer or locked_prayer is null);

  return jsonb_build_object(
    'id', v_row.id,
    'prayer', v_row.prayer,
    'status', v_row.status,
    'date', v_row.date
  );
end;
$$;

grant execute on function public.record_historical_qada(uuid, text, date) to authenticated;

-- 6. RPC: recompute_streak
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

  select array_agg(distinct date order by date desc)
  into v_dates
  from public.prayer_logs
  where user_id = p_user_id
    and status in ('congregation', 'individual', 'qada');

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
      last_active_date = v_today,
      updated_at = now()
  where id = p_user_id;

  return jsonb_build_object('streak', v_streak, 'longest', v_longest);
end;
$$;

grant execute on function public.recompute_streak(uuid) to authenticated;

-- 7. record_prayer v3 — يحسب bonus من السيرفر
create or replace function public.record_prayer(
  p_user_id uuid,
  p_prayer text,
  p_status text,
  p_date date,
  p_adhan timestamptz,
  p_congregation_open timestamptz,
  p_congregation_close timestamptz,
  p_individual_close timestamptz,
  p_qada_close timestamptz,
  p_bonus_multiplier numeric default 1.0
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_now timestamptz := now();
  v_phase text;
  v_hasanat int := 0;
  v_id text;
  v_row public.prayer_logs;
  v_hours_diff numeric;
  v_bonus numeric;
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  if p_prayer not in ('fajr','dhuhr','asr','maghrib','isha') then
    raise exception 'Invalid prayer: %', p_prayer;
  end if;
  if p_status not in ('congregation','individual','qada','missed') then
    raise exception 'Invalid status: %', p_status;
  end if;

  if p_date < current_date - 1 or p_date > current_date then
    raise exception 'Invalid date: %', p_date;
  end if;

  v_hours_diff := extract(epoch from (p_adhan - v_now)) / 3600.0;
  if abs(v_hours_diff) > 14 then
    raise exception 'Adhan time out of range';
  end if;

  if not (
    p_adhan <= p_congregation_open and
    p_congregation_open <= p_congregation_close and
    p_congregation_close <= p_individual_close and
    p_individual_close <= p_qada_close
  ) then
    raise exception 'Invalid timeline order';
  end if;

  if v_now < p_adhan then v_phase := 'before_adhan';
  elsif v_now < p_congregation_open then v_phase := 'waiting';
  elsif v_now < p_congregation_close then v_phase := 'congregation';
  elsif v_now < p_individual_close then v_phase := 'individual';
  elsif v_now < p_qada_close then v_phase := 'qada';
  else v_phase := 'missed';
  end if;

  if p_status = 'congregation' and v_phase != 'congregation' then
    raise exception 'وقت الجماعة انتهى';
  end if;
  if p_status = 'individual'
     and v_phase not in ('individual', 'congregation') then
    raise exception 'لم يعد وقت الانفراد متاحًا';
  end if;
  if p_status = 'qada' and v_phase != 'qada' then
    raise exception 'وقت القضاء لم يبدأ بعد';
  end if;

  -- 🔒 السيرفر يحسب المضاعف من current_streak (يتجاهل p_bonus_multiplier)
  select public.streak_bonus_multiplier(coalesce(current_streak, 0))
  into v_bonus
  from public.profiles where id = p_user_id;
  v_bonus := coalesce(v_bonus, 1.0);

  if p_status = 'congregation' and v_phase = 'congregation' then
    v_hasanat := round(27 * v_bonus);
  elsif p_status = 'individual'
        and v_phase in ('individual', 'congregation') then
    v_hasanat := round(1 * v_bonus);
  else
    v_hasanat := 0;
  end if;

  perform set_config('app.allow_protected_update', 'true', true);

  v_id := p_user_id::text || '_' || to_char(p_date, 'YYYYMMDD')
          || '_' || p_prayer;

  insert into public.prayer_logs
    (id, user_id, date, prayer, status,
     hasanat, sayyiat, sayyiat_repented, recorded_at)
  values
    (v_id, p_user_id, p_date, p_prayer, p_status,
     v_hasanat, 0, false, v_now)
  on conflict (user_id, date, prayer) do update
    set status = excluded.status,
        hasanat = excluded.hasanat,
        sayyiat = 0,
        sayyiat_repented = false,
        recorded_at = excluded.recorded_at
  returning * into v_row;

  -- إذا كانت قضاء + مقفل → ارفع القفل مباشرة
  if p_status = 'qada' then
    update public.profiles
    set is_locked = false,
        locked_at = null,
        locked_reason = null,
        locked_prayer = null,
        locked_date = null,
        updated_at = now()
    where id = p_user_id
      and is_locked = true
      and (locked_prayer = p_prayer or locked_prayer is null);
  end if;

  return jsonb_build_object(
    'id', v_row.id,
    'prayer', v_row.prayer,
    'status', v_row.status,
    'hasanat', v_row.hasanat,
    'recorded_at', v_row.recorded_at,
    'phase', v_phase,
    'bonus_applied', v_bonus
  );
end;
$$;

grant execute on function public.record_prayer(
  uuid, text, text, date,
  timestamptz, timestamptz, timestamptz, timestamptz, timestamptz,
  numeric
) to authenticated;