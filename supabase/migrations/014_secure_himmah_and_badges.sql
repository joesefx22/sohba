-- ============================================
-- SOHBA — Migration 014
-- تحصين himmah_transactions + transactions + user_badges
-- ============================================

-- 1. himmah_transactions: قراءة فقط
drop policy if exists "Users see own himmah" on public.himmah_transactions;
create policy "Users see own himmah"
  on public.himmah_transactions for select using (auth.uid() = user_id);

-- منع تكرار reference_id
create unique index if not exists himmah_tx_user_ref_uniq
  on public.himmah_transactions(user_id, reference_id)
  where reference_id is not null;

-- 2. transactions: قراءة فقط (لا يوجد كتابة من العميل حالياً)
drop policy if exists "Users see own transactions" on public.transactions;
create policy "Users see own transactions"
  on public.transactions for select using (auth.uid() = user_id);

-- 3. user_badges: قراءة فقط + RPC
drop policy if exists "Users see own badges" on public.user_badges;
create policy "Users see own badges"
  on public.user_badges for select using (auth.uid() = user_id);

create or replace function public.unlock_badge(
  p_user_id uuid,
  p_badge_id text
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

  if not exists (select 1 from public.badges where id = p_badge_id) then
    raise exception 'Badge not found: %', p_badge_id;
  end if;

  insert into public.user_badges (user_id, badge_id, unlocked_at)
  values (p_user_id, p_badge_id, now())
  on conflict (user_id, badge_id) do nothing;

  return true;
end;
$$;

grant execute on function public.unlock_badge(uuid, text) to authenticated;

-- 4. RPC: award_himmah
create or replace function public.award_himmah(
  p_user_id uuid,
  p_amount int,
  p_reason text,
  p_reference_id text default null
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_balance int;
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  if p_amount <= 0 or p_amount > 500 then
    raise exception 'Invalid award amount: %', p_amount;
  end if;

  if p_reason not in (
    'streak_day','milestone_7','milestone_14','milestone_30',
    'milestone_60','milestone_100','milestone_365',
    'challenge_win','admin_grant'
  ) then
    raise exception 'Invalid award reason: %', p_reason;
  end if;

  perform set_config('app.allow_protected_update', 'true', true);

  insert into public.himmah_transactions
    (user_id, amount, reason, reference_id)
  values
    (p_user_id, p_amount, p_reason, p_reference_id)
  on conflict (user_id, reference_id) do nothing;

  select coalesce(himmah, 0) into v_balance
  from public.profiles where id = p_user_id;

  return v_balance;
end;
$$;

grant execute on function public.award_himmah(uuid, int, text, text)
  to authenticated;

-- 5. RPC: spend_himmah
create or replace function public.spend_himmah(
  p_user_id uuid,
  p_amount int,
  p_reason text,
  p_reference_id text default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_balance int;
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  if p_amount <= 0 or p_amount > 1000 then
    raise exception 'Invalid spend amount: %', p_amount;
  end if;

  if p_reason not in ('protect_streak','skip_optional') then
    raise exception 'Invalid spend reason: %', p_reason;
  end if;

  select coalesce(himmah, 0) into v_balance
  from public.profiles where id = p_user_id;

  if v_balance < p_amount then
    raise exception 'رصيد الهمّة غير كافٍ';
  end if;

  perform set_config('app.allow_protected_update', 'true', true);

  insert into public.himmah_transactions
    (user_id, amount, reason, reference_id)
  values
    (p_user_id, -abs(p_amount), p_reason, p_reference_id);

  return true;
end;
$$;

grant execute on function public.spend_himmah(uuid, int, text, text)
  to authenticated;