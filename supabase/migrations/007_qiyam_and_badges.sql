-- ============================================
-- SOHBA — Migration 007
-- Qiyam/Sunnah logs + fix compound badge bug
-- ============================================
--
-- Problem: CompoundBadgeEngine was passing witr/shaf as "true"
-- automatically. This adds real tracking.
-- ============================================

-- ============================================
-- 1. QIYAM LOGS
-- ============================================
create table if not exists public.qiyam_logs (
  user_id uuid references public.profiles(id) on delete cascade,
  date date not null,
  prayed_witr boolean default false,
  prayed_shaf boolean default false,
  prayed_duha boolean default false,
  sunnah_rakat int default 0,       -- total sunnah rakats today
  tahajjud_rakat int default 0,
  updated_at timestamptz default now(),
  primary key (user_id, date)
);

create index if not exists qiyam_logs_user_date_idx
  on public.qiyam_logs(user_id, date desc);

alter table public.qiyam_logs enable row level security;

drop policy if exists "Users see own qiyam" on public.qiyam_logs;
create policy "Users see own qiyam"
  on public.qiyam_logs for all using (auth.uid() = user_id);

-- ============================================
-- 2. RPC: log_qiyam
-- ============================================
create or replace function public.log_qiyam(
  p_user_id uuid,
  p_date date,
  p_witr boolean default null,
  p_shaf boolean default null,
  p_duha boolean default null,
  p_sunnah_rakat int default null,
  p_tahajjud_rakat int default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.qiyam_logs;
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  -- Sanity: date must be today or yesterday
  if p_date < current_date - 1 or p_date > current_date then
    raise exception 'Invalid date: %', p_date;
  end if;

  insert into public.qiyam_logs
    (user_id, date, prayed_witr, prayed_shaf, prayed_duha,
     sunnah_rakat, tahajjud_rakat, updated_at)
  values
    (p_user_id, p_date,
     coalesce(p_witr, false),
     coalesce(p_shaf, false),
     coalesce(p_duha, false),
     coalesce(p_sunnah_rakat, 0),
     coalesce(p_tahajjud_rakat, 0),
     now())
  on conflict (user_id, date) do update
    set prayed_witr = coalesce(p_witr, qiyam_logs.prayed_witr),
        prayed_shaf = coalesce(p_shaf, qiyam_logs.prayed_shaf),
        prayed_duha = coalesce(p_duha, qiyam_logs.prayed_duha),
        sunnah_rakat = coalesce(p_sunnah_rakat, qiyam_logs.sunnah_rakat),
        tahajjud_rakat = coalesce(p_tahajjud_rakat, qiyam_logs.tahajjud_rakat),
        updated_at = now()
  returning * into v_row;

  return jsonb_build_object(
    'user_id', v_row.user_id,
    'date', v_row.date,
    'witr', v_row.prayed_witr,
    'shaf', v_row.prayed_shaf,
    'duha', v_row.prayed_duha,
    'sunnah_rakat', v_row.sunnah_rakat,
    'tahajjud_rakat', v_row.tahajjud_rakat
  );
end;
$$;

grant execute on function public.log_qiyam(
  uuid, date, boolean, boolean, boolean, int, int
) to authenticated;

-- ============================================
-- 3. RPC: get_qiyam_range (last N days)
-- ============================================
create or replace function public.get_qiyam_range(
  p_user_id uuid,
  p_days int default 30
)
returns setof public.qiyam_logs
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  return query
    select * from public.qiyam_logs
    where user_id = p_user_id
      and date >= current_date - p_days
    order by date desc;
end;
$$;

grant execute on function public.get_qiyam_range(uuid, int) to authenticated;

-- ============================================
-- 4. Enable realtime (optional)
-- ============================================
-- alter publication supabase_realtime add table public.qiyam_logs;