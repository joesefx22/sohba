-- ============================================
-- SOHBA — Initial Schema v0.1
-- ============================================
-- Run this in Supabase SQL Editor.
-- ============================================

-- ============================================
-- 1. PROFILES (extends auth.users)
-- ============================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  avatar_url text,

  -- Prayer settings
  calculation_method text default 'egyptian',
  madhab text default 'shafi',
  timezone text default 'Africa/Cairo',

  -- Economy (denormalized for fast reads)
  total_hasanat bigint default 0,
  total_sayyiat_unrepented int default 0,
  iman numeric(10,2) default 0,

  -- Streak
  current_streak int default 0,
  longest_streak int default 0,
  last_active_date date,

  -- Group
  current_group_id uuid,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================
-- 2. GROUPS
-- ============================================
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  invite_code text not null unique,
  description text,
  avatar_url text,
  created_by uuid references public.profiles(id),
  is_active boolean default true,
  created_at timestamptz default now()
);

create unique index if not exists groups_name_lower_idx
  on public.groups (lower(name));

-- FK from profiles → groups (added after groups table exists)
alter table public.profiles
  drop constraint if exists profiles_current_group_id_fkey;
alter table public.profiles
  add constraint profiles_current_group_id_fkey
  foreign key (current_group_id) references public.groups(id)
  on delete set null;

-- ============================================
-- 3. GROUP_MEMBERS
-- ============================================
create table if not exists public.group_members (
  group_id uuid references public.groups(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  role text default 'member' check (role in ('admin','member')),

  -- Weekly snapshot (for leaderboard)
  weekly_hasanat int default 0,
  weekly_prayers_completed int default 0,
  week_start_date date default date_trunc('week', now())::date,

  joined_at timestamptz default now(),
  primary key (group_id, user_id)
);

create index if not exists group_members_group_idx
  on public.group_members(group_id);
create index if not exists group_members_user_idx
  on public.group_members(user_id);

-- ============================================
-- 4. PRAYER_LOGS
-- ============================================
create table if not exists public.prayer_logs (
  id text primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  date date not null,
  prayer text not null check (prayer in ('fajr','dhuhr','asr','maghrib','isha')),
  status text not null default 'pending'
    check (status in ('pending','congregation','individual','qada','missed')),
  hasanat int default 0,
  sayyiat int default 0,
  sayyiat_repented boolean default false,
  recorded_at timestamptz default now(),
  repented_at timestamptz,
  unique(user_id, date, prayer)
);

create index if not exists prayer_logs_user_date_idx
  on public.prayer_logs(user_id, date desc);

-- ============================================
-- 5. ATHKAR (categories + items)
-- ============================================
create table if not exists public.athkar_categories (
  id text primary key,
  name_ar text not null,
  name_en text,
  icon text,
  display_order int default 0,
  is_mandatory boolean default false
);

create table if not exists public.athkar_items (
  id text primary key,
  category_id text references public.athkar_categories(id) on delete cascade,
  display_order int not null,
  arabic text not null,
  transliteration text,
  translation text,
  repeat_count int default 1,
  reference text,
  virtue text
);

create index if not exists athkar_items_category_idx
  on public.athkar_items(category_id, display_order);

-- ============================================
-- 6. USER_ATHKAR_LOGS
-- ============================================
create table if not exists public.user_athkar_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  athkar_item_id text references public.athkar_items(id),
  date date not null,
  count int default 0,
  completed boolean default false,
  completed_at timestamptz,
  unique(user_id, athkar_item_id, date)
);

create index if not exists user_athkar_user_date_idx
  on public.user_athkar_logs(user_id, date desc);

-- ============================================
-- 7. TRANSACTIONS
-- ============================================
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  type text not null check (type in (
    'prayer_congregation','prayer_individual','sunnah','qiyam','dhikr',
    'missed_prayer','tawbah','bonus','badge_unlock'
  )),
  amount int not null,
  balance_after bigint,
  reference_id text,
  description text,
  created_at timestamptz default now()
);

create index if not exists transactions_user_created_idx
  on public.transactions(user_id, created_at desc);

-- ============================================
-- 8. BADGES (definitions)
-- ============================================
create table if not exists public.badges (
  id text primary key,
  name_ar text not null,
  description text not null,
  icon text not null,
  tier text not null check (tier in ('bronze','silver','gold','platinum')),
  category text not null check (category in ('prayer','streak','athkar','special')),
  condition text not null,
  target_value int,
  reward_xp int default 0,
  reward_hasanat int default 0,
  is_secret boolean default false
);

-- ============================================
-- 9. USER_BADGES
-- ============================================
create table if not exists public.user_badges (
  user_id uuid references public.profiles(id) on delete cascade,
  badge_id text references public.badges(id),
  unlocked_at timestamptz default now(),
  primary key (user_id, badge_id)
);

-- ============================================
-- 10. NOTIFICATIONS
-- ============================================
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  type text not null,
  title text not null,
  message text not null,
  icon text,
  is_read boolean default false,
  created_at timestamptz default now()
);

create index if not exists notifications_user_unread_idx
  on public.notifications(user_id, is_read, created_at desc);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================
alter table public.profiles enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.prayer_logs enable row level security;
alter table public.user_athkar_logs enable row level security;
alter table public.transactions enable row level security;
alter table public.user_badges enable row level security;
alter table public.notifications enable row level security;

-- ---------- profiles ----------
drop policy if exists "Profiles are viewable by everyone" on public.profiles;
create policy "Profiles are viewable by everyone"
  on public.profiles for select using (true);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);

-- ---------- groups ----------
drop policy if exists "Members can view their group" on public.groups;
create policy "Members can view their group"
  on public.groups for select
  using (
    id in (
      select group_id from public.group_members where user_id = auth.uid()
    )
    or created_by = auth.uid()
  );

drop policy if exists "Authenticated users can create groups" on public.groups;
create policy "Authenticated users can create groups"
  on public.groups for insert
  with check (auth.uid() = created_by);

drop policy if exists "Group admins can update" on public.groups;
create policy "Group admins can update"
  on public.groups for update
  using (
    id in (
      select group_id from public.group_members
      where user_id = auth.uid() and role = 'admin'
    )
  );

-- ---------- group_members ----------
drop policy if exists "Members can view same group members" on public.group_members;
create policy "Members can view same group members"
  on public.group_members for select
  using (
    group_id in (
      select group_id from public.group_members where user_id = auth.uid()
    )
  );

drop policy if exists "Users can join groups" on public.group_members;
create policy "Users can join groups"
  on public.group_members for insert
  with check (auth.uid() = user_id);

drop policy if exists "Admins can manage members" on public.group_members;
create policy "Admins can manage members"
  on public.group_members for delete
  using (
    group_id in (
      select group_id from public.group_members
      where user_id = auth.uid() and role = 'admin'
    )
    or user_id = auth.uid()  -- users can leave
  );

-- ---------- prayer_logs ----------
drop policy if exists "Users see own prayer logs" on public.prayer_logs;
create policy "Users see own prayer logs"
  on public.prayer_logs for all using (auth.uid() = user_id);

-- ---------- user_athkar_logs ----------
drop policy if exists "Users see own athkar logs" on public.user_athkar_logs;
create policy "Users see own athkar logs"
  on public.user_athkar_logs for all using (auth.uid() = user_id);

-- ---------- transactions ----------
drop policy if exists "Users see own transactions" on public.transactions;
create policy "Users see own transactions"
  on public.transactions for all using (auth.uid() = user_id);

-- ---------- user_badges ----------
drop policy if exists "Users see own badges" on public.user_badges;
create policy "Users see own badges"
  on public.user_badges for all using (auth.uid() = user_id);

-- ---------- notifications ----------
drop policy if exists "Users see own notifications" on public.notifications;
create policy "Users see own notifications"
  on public.notifications for all using (auth.uid() = user_id);

-- ---------- athkar (public read) ----------
drop policy if exists "Anyone can read athkar categories" on public.athkar_categories;
create policy "Anyone can read athkar categories"
  on public.athkar_categories for select using (true);

drop policy if exists "Anyone can read athkar items" on public.athkar_items;
create policy "Anyone can read athkar items"
  on public.athkar_items for select using (true);

drop policy if exists "Anyone can read badges" on public.badges;
create policy "Anyone can read badges"
  on public.badges for select using (true);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles (id, name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', 'طالب جديد')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Recalculate iman whenever hasanat/sayyiat change
create or replace function public.recalc_iman()
returns trigger
language plpgsql
as $$
begin
  update public.profiles
  set
    iman = (total_hasanat::numeric / 100.0)
         - (total_sayyiat_unrepented::numeric / 50.0),
    updated_at = now()
  where id = coalesce(new.user_id, old.user_id);
  return coalesce(new, old);
end;
$$;

-- Recompute total_hasanat when a prayer_log is inserted/updated
create or replace function public.recompute_totals_on_prayer_log()
returns trigger
language plpgsql
as $$
declare
  target_user uuid;
begin
  target_user := coalesce(new.user_id, old.user_id);

  update public.profiles p
  set
    total_hasanat = coalesce((
      select sum(hasanat) from public.prayer_logs where user_id = target_user
    ), 0) + coalesce((
      select sum(amount) from public.transactions
      where user_id = target_user and amount > 0
    ), 0),
    total_sayyiat_unrepented = coalesce((
      select sum(sayyiat) from public.prayer_logs
      where user_id = target_user and sayyiat_repented = false
    ), 0),
    updated_at = now()
  where id = target_user;

  return coalesce(new, old);
end;
$$;

drop trigger if exists on_prayer_log_change on public.prayer_logs;
create trigger on_prayer_log_change
  after insert or update or delete on public.prayer_logs
  for each row execute function public.recompute_totals_on_prayer_log();

-- ============================================
-- REALTIME
-- ============================================
-- Enable realtime on group_members so leaderboard updates live.
alter publication supabase_realtime add table public.group_members;
alter publication supabase_realtime add table public.prayer_logs;

-- ============================================
-- SEED: initial badges (Sohba medal system)
-- ============================================
insert into public.badges (id, name_ar, description, icon, tier, category, condition, target_value, reward_xp, reward_hasanat)
values
  ('fajr_7',      'نور الفجر',         'حافظ على صلاة الفجر جماعة 7 أيام',    'wb_twilight',    'bronze',   'prayer',  'fajr_congregation_streak', 7,   50,  10),
  ('fajr_30',     'بشير المشائين',      'حافظ على صلاة الفجر جماعة 30 يومًا',  'wb_twilight',    'silver',   'prayer',  'fajr_congregation_streak', 30,  200, 50),
  ('fajr_100',    'نور تام',           'حافظ على صلاة الفجر جماعة 100 يوم',   'wb_twilight',    'gold',     'prayer',  'fajr_congregation_streak', 100, 500, 100),
  ('prayer_30',   'الصلوات الخمس',     'صلِّ الصلوات الخمس في وقتها 30 يومًا', 'mosque',         'silver',   'prayer',  'all_prayers_on_time',      30,  300, 75),
  ('qiyam_7',     'قيام الليل',        'قم الليل 7 ليالٍ متتالية',           'nightlight',     'bronze',   'prayer',  'qiyam_streak',              7,   100, 30),
  ('qiyam_30',    'قوام الليل',        'قم الليل 30 ليلة متتالية',           'nightlight',     'gold',     'prayer',  'qiyam_streak',              30,  400, 100),
  ('athkar_7',    'حافظ الأذكار',      'أذكار الصباح والمساء 7 أيام',         'book',           'bronze',   'athkar',  'athkar_streak',             7,   50,  20),
  ('athkar_30',   'ذاكر الله',         'أذكار الصباح والمساء 30 يومًا',       'book',           'silver',   'athkar',  'athkar_streak',             30,  250, 60),
  ('streak_7',    'بداية الطريق',       '7 أيام متتالية من الطاعة',            'local_fire_department', 'bronze', 'streak', 'overall_streak', 7, 50, 10),
  ('streak_30',   'الثبات',            '30 يومًا متتالية من الطاعة',           'local_fire_department', 'silver', 'streak', 'overall_streak', 30, 250, 60),
  ('streak_100',  'الاستقامة',         '100 يوم متتالية من الطاعة',            'crown',          'gold',     'streak',  'overall_streak',            100, 800, 200),
  ('streak_365',  'السابقون',          'سنة كاملة من الطاعة',                  'workspace_premium', 'platinum', 'streak', 'overall_streak',          365, 2000, 500)
on conflict (id) do nothing;