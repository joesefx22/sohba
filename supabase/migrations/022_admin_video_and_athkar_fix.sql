-- ============================================
-- SOHBA — Migration 022
-- 1. is_admin column + auto-promote admin@gmail.com
-- 2. video_url on daily_lessons
-- 3. Drop FK on user_athkar_logs.athkar_item_id (athkar from assets)
-- ============================================

-- ============================================
-- 1. ADMIN
-- ============================================
alter table public.profiles
  add column if not exists is_admin boolean default false;

-- Auto-promote on signup (email = admin@gmail.com)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles (id, name, is_admin)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', 'طالب جديد'),
    new.email = 'admin@gmail.com'
  );
  return new;
end;
$$;

-- Promote existing profile (if already signed up)
update public.profiles
set is_admin = true
where id in (
  select id from auth.users where email = 'admin@gmail.com'
);

-- ============================================
-- 2. DAILY LESSON: VIDEO
-- ============================================
alter table public.daily_lessons
  add column if not exists video_url text;

-- ============================================
-- 3. ATHKAR: DROP FK (items live in assets, not DB)
-- ============================================
do $$
begin
  begin
    alter table public.user_athkar_logs
      drop constraint if exists user_athkar_logs_athkar_item_id_fkey;
  exception when undefined_object then null;
  end;
end $$;

-- ============================================
-- 4. ADMIN RLS: only admins can manage lessons
-- ============================================
drop policy if exists "Anyone reads lessons" on public.daily_lessons;
create policy "Anyone reads lessons"
  on public.daily_lessons for select using (true);

drop policy if exists "Admins can insert lessons" on public.daily_lessons;
create policy "Admins can insert lessons"
  on public.daily_lessons for insert
  with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and is_admin = true
    )
  );

drop policy if exists "Admins can update lessons" on public.daily_lessons;
create policy "Admins can update lessons"
  on public.daily_lessons for update
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and is_admin = true
    )
  );

drop policy if exists "Admins can delete lessons" on public.daily_lessons;
create policy "Admins can delete lessons"
  on public.daily_lessons for delete
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and is_admin = true
    )
  );