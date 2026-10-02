-- ============================================
-- SOHBA — Migration 002
-- Fix: recompute iman correctly on prayer log changes
-- Add: sweep_missed_prayers() function
-- ============================================

-- 1. Fix the trigger function to also update iman
create or replace function public.recompute_totals_on_prayer_log()
returns trigger
language plpgsql
as $$
declare
  target_user uuid;
  h bigint;
  s bigint;
  i numeric(10,2);
begin
  target_user := coalesce(new.user_id, old.user_id);
  if target_user is null then
    return coalesce(new, old);
  end if;

  -- Hasanat = prayer_logs + positive transactions (for future sunan/qiyam/etc.)
  h := coalesce((
    select sum(hasanat) from public.prayer_logs where user_id = target_user
  ), 0) + coalesce((
    select sum(amount) from public.transactions
    where user_id = target_user and amount > 0
  ), 0);

  -- Sayyiat = unrepented only
  s := coalesce((
    select sum(sayyiat) from public.prayer_logs
    where user_id = target_user and sayyiat_repented = false
  ), 0);

  -- Iman = hasanat/100 - sayyiat/50
  i := (h::numeric / 100.0) - (s::numeric / 50.0);

  update public.profiles
  set total_hasanat = h,
      total_sayyiat_unrepented = s::int,
      iman = i,
      updated_at = now()
  where id = target_user;

  return coalesce(new, old);
end;
$$;

-- 2. Also fix iman when a tawbah is recorded
create or replace function public.recalc_iman_on_tawbah()
returns trigger
language plpgsql
as $$
begin
  -- Handled by recompute_totals_on_prayer_log since tawbah updates prayer_logs.
  -- This is a hook for future non-prayer tawbahs.
  return coalesce(new, old);
end;
$$;

-- 3. Server-side sweep (called by cron OR manually by admin)
create or replace function public.sweep_missed_prayers()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  affected int;
begin
  update public.prayer_logs
  set status = 'missed',
      sayyiat = 200,
      recorded_at = now()
  where status = 'pending'
    and date < (current_date - interval '1 day');

  get diagnostics affected = row_count;
  return affected;
end;
$$;

-- 4. Allow authenticated users to trigger their own sweep (RLS still applies
--    because we call it via direct update from client — this function is
--    for admin/cron use only).
revoke all on function public.sweep_missed_prayers() from public;
grant execute on function public.sweep_missed_prayers() to service_role;