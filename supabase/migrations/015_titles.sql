-- ============================================
-- SOHBA — Migration 015
-- نظام الألقاب (Titles)
-- ============================================

create table if not exists public.titles (
  id text primary key,
  name_ar text not null,
  description text not null,
  icon text,
  category text not null check (category in ('prayer','streak','athkar','sunnah','special')),
  source_badge_id text references public.badges(id),
  display_order int default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

alter table public.titles enable row level security;
drop policy if exists "Anyone can read titles" on public.titles;
create policy "Anyone can read titles"
  on public.titles for select using (true);

create table if not exists public.user_titles (
  user_id uuid references public.profiles(id) on delete cascade,
  title_id text references public.titles(id) on delete cascade,
  unlocked_at timestamptz default now(),
  is_active boolean default false,
  primary key (user_id, title_id)
);

create index if not exists user_titles_user_idx
  on public.user_titles(user_id, is_active desc);

alter table public.user_titles enable row level security;
drop policy if exists "Users see own titles" on public.user_titles;
create policy "Users see own titles"
  on public.user_titles for select using (auth.uid() = user_id);

-- RPC: unlock_title
create or replace function public.unlock_title(
  p_user_id uuid,
  p_title_id text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  if not exists (select 1 from public.titles where id = p_title_id) then
    raise exception 'Title not found: %', p_title_id;
  end if;

  insert into public.user_titles (user_id, title_id, unlocked_at)
  values (p_user_id, p_title_id, now())
  on conflict (user_id, title_id) do nothing;

  return true;
end;
$$;
grant execute on function public.unlock_title(uuid, text) to authenticated;

-- RPC: set_active_title
create or replace function public.set_active_title(
  p_user_id uuid,
  p_title_id text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  if not exists (
    select 1 from public.user_titles
    where user_id = p_user_id and title_id = p_title_id
  ) then
    raise exception 'Title not unlocked yet';
  end if;

  update public.user_titles
  set is_active = false
  where user_id = p_user_id;

  update public.user_titles
  set is_active = true
  where user_id = p_user_id and title_id = p_title_id;
end;
$$;
grant execute on function public.set_active_title(uuid, text) to authenticated;

-- Seeds (كل لقب مربوط بميدالية موجودة)
insert into public.titles
  (id, name_ar, description, icon, category, source_badge_id, display_order)
values
  ('fajr_lion',       'صلاتي خير من نومي',
    'للمحافظين على صلاة الفجر جماعة',
    'wb_twilight', 'prayer', 'fajr_7', 1),
  ('awwab',           'الأواب',
    'العائد إلى الله بعد كل خطيئة',
    'wb_sunny', 'prayer', 'prayer_30', 2),
  ('night_half',      'قوام نصف الليل الأول',
    'للمحافظين على العشاء جماعة',
    'nightlight', 'prayer', 'qiyam_7', 3),
  ('night_full',      'قوام الليل كله',
    'من صلّى العشاء والفجر جماعة',
    'nightlight', 'special', 'qiyam_30', 4),
  ('witr_king',       'صلاة في جوف الليل',
    'للمحافظين على الشفع والوتر',
    'star', 'sunnah', 'night_prayer', 5),
  ('duha_owner',      'صدقة عن كل عضو',
    'للمحافظين على صلاة الضحى',
    'wb_sunny', 'sunnah', 'duha_house', 6),
  ('house_in_jannah', 'بيت في الجنة',
    'من صلّى 12 ركعة سنة في اليوم',
    'crown', 'sunnah', 'sunan_12_house', 7),
  ('streak_starter',  'بداية الطريق',
    'سبعة أيام من الاستقامة',
    'local_fire_department', 'streak', 'streak_7', 8),
  ('the_steadfast',   'الثبات',
    'ثلاثون يومًا من الاستقامة',
    'local_fire_department', 'streak', 'streak_30', 9),
  ('the_foremost',    'السابقون',
    'سنة كاملة من الاستقامة',
    'workspace_premium', 'streak', 'streak_365', 10)
on conflict (id) do nothing;