-- ============================================
-- SOHBA — Migration 011
-- إصلاح جذري لـ sweep + إنشاء صفوف missed حقيقية
-- ============================================

drop function if exists public.sweep_missed_prayers_for_user(uuid);

create or replace function public.sweep_missed_prayers_for_user(
  p_user_id uuid
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_account_date date;
  v_today date := current_date;
  v_yesterday date := current_date - 1;
  d date;
  p text;
  affected int := 0;
  v_exists boolean;
begin
  -- Auth check
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  -- أول يوم في الحساب (أو آخر 90 يوم حد أقصى لتفادي bulk ضخم)
  select greatest(
           coalesce(created_at::date, current_date),
           current_date - 90
         )
    into v_account_date
    from public.profiles
   where id = p_user_id;

  if v_account_date is null then
    return 0;
  end if;

  -- من تاريخ الحساب لحد امبارح
  d := v_account_date;
  while d <= v_yesterday loop
    foreach p in array array['fajr','dhuhr','asr','maghrib','isha'] loop

      -- هل يوجد صف أصلاً؟
      select exists(
        select 1 from public.prayer_logs
        where user_id = p_user_id and date = d and prayer = p
      ) into v_exists;

      if not v_exists then
        -- ملاحظة: صلاحية الـ qada لصلاة يوم d تمتد حتى نفس الصلاة يوم d+1.
        -- لذلك لا نحكم بالفوات إلا بعد مرور 24 ساعة على الأقل.
        -- نتأكد إن الصف من يومين أو أكثر، أو من امبارح وفات وقت القضاء.
        if d <= (v_today - 2) then
          insert into public.prayer_logs
            (id, user_id, date, prayer, status,
             hasanat, sayyiat, sayyiat_repented, recorded_at)
          values
            (p_user_id::text || '_' || to_char(d, 'YYYYMMDD') || '_' || p,
             p_user_id, d, p, 'missed', 0, 200, false, now())
          on conflict (user_id, date, prayer) do nothing;
          affected := affected + 1;
        end if;

      elsif exists (
        select 1 from public.prayer_logs
        where user_id = p_user_id and date = d and prayer = p
          and status = 'pending'
      ) then
        -- صف pending قديم → حوّله لـ missed بعد مرور يومين على الأقل
        if d <= (v_today - 2) then
          update public.prayer_logs
             set status = 'missed',
                 sayyiat = 200,
                 recorded_at = now()
           where user_id = p_user_id and date = d and prayer = p
             and status = 'pending';
          affected := affected + 1;
        end if;
      end if;

    end loop;
    d := d + 1;
  end loop;

  return affected;
end;
$$;

grant execute on function public.sweep_missed_prayers_for_user(uuid)
  to authenticated;