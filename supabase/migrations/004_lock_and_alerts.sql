-- ============================================
-- SOHBA — Migration 004
-- Lock state (missed prayer) + Admin alerts
-- ============================================

-- 1. Lock fields on profiles
alter table public.profiles
  add column if not exists is_locked boolean default false,
  add column if not exists locked_at timestamptz,
  add column if not exists locked_reason text,
  add column if not exists locked_prayer text,
  add column if not exists himmah int default 0;

-- 2. Admin alerts table
create table if not exists public.admin_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  group_id uuid references public.groups(id) on delete cascade,
  type text not null,               -- 'missed_prayer' | 'lock' | 'streak_lost'
  severity text default 'normal',   -- 'info' | 'normal' | 'high'
  title text not null,
  message text not null,
  payload jsonb,
  is_resolved boolean default false,
  resolved_by uuid references public.profiles(id),
  resolved_at timestamptz,
  created_at timestamptz default now()
);

create index if not exists admin_alerts_group_unresolved_idx
  on public.admin_alerts(group_id, is_resolved, created_at desc);

alter table public.admin_alerts enable row level security;

drop policy if exists "Admins read their group alerts" on public.admin_alerts;
create policy "Admins read their group alerts"
  on public.admin_alerts for select
  using (
    group_id in (
      select group_id from public.group_members
      where user_id = auth.uid() and role = 'admin'
    )
  );

drop policy if exists "Admins resolve alerts" on public.admin_alerts;
create policy "Admins resolve alerts"
  on public.admin_alerts for update
  using (
    group_id in (
      select group_id from public.group_members
      where user_id = auth.uid() and role = 'admin'
    )
  );

drop policy if exists "Users insert their own alerts" on public.admin_alerts;
create policy "Users insert their own alerts"
  on public.admin_alerts for insert
  with check (auth.uid() = user_id);

-- 3. Function: lock a user + create alert
create or replace function public.lock_user_for_missed_prayer(
  p_user_id uuid,
  p_prayer text,
  p_date date
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group uuid;
  v_name text;
begin
  -- Lock the profile
  update public.profiles
  set is_locked = true,
      locked_at = now(),
      locked_reason = 'missed_prayer',
      locked_prayer = p_prayer,
      updated_at = now()
  where id = p_user_id and is_locked = false;

  -- Get group + name for the alert
  select current_group_id, name into v_group, v_name
  from public.profiles where id = p_user_id;

  -- Create an alert if not already pending for the same prayer
  if not exists (
    select 1 from public.admin_alerts
    where user_id = p_user_id
      and type = 'lock'
      and is_resolved = false
      and (payload->>'prayer') = p_prayer
      and (payload->>'date') = p_date::text
  ) then
    insert into public.admin_alerts
      (user_id, group_id, type, severity, title, message, payload)
    values (
      p_user_id,
      v_group,
      'lock',
      'high',
      'توقف رحلة: ' || coalesce(v_name, 'طالب'),
      'لم يسجل صلاة ' || p_prayer || ' في وقتها',
      jsonb_build_object('prayer', p_prayer, 'date', p_date::text)
    );
  end if;
end;
$$;

-- 4. Function: unlock user (called after he confirms he prayed)
create or replace function public.unlock_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set is_locked = false,
      locked_at = null,
      locked_reason = null,
      locked_prayer = null,
      updated_at = now()
  where id = p_user_id;
end;
$$;