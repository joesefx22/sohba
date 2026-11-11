-- ============================================
-- SOHBA — Migration 017
-- سجل الرصيد الموحد
-- ============================================

create or replace view public.hasanat_ledger as
  select
    p.id::text || '_hasanat' as id,
    p.user_id,
    p.recorded_at as event_at,
    p.date as event_date,
    'prayer'::text as source,
    p.prayer as ref_key,
    ('صلاة ' || p.prayer)::text as description,
    p.hasanat::int as amount,
    null::text as note
  from public.prayer_logs p
  where p.hasanat > 0

  union all

  select
    p.id::text || '_sayyiat',
    p.user_id,
    p.recorded_at,
    p.date,
    'sayyiat'::text,
    p.prayer,
    ('تفويت ' || p.prayer)::text,
    (-p.sayyiat)::int,
    case when p.sayyiat_repented then 'تمت التوبة' else null end
  from public.prayer_logs p
  where p.sayyiat > 0

  union all

  select
    t.id::text,
    t.user_id,
    t.created_at,
    t.created_at::date,
    t.type::text,
    null::text,
    coalesce(t.description, t.type),
    t.amount::int,
    null::text
  from public.transactions t;

-- RPC: get_ledger
create or replace function public.get_ledger(
  p_user_id uuid,
  p_limit int default 100,
  p_offset int default 0
)
returns setof public.hasanat_ledger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  return query
    select * from public.hasanat_ledger
    where user_id = p_user_id
    order by event_at desc
    limit least(p_limit, 200) offset greatest(p_offset, 0);
end;
$$;
grant execute on function public.get_ledger(uuid, int, int) to authenticated;

-- RPC: ledger_summary
create or replace function public.ledger_summary(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hasanat bigint;
  v_sayyiat bigint;
  v_iman numeric;
begin
  if auth.uid() is not null and auth.uid() != p_user_id then
    raise exception 'Unauthorized';
  end if;

  select total_hasanat, total_sayyiat_unrepented, iman
  into v_hasanat, v_sayyiat, v_iman
  from public.profiles where id = p_user_id;

  return jsonb_build_object(
    'total_hasanat', coalesce(v_hasanat, 0),
    'total_sayyiat', coalesce(v_sayyiat, 0),
    'iman', coalesce(v_iman, 0)
  );
end;
$$;
grant execute on function public.ledger_summary(uuid) to authenticated;