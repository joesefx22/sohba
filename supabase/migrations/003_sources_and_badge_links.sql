-- ============================================
-- SOHBA — Migration 003
-- Sources (hadith/quran references) + link to badges
-- ============================================

create table if not exists public.sources (
  id text primary key,
  text_ar text not null,
  reference text not null,
  grade text,
  url text,
  created_at timestamptz default now()
);

alter table public.sources enable row level security;

drop policy if exists "Sources are public read" on public.sources;
create policy "Sources are public read"
  on public.sources for select using (true);

-- Link badges to sources
alter table public.badges
  add column if not exists source_id text references public.sources(id);

-- Seed sources
insert into public.sources (id, text_ar, reference, grade) values
  ('fajr_bushra',    'بشّر المشائين في الظلم بالنور التام يوم القيامة', 'سنن الترمذي 223 — صححه الألباني', 'حسن'),
  ('salah_wasat',    'حَافِظُوا عَلَى الصَّلَوَاتِ وَالصَّلَاةِ الْوُسْطَى', 'البقرة: 238', 'قرآن'),
  ('salah_malaika',  'يَتَعَاقَبُونَ فِيكُمْ مَلَائِكَةٌ بِاللَّيْلِ وَمَلَائِكَةٌ بِالنَّهَارِ', 'صحيح البخاري 555', 'صحيح'),
  ('qiyam_best',     'أَفْضَلُ الصَّلَاةِ بَعْدَ الْفَرِيضَةِ صَلَاةُ اللَّيْلِ', 'صحيح مسلم 1163', 'صحيح'),
  ('sunan_12',       'مَنْ صَلَّى اثْنَتَيْ عَشْرَةَ رَكْعَةً بُنِيَ لَهُ بَيْتُ فِي الْجَنَّةِ', 'صحيح مسلم 728', 'صحيح'),
  ('fajr_shahid',    'مَنْ صَلَّى الصُّبْحَ فَهُوَ فِي ذِمَّةِ اللَّهِ', 'صحيح مسلم 657', 'صحيح')
on conflict (id) do nothing;

-- Attach sources to existing badges
update public.badges set source_id = 'fajr_bushra'   where id like 'fajr_%';
update public.badges set source_id = 'qiyam_best'    where id like 'qiyam_%';
update public.badges set source_id = 'salah_malaika' where id in ('prayer_30');