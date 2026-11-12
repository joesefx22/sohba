-- ============================================
-- SOHBA — Migration 021
-- 1. Qada within 24h = 100 sayyiat penalty
-- 2. Per-prayer sunnah tracking for Gardens
-- 3. Dua/qiyam flags for Gardens
-- ============================================

-- ============================================
-- 1. record_prayer: qada → 100 sayyiat
-- ============================================
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
  v_sayyiat int := 0;
  v_id text;
  v_row public.prayer_logs;
  v_hours_diff numeric;
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

  -- Sanity guards
  if p_date < current_date - 1 or p_date > current_date then
    raise exception 'Invalid date: %', p_date;
  end if;

  v_hours_diff := extract(epoch from (p_adhan - v_now)) / 3600.0;
  if abs(v_hours_diff) > 14 then
    raise exception 'Adhan time out of range (% hours from now)', v_hours_diff;
  end if;

  if not (
    p_adhan <= p_congregation_open and
    p_congregation_open <= p_congregation_close and
    p_congregation_close <= p_individual_close and
    p_individual_close <= p_qada_close
  ) then
    raise exception 'Invalid timeline order';
  end if;

  if p_qada_close - p_adhan < interval '1 hour'
     or p_qada_close - p_adhan > interval '30 hours' then
    raise exception 'Timeline duration out of range';
  end if;

  if p_bonus_multiplier < 1.0 or p_bonus_multiplier > 2.0 then
    raise exception 'Invalid bonus multiplier: %', p_bonus_multiplier;
  end if;

  -- Phase determination
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

  -- Status/phase compatibility
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

  -- Hasanat
  if p_status = 'congregation' and v_phase = 'congregation' then
    v_hasanat := round(27 * p_bonus_multiplier);
  elsif p_status = 'individual'
        and v_phase in ('individual', 'congregation') then
    v_hasanat := round(1 * p_bonus_multiplier);
  else
    v_hasanat := 0;
  end if;

  -- ✅ NEW: qada within 24h window → 100 sayyiat penalty
  if p_status = 'qada' then
    v_sayyiat := 100;
  end if;

  v_id := p_user_id::text || '_' || to_char(p_date, 'YYYYMMDD')
          || '_' || p_prayer;

  insert into public.prayer_logs
    (id, user_id, date, prayer, status,
     hasanat, sayyiat, sayyiat_repented, recorded_at)
  values
    (v_id, p_user_id, p_date, p_prayer, p_status,
     v_hasanat, v_sayyiat, false, v_now)
  on conflict (user_id, date, prayer) do update
    set status = excluded.status,
        hasanat = excluded.hasanat,
        sayyiat = excluded.sayyiat,
        sayyiat_repented = excluded.sayyiat_repented,
        recorded_at = excluded.recorded_at
  returning * into v_row;

  return jsonb_build_object(
    'id', v_row.id,
    'prayer', v_row.prayer,
    'status', v_row.status,
    'hasanat', v_row.hasanat,
    'sayyiat', v_row.sayyiat,
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

-- ============================================
-- 2. Sunnah per-prayer tracking (for Gardens)
-- ============================================
alter table public.qiyam_logs
  add column if not exists fajr_sunnah int default 0,
  add column if not exists dhuhr_sunnah int default 0,
  add column if not exists asr_sunnah int default 0,
  add column if not exists maghrib_sunnah int default 0,
  add column if not exists isha_sunnah int default 0,
  add column if not exists qiyam_prayed boolean default false,
  add column if not exists dua_done boolean default false;

-- ============================================
-- 3. RPC: log_sunnah (per prayer)
-- ============================================
create or replace function public.log_sunnah(
  p_user_id uuid,
  p_prayer text,
  p_rakat int,
  p_date date default current_date
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_col text;
  v_hasanat int;
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  if p_prayer not in ('fajr','dhuhr','asr','maghrib','isha') then
    raise exception 'Invalid prayer';
  end if;

  if p_rakat not in (0, 2, 4, 6) then
    raise exception 'Invalid rakat count';
  end if;

  v_col := p_prayer || '_sunnah';

  -- Upsert row
  insert into public.qiyam_logs (user_id, date)
  values (p_user_id, p_date)
  on conflict (user_id, date) do nothing;

  -- Update the specific column
  execute format(
    'update public.qiyam_logs set %I = $1, updated_at = now() where user_id = $2 and date = $3',
    v_col
  ) using p_rakat, p_user_id, p_date;

  -- Award hasanat: 20 per 2 rakats
  v_hasanat := (p_rakat / 2) * 20;

  if v_hasanat > 0 then
    perform public.award_hasanat(
      p_user_id,
      v_hasanat,
      'sunnah',
      'sunnah_' || p_prayer || '_' || p_date::text
    );
  end if;

  return jsonb_build_object(
    'prayer', p_prayer,
    'rakat', p_rakat,
    'hasanat', v_hasanat
  );
end;
$$;
grant execute on function public.log_sunnah(uuid, text, int, date) to authenticated;

-- ============================================
-- 4. RPC: log_qiyam_garden (for new Gardens UI)
-- ============================================
create or replace function public.log_qiyam_garden(
  p_user_id uuid,
  p_date date,
  p_shaf_witr boolean default null,
  p_dua_done boolean default null,
  p_qiyam_prayed boolean default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.qiyam_logs;
  v_hasanat int := 0;
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  if p_date < current_date - 1 or p_date > current_date then
    raise exception 'Invalid date';
  end if;

  insert into public.qiyam_logs
    (user_id, date, prayed_shaf, prayed_witr, dua_done, qiyam_prayed,
     dua_count, tahajjud_rakat, updated_at)
  values
    (p_user_id, p_date,
     coalesce(p_shaf_witr, false),
     coalesce(p_shaf_witr, false),
     coalesce(p_dua_done, false),
     coalesce(p_qiyam_prayed, false),
     case when coalesce(p_dua_done, false) then 1 else 0 end,
     case when coalesce(p_qiyam_prayed, false) then 2 else 0 end,
     now())
  on conflict (user_id, date) do update
    set prayed_shaf = coalesce(p_shaf_witr, qiyam_logs.prayed_shaf),
        prayed_witr = coalesce(p_shaf_witr, qiyam_logs.prayed_witr),
        dua_done = coalesce(p_dua_done, qiyam_logs.dua_done),
        qiyam_prayed = coalesce(p_qiyam_prayed, qiyam_logs.qiyam_prayed),
        dua_count = case when coalesce(p_dua_done, false) then 1 else qiyam_logs.dua_count end,
        tahajjud_rakat = case when coalesce(p_qiyam_prayed, false) then 2 else qiyam_logs.tahajjud_rakat end,
        updated_at = now()
  returning * into v_row;

  -- Award hasanat
  if p_shaf_witr = true then v_hasanat := v_hasanat + 20; end if;
  if p_dua_done = true then v_hasanat := v_hasanat + 10; end if;
  if p_qiyam_prayed = true then v_hasanat := v_hasanat + 20; end if;

  if v_hasanat > 0 then
    perform public.award_hasanat(
      p_user_id, v_hasanat, 'qiyam',
      'qiyam_garden_' || p_date::text
    );
  end if;

  return jsonb_build_object(
    'shaf_witr', v_row.prayed_shaf and v_row.prayed_witr,
    'dua_done', v_row.dua_done,
    'qiyam_prayed', v_row.qiyam_prayed,
    'hasanat', v_hasanat
  );
end;
$$;
grant execute on function public.log_qiyam_garden(uuid, date, boolean, boolean, boolean) to authenticated;

-- ============================================
-- 5. RPC: log_duha
-- ============================================
create or replace function public.log_duha(
  p_user_id uuid,
  p_date date default current_date
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  insert into public.qiyam_logs (user_id, date, prayed_duha)
  values (p_user_id, p_date, true)
  on conflict (user_id, date) do update
    set prayed_duha = true, updated_at = now();

  perform public.award_hasanat(
    p_user_id, 20, 'qiyam', 'duha_' || p_date::text
  );

  return jsonb_build_object('duha', true, 'hasanat', 20);
end;
$$;
grant execute on function public.log_duha(uuid, date) to authenticated;