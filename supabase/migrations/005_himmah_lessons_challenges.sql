-- ============================================
-- SOHBA — Migration 005
-- Himmah economy + Daily lessons + Challenges + Athkar unlock + Compound badges
-- ============================================

-- 1. Himmah transactions
create table if not exists public.himmah_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  amount int not null,
  reason text not null,      -- 'streak_day' | 'milestone_7' | 'milestone_30' | 'protect_streak' | 'skip_optional' | 'challenge_win'
  reference_id text,
  balance_after int,
  created_at timestamptz default now()
);

create index if not exists himmah_tx_user_idx
  on public.himmah_transactions(user_id, created_at desc);

alter table public.himmah_transactions enable row level security;

drop policy if exists "Users see own himmah" on public.himmah_transactions;
create policy "Users see own himmah"
  on public.himmah_transactions for all using (auth.uid() = user_id);

-- Auto-update profile.himmah on insert
create or replace function public.apply_himmah_tx()
returns trigger
language plpgsql
as $$
begin
  update public.profiles
  set himmah = greatest(0, coalesce(himmah,0) + new.amount),
      updated_at = now()
  where id = new.user_id;
  return new;
end;
$$;

drop trigger if exists on_himmah_tx on public.himmah_transactions;
create trigger on_himmah_tx
  after insert on public.himmah_transactions
  for each row execute function public.apply_himmah_tx();

-- 2. Daily lessons
create table if not exists public.daily_lessons (
  id text primary key,
  title text not null,
  audio_url text,
  duration_seconds int,
  transcript text,
  source_id text references public.sources(id),
  publish_date date,
  created_at timestamptz default now()
);

create table if not exists public.user_lesson_logs (
  user_id uuid references public.profiles(id) on delete cascade,
  lesson_id text references public.daily_lessons(id),
  listened_at timestamptz default now(),
  primary key (user_id, lesson_id)
);

alter table public.daily_lessons enable row level security;
alter table public.user_lesson_logs enable row level security;

drop policy if exists "Anyone reads lessons" on public.daily_lessons;
create policy "Anyone reads lessons"
  on public.daily_lessons for select using (true);

drop policy if exists "Users see own lesson logs" on public.user_lesson_logs;
create policy "Users see own lesson logs"
  on public.user_lesson_logs for all using (auth.uid() = user_id);

-- 3. Group challenges
create table if not exists public.challenges (
  id uuid primary key default gen_random_uuid(),
  group_id uuid references public.groups(id) on delete cascade,
  created_by uuid references public.profiles(id),
  title text not null,
  type text not null,        -- 'fajr_streak' | 'all_prayers' | 'athkar'
  target_days int not null,
  starts_at date not null default current_date,
  ends_at date not null,
  created_at timestamptz default now()
);

create table if not exists public.challenge_participants (
  challenge_id uuid references public.challenges(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  progress int default 0,
  completed boolean default false,
  joined_at timestamptz default now(),
  primary key (challenge_id, user_id)
);

alter table public.challenges enable row level security;
alter table public.challenge_participants enable row level security;

drop policy if exists "Group members see challenges" on public.challenges;
create policy "Group members see challenges"
  on public.challenges for all
  using (
    group_id in (
      select group_id from public.group_members where user_id = auth.uid()
    )
  );

drop policy if exists "Group members see participation" on public.challenge_participants;
create policy "Group members see participation"
  on public.challenge_participants for all
  using (
    challenge_id in (
      select id from public.challenges where group_id in (
        select group_id from public.group_members where user_id = auth.uid()
      )
    )
  );

-- 4. Athkar progressive unlock state
create table if not exists public.athkar_unlock_state (
  user_id uuid references public.profiles(id) on delete cascade,
  category_id text not null,
  current_level int default 5,       -- number of items currently unlocked
  consecutive_days int default 0,
  last_completed_date date,
  is_active boolean default true,    -- for optional habits
  updated_at timestamptz default now(),
  primary key (user_id, category_id)
);

alter table public.athkar_unlock_state enable row level security;

drop policy if exists "Users see own athkar unlock" on public.athkar_unlock_state;
create policy "Users see own athkar unlock"
  on public.athkar_unlock_state for all using (auth.uid() = user_id);

-- 5. Compound badges — add requirements column
alter table public.badges
  add column if not exists requirements jsonb;

-- Seed compound badges
insert into public.badges
  (id, name_ar, description, icon, tier, category, condition, target_value, reward_xp, reward_hasanat, requirements)
values
  ('qiyam_full_night',  'قوام الليل كله',    'الشفع + الوتر + العشاء جماعة + الفجر جماعة',  'nightlight', 'gold', 'prayer', 'compound', 1, 500, 150,
    '{"all_of":["isha_congregation","fajr_congregation","witr","shaf"]}'),
  ('sunan_12_house',    'بيت في الجنة',      '12 ركعة سنة في اليوم',                        'mosque', 'gold', 'prayer', 'compound', 1, 400, 120,
    '{"min_sunnah_rakat":12}'),
  ('duha_house',        'صدقة عن كل عضو',   'صلاة الضحى',                                  'wb_sunny', 'silver', 'prayer', 'compound', 1, 250, 80,
    '{"has_duha":true}'),
  ('night_prayer',      'صلاة في جوف الليل','الشفع + الوتر',                              'nightlight', 'silver', 'prayer', 'compound', 1, 300, 90,
    '{"all_of":["witr","shaf"]}')
on conflict (id) do nothing;

-- 6. Seed a couple of daily lessons
insert into public.daily_lessons (id, title, duration_seconds, transcript, publish_date) values
  ('l001', 'كيف تحافظ على صلاتك في يوم مزدحم؟', 222, 'نص مختصر للدرس...', current_date),
  ('l002', 'الفجر — بداية اليوم بنور', 180, 'نص مختصر للدرس...', current_date + 1),
  ('l003', 'أثر الأذكار على القلب', 240, 'نص مختصر للدرس...', current_date + 2)
on conflict (id) do nothing;

-- 7. Realtime for alerts
alter publication supabase_realtime add table public.admin_alerts;