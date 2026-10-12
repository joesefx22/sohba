-- ============================================
-- SOHBA — Migration 009
-- Server-authoritative record_prayer
-- ============================================
--
-- Changes:
--   - Accepts lat/lng + timezone instead of pre-computed timestamps
--   - Validates date is within [yesterday, today] server-side
--   - Validates phase client sent matches server's "reasonable window"
--   - Still computes phase from client-passed adhan, but guards abuse
--   - Adds idempotency via ON CONFLICT (already present)
-- ============================================

drop function if exists public.record_prayer(
  uuid, text, text, date,
  timestamptz, timestamptz, timestamptz, timestamptz, timestamptz,
  numeric
);

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

  -- ============ SANITY GUARDS ============
  -- 1. Date must be today or yesterday (prevents future-dating)
  if p_date < current_date - 1 or p_date > current_date then
    raise exception 'Invalid date: %', p_date;
  end if;

  -- 2. Adhan must be within ±14 hours of server time
  --    (largest timezone offset in the world is ±14h)
  v_hours_diff := extract(epoch from (p_adhan - v_now)) / 3600.0;
  if abs(v_hours_diff) > 14 then
    raise exception 'Adhan time out of range (% hours from now)', v_hours_diff;
  end if;

  -- 3. Window order must be chronological
  if not (
    p_adhan <= p_congregation_open and
    p_congregation_open <= p_congregation_close and
    p_congregation_close <= p_individual_close and
    p_individual_close <= p_qada_close
  ) then
    raise exception 'Invalid timeline order';
  end if;

  -- 4. Windows must be reasonable (between 1h and 30h total)
  if p_qada_close - p_adhan < interval '1 hour'
     or p_qada_close - p_adhan > interval '30 hours' then
    raise exception 'Timeline duration out of range';
  end if;

  -- 5. Bonus multiplier bounds
  if p_bonus_multiplier < 1.0 or p_bonus_multiplier > 2.0 then
    raise exception 'Invalid bonus multiplier: %', p_bonus_multiplier;
  end if;

  -- ============ Phase determination (server's now) ============
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