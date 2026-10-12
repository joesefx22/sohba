-- ============================================
-- SOHBA — Migration 008
-- Challenge daily log (fixes race condition + double counting)
-- ============================================

create table if not exists public.challenge_daily_log (
  challenge_id uuid references public.challenges(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  date date not null,
  qualified boolean default false,
  recorded_at timestamptz default now(),
  primary key (challenge_id, user_id, date)
);

create index if not exists challenge_daily_log_user_idx
  on public.challenge_daily_log(user_id, date desc);

alter table public.challenge_daily_log enable row level security;

drop policy if exists "Users see own challenge log" on public.challenge_daily_log;
create policy "Users see own challenge log"
  on public.challenge_daily_log for all using (auth.uid() = user_id);

-- ============================================
-- RPC: advance_challenge (idempotent per day)
-- ============================================
create or replace function public.advance_challenge(
  p_user_id uuid,
  p_prayer text
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_today date := current_date;
  v_advanced int := 0;
  v_row record;
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  for v_row in
    select
      cp.challenge_id,
      cp.progress,
      c.type,
      c.target_days,
      c.ends_at
    from public.challenge_participants cp
    join public.challenges c on c.id = cp.challenge_id
    where cp.user_id = p_user_id
      and cp.completed = false
      and c.ends_at >= v_today
  loop
    -- Does this prayer qualify?
    if not (
      (v_row.type = 'fajr_streak' and p_prayer = 'fajr') or
      (v_row.type = 'all_prayers' and p_prayer = 'isha')
    ) then
      continue;
    end if;

    -- Insert daily log (idempotent)
    insert into public.challenge_daily_log
      (challenge_id, user_id, date, qualified)
    values
      (v_row.challenge_id, p_user_id, v_today, true)
    on conflict (challenge_id, user_id, date) do nothing;

    -- Only advance if we JUST inserted (i.e. first time today)
    if found then
      update public.challenge_participants
      set progress = progress + 1,
          completed = (progress + 1) >= v_row.target_days
      where challenge_id = v_row.challenge_id
        and user_id = p_user_id;

      v_advanced := v_advanced + 1;
    end if;
  end loop;

  return v_advanced;
end;
$$;

grant execute on function public.advance_challenge(uuid, text) to authenticated;