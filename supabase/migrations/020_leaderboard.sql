-- ============================================
-- SOHBA — Migration 020
-- Leaderboard عام أسبوعي
-- ============================================

-- 1. عمود privacy
alter table public.profiles
  add column if not exists show_in_leaderboard boolean default true;

-- 2. view أسبوعي
create or replace view public.leaderboard_weekly as
  select
    p.id as user_id,
    case when coalesce(p.show_in_leaderboard, true) then p.name else 'عبد من عباد الله' end as display_name,
    p.avatar_url,
    p.current_streak,
    (
      coalesce((
        select sum(hasanat) from public.prayer_logs
        where user_id = p.id
          and date >= current_date - 7
      ), 0)
      +
      coalesce((
        select sum(amount) from public.transactions
        where user_id = p.id
          and amount > 0
          and created_at::date >= current_date - 7
      ), 0)
    )::int as weekly_points
  from public.profiles p
  where coalesce(p.is_locked, false) = false;

-- 3. RPC: get_leaderboard_weekly
create or replace function public.get_leaderboard_weekly(p_limit int default 50)
returns table (
  user_id uuid,
  display_name text,
  avatar_url text,
  current_streak int,
  weekly_points int,
  rank int
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
    select
      lw.user_id,
      lw.display_name,
      lw.avatar_url,
      lw.current_streak,
      lw.weekly_points,
      (row_number() over (order by lw.weekly_points desc, lw.current_streak desc))::int
    from public.leaderboard_weekly lw
    order by lw.weekly_points desc, lw.current_streak desc
    limit least(p_limit, 100);
end;
$$;
grant execute on function public.get_leaderboard_weekly(int) to authenticated;