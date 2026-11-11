-- ============================================
-- SOHBA — Migration 012
-- تحصين دوال القفل/الفتح + سجل تاريخ الفوات
-- ============================================

-- 1. إضافة عمود locked_date لملف المستخدم
alter table public.profiles
  add column if not exists locked_date date;

-- 2. حذف الدوال القديمة
drop function if exists public.lock_user_for_missed_prayer(uuid, text, date);
drop function if exists public.unlock_user(uuid);

-- 3. lock_user_for_missed_prayer — للاستخدام الداخلي فقط (من sweep)
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
  -- ملاحظة أمنية: هذه الدالة للاستخدام الداخلي فقط (من sweep).
  -- لا تُمنح EXECUTE لـ authenticated.
  
  perform set_config('app.allow_protected_update', 'true', true);

  update public.profiles
  set is_locked = true,
      locked_at = now(),
      locked_reason = 'missed_prayer',
      locked_prayer = p_prayer,
      locked_date = p_date,
      updated_at = now()
  where id = p_user_id and is_locked = false;

  select current_group_id, name into v_group, v_name
  from public.profiles where id = p_user_id;

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
      'لم يسجل صلاة ' || p_prayer || ' في وقتها (' || p_date || ')',
      jsonb_build_object('prayer', p_prayer, 'date', p_date::text)
    );
  end if;
end;
$$;

-- 🚨 منع الاستدعاء من العملاء
revoke all on function public.lock_user_for_missed_prayer(uuid, text, date) from public;
grant execute on function public.lock_user_for_missed_prayer(uuid, text, date) to service_role;

-- 4. unlock_user — لا يعمل إلا بعد تسجيل قضاء حديث
create or replace function public.unlock_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  -- يجب وجود سجل قضاء خلال آخر 5 دقائق
  if not exists (
    select 1 from public.prayer_logs
    where user_id = p_user_id
      and status = 'qada'
      and recorded_at > now() - interval '5 minutes'
  ) then
    raise exception 'لا يمكن رفع القفل بدون تسجيل قضاء الصلاة';
  end if;

  perform set_config('app.allow_protected_update', 'true', true);

  update public.profiles
  set is_locked = false,
      locked_at = null,
      locked_reason = null,
      locked_prayer = null,
      locked_date = null,
      updated_at = now()
  where id = p_user_id;
end;
$$;

grant execute on function public.unlock_user(uuid) to authenticated;

-- 5. sweep — يقفل داخلياً بعد المسح
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
  v_most_recent_missed_date date;
  v_most_recent_missed_prayer text;
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  perform set_config('app.allow_protected_update', 'true', true);

  select greatest(
           coalesce(created_at::date, current_date),
           current_date - 90
         )
    into v_account_date
    from public.profiles where id = p_user_id;

  if v_account_date is null then return 0; end if;

  d := v_account_date;
  while d <= v_yesterday loop
    foreach p in array array['fajr','dhuhr','asr','maghrib','isha'] loop
      select exists(
        select 1 from public.prayer_logs
        where user_id = p_user_id and date = d and prayer = p
      ) into v_exists;

      if not v_exists and d <= (v_today - 2) then
        insert into public.prayer_logs
          (id, user_id, date, prayer, status,
           hasanat, sayyiat, sayyiat_repented, recorded_at)
        values
          (p_user_id::text || '_' || to_char(d, 'YYYYMMDD') || '_' || p,
           p_user_id, d, p, 'missed', 0, 200, false, now())
        on conflict (user_id, date, prayer) do nothing;
        affected := affected + 1;
      elsif v_exists and d <= (v_today - 2) then
        update public.prayer_logs
           set status = 'missed', sayyiat = 200, recorded_at = now()
         where user_id = p_user_id and date = d and prayer = p
           and status = 'pending';
        get diagnostics affected = row_count;
        if affected > 0 then affected := affected; end if;
      end if;
    end loop;
    d := d + 1;
  end loop;

  -- بعد المسح، اقفل إذا فيه فوات غير متوب عنها ولم يكن مقفلاً
  select date, prayer
    into v_most_recent_missed_date, v_most_recent_missed_prayer
    from public.prayer_logs
   where user_id = p_user_id
     and status = 'missed'
     and sayyiat_repented = false
   order by date desc
   limit 1;

  if v_most_recent_missed_date is not null then
    perform public.lock_user_for_missed_prayer(
      p_user_id, v_most_recent_missed_prayer, v_most_recent_missed_date
    );
  end if;

  return affected;
end;
$$;

grant execute on function public.sweep_missed_prayers_for_user(uuid)
  to authenticated;