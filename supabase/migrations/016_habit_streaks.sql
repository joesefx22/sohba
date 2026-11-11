-- ============================================
-- SOHBA — Migration 016
-- Streaks مستقلة لكل عادة
-- ============================================

create table if not exists public.habit_streaks (
  user_id uuid references public.profiles(id) on delete cascade,
  habit_key text not null,
  current_streak int default 0,
  longest_streak int default 0,
  last_active_date date,
  updated_at timestamptz default now(),
  primary key (user_id, habit_key)
);

create index if not exists habit_streaks_user_idx
  on public.habit_streaks(user_id, current_streak desc);

alter table public.habit_streaks enable row level security;
drop policy if exists "Users see own habit streaks" on public.habit_streaks;
create policy "Users see own habit streaks"
  on public.habit_streaks for select using (auth.uid() = user_id);

-- RPC: bump_habit_streak (idempotent per day)
create or replace function public.bump_habit_streak(
  p_user_id uuid,
  p_habit_key text,
  p_date date default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_date date := coalesce(p_date, current_date);
  v_current int;
  v_longest int;
  v_last date;
  v_new_streak int;
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  if p_habit_key not in (
    'fajr_congregation','dhuhr_congregation','asr_congregation',
    'maghrib_congregation','isha_congregation',
    'morning_athkar','evening_athkar','after_prayer_athkar',
    'qiyam','duha','sunnah_12'
  ) then
    raise exception 'Invalid habit_key: %', p_habit_key;
  end if;

  select current_streak, longest_streak, last_active_date
  into v_current, v_longest, v_last
  from public.habit_streaks
  where user_id = p_user_id and habit_key = p_habit_key;

  if v_last = v_date then
    return jsonb_build_object(
      'habit_key', p_habit_key,
      'current_streak', coalesce(v_current, 0),
      'longest_streak', coalesce(v_longest, 0),
      'last_active_date', v_last
    );
  end if;

  if v_last is null or v_last = v_date - 1 then
    v_new_streak := coalesce(v_current, 0) + 1;
  else
    v_new_streak := 1;
  end if;

  v_longest := greatest(coalesce(v_longest, 0), v_new_streak);

  insert into public.habit_streaks
    (user_id, habit_key, current_streak, longest_streak, last_active_date, updated_at)
  values
    (p_user_id, p_habit_key, v_new_streak, v_longest, v_date, now())
  on conflict (user_id, habit_key) do update
    set current_streak = excluded.current_streak,
        longest_streak = excluded.longest_streak,
        last_active_date = excluded.last_active_date,
        updated_at = now();

  return jsonb_build_object(
    'habit_key', p_habit_key,
    'current_streak', v_new_streak,
    'longest_streak', v_longest,
    'last_active_date', v_date
  );
end;
$$;
grant execute on function public.bump_habit_streak(uuid, text, date) to authenticated;

-- RPC: sweep — resets broken habits
create or replace function public.sweep_habit_streaks(p_user_id uuid)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_affected int;
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  update public.habit_streaks
  set current_streak = 0,
      updated_at = now()
  where user_id = p_user_id
    and current_streak > 0
    and last_active_date is not null
    and last_active_date < (current_date - 1);

  get diagnostics v_affected = row_count;
  return v_affected;
end;
$$;
grant execute on function public.sweep_habit_streaks(uuid) to authenticated;

-- Trigger: prayer_logs congregation → bump habit streak
create or replace function public.sync_prayer_habit_streak()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'congregation' then
    perform public.bump_habit_streak(
      new.user_id, new.prayer || '_congregation', new.date
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_sync_prayer_habit on public.prayer_logs;
create trigger trg_sync_prayer_habit
  after insert or update on public.prayer_logs
  for each row
  when (new.status = 'congregation')
  execute function public.sync_prayer_habit_streak();

-- Trigger: athkar completion → bump habit streak
create or replace function public.sync_athkar_habit_streak()
returns trigger
language plpgsql
as $$
declare
  v_category_id text;
  v_completed int;
  v_total int;
  v_habit_key text;
begin
  if new.completed != true or old.completed = true then return new; end if;

  select category_id into v_category_id
  from public.athkar_items where id = new.athkar_item_id;
  if v_category_id is null then return new; end if;

  v_habit_key := case v_category_id
    when 'morning' then 'morning_athkar'
    when 'evening' then 'evening_athkar'
    when 'after_prayer' then 'after_prayer_athkar'
    else null end;
  if v_habit_key is null then return new; end if;

  select count(*) into v_completed
  from public.user_athkar_logs ual
  join public.athkar_items ai on ai.id = ual.athkar_item_id
  where ual.user_id = new.user_id
    and ual.date = new.date
    and ual.completed = true
    and ai.category_id = v_category_id;

  select count(*) into v_total
  from public.athkar_items where category_id = v_category_id;

  if v_total > 0 and v_completed >= v_total then
    perform public.bump_habit_streak(new.user_id, v_habit_key, new.date);
  end if;

  return new;
end;
$$;

drop trigger if exists trg_sync_athkar_habit on public.user_athkar_logs;
create trigger trg_sync_athkar_habit
  after insert or update on public.user_athkar_logs
  for each row execute function public.sync_athkar_habit_streak();