-- ============================================
-- SOHBA — Migration 006
-- Logic fixes:
--   1. User-scoped sweep_missed_prayers (client-callable, safe)
--   2. record_prayer RPC (server-authoritative time + hasanat)
-- ============================================

-- ============================================
-- 1. Rewrite sweep to be user-scoped + client-callable
-- ============================================
drop function if exists public.sweep_missed_prayers();

create or replace function public.sweep_missed_prayers_for_user(
  p_user_id uuid
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  affected int;
begin
  -- Only allow users to sweep their own logs.
  -- Service role (auth.uid() is null) can sweep anyone.
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized: cannot sweep another user''s logs';
  end if;

  update public.prayer_logs
  set status = 'missed',
      sayyiat = 200,
      recorded_at = now()
  where user_id = p_user_id
    and status = 'pending'
    and date < (current_date - interval '1 day');

  get diagnostics affected = row_count;
  return affected;
end;
$$;

-- ✅ Grant to authenticated (scoped by auth.uid() check inside)
grant execute on function public.sweep_missed_prayers_for_user(uuid)
  to authenticated;

-- ============================================
-- 2. record_prayer RPC — server-authoritative time + hasanat
-- ============================================
--
-- Client passes:
--   - prayer name, status
--   - the date the user is logging for (client-tz logical date)
--   - the adhan + window boundaries (computed client-side via `adhan` pkg)
--   - streak bonus multiplier (from profiles.current_streak client-side)
--
-- Server:
--   - validates phase against `now()`
--   - computes hasanat from status + phase
--   - upserts prayer_logs with server's recorded_at
--
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
begin
  -- ============ Authorization ============
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  if p_prayer not in ('fajr','dhuhr','asr','maghrib','isha') then
    raise exception 'Invalid prayer: %', p_prayer;
  end if;

  if p_status not in ('congregation','individual','qada','missed') then
    raise exception 'Invalid status: %', p_status;
  end if;

  -- ============ Phase determination (server time) ============
  if v_now < p_adhan then
    v_phase := 'before_adhan';
  elsif v_now < p_congregation_open then
    v_phase := 'waiting';
  elsif v_now < p_congregation_close then
    v_phase := 'congregation';
  elsif v_now < p_individual_close then
    v_phase := 'individual';
  elsif v_now < p_qada_close then
    v_phase := 'qada';
  else
    v_phase := 'missed';
  end if;

  -- ============ Status/phase compatibility ============
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

  -- ============ Hasanat calculation ============
  if p_status = 'congregation' and v_phase = 'congregation' then
    v_hasanat := round(27 * p_bonus_multiplier);
  elsif p_status = 'individual'
        and v_phase in ('individual', 'congregation') then
    v_hasanat := round(1 * p_bonus_multiplier);
  else
    v_hasanat := 0;
  end if;

  -- ============ Upsert ============
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

  return jsonb_build_object(
    'id', v_row.id,
    'prayer', v_row.prayer,
    'status', v_row.status,
    'hasanat', v_row.hasanat,
    'recorded_at', v_row.recorded_at,
    'phase', v_phase
  );
end;
$$;

grant execute on function public.record_prayer(
  uuid, text, text, date,
  timestamptz, timestamptz, timestamptz, timestamptz, timestamptz,
  numeric
) to authenticated;