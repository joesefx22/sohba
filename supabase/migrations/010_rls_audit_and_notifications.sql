-- ============================================
-- SOHBA — Migration 010
-- RLS audit + notifications realtime + admin alerts fix
-- ============================================

-- ============================================
-- 1. AUDIT RLS — ensure every user table has policies
-- ============================================
do $$
declare
  tbl text;
  tables text[] := array[
    'profiles', 'groups', 'group_members', 'prayer_logs',
    'user_athkar_logs', 'transactions', 'user_badges',
    'notifications', 'admin_alerts', 'himmah_transactions',
    'user_lesson_logs', 'challenges', 'challenge_participants',
    'challenge_daily_log', 'athkar_unlock_state', 'qiyam_logs'
  ];
begin
  foreach tbl in array tables loop
    -- Check RLS enabled
    if not exists (
      select 1 from pg_tables
      where schemaname = 'public' and tablename = tbl and rowsecurity = true
    ) then
      execute format('alter table public.%I enable row level security', tbl);
      raise notice 'Enabled RLS on %', tbl;
    end if;
  end loop;
end $$;

-- ============================================
-- 2. NOTIFICATIONS — dedupe + anti-spam
-- ============================================
-- Prevent the same notification (same user, type, ref) from being
-- created more than once per hour.
create or replace function public.dedupe_notifications()
returns trigger
language plpgsql
as $$
begin
  if exists (
    select 1 from public.notifications
    where user_id = new.user_id
      and type = new.type
      and title = new.title
      and created_at > now() - interval '1 hour'
  ) then
    return null; -- skip insert
  end if;
  return new;
end;
$$;

drop trigger if exists trg_dedupe_notifications on public.notifications;
create trigger trg_dedupe_notifications
  before insert on public.notifications
  for each row execute function public.dedupe_notifications();

-- Auto-purge read notifications older than 60 days (called by cron).
create or replace function public.purge_old_notifications()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  affected int;
begin
  delete from public.notifications
  where is_read = true
    and created_at < now() - interval '60 days';
  get diagnostics affected = row_count;
  return affected;
end;
$$;

revoke all on function public.purge_old_notifications() from public;
grant execute on function public.purge_old_notifications() to service_role;

-- ============================================
-- 3. ADMIN ALERTS — auto-resolve on unlock
-- ============================================
create or replace function public.auto_resolve_alert_on_unlock()
returns trigger
language plpgsql
as $$
begin
  -- When profile.is_locked flips from true to false, resolve pending alerts
  if old.is_locked = true and new.is_locked = false then
    update public.admin_alerts
    set is_resolved = true,
        resolved_at = now()
    where user_id = new.id
      and type = 'lock'
      and is_resolved = false;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_auto_resolve_alert on public.profiles;
create trigger trg_auto_resolve_alert
  after update on public.profiles
  for each row execute function public.auto_resolve_alert_on_unlock();

-- ============================================
-- 4. REALTIME — enable on notifications + admin_alerts
-- ============================================
-- Wrap in DO to ignore errors if already in publication.
do $$
begin
  begin
    alter publication supabase_realtime add table public.notifications;
  exception when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.admin_alerts;
  exception when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.challenge_participants;
  exception when duplicate_object then null;
  end;
end $$;

-- ============================================
-- 5. SEED: complete sources
-- ============================================
insert into public.sources (id, text_ar, reference, grade) values
  ('sunan_bayt',   'من صلى اثنتي عشرة ركعة في يوم وليلة بُني له بيت في الجنة', 'صحيح مسلم 728', 'صحيح'),
  ('witr_habib',   'إن الله وتر يحب الوتر', 'صحيح البخاري 6410', 'صحيح'),
  ('tahajjud_nuzul','ينزل ربنا تبارك وتعالى كل ليلة إلى السماء الدنيا حين يبقى ثلث الليل الآخر', 'صحيح البخاري 1145', 'صحيح'),
  ('fajr_nur',     'من صلى البردين دخل الجنة', 'صحيح مسلم 635', 'صحيح'),
  ('athkar_sabah', 'أذكار الصباح — من قالها حين يصبح أُجير من الجن حتى يُمسي', 'صحيح الترمذي 3571', 'حسن')
on conflict (id) do nothing;