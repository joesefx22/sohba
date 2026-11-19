-- ═══════════════════════════════════════════════════════════
-- 023 — Simplify prayer system (FIXED for hasanat_ledger dependency)
-- ═══════════════════════════════════════════════════════════

-- ─── STEP 0: احفظ تعريفات الـ view والـ function أولاً (احتياطي) ──
-- SELECT pg_get_viewdef('hasanat_ledger', true);
-- SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'get_ledger';

-- ─── STEP 1: حوّل qada → missed ─────────────────────────────
UPDATE prayer_logs
SET status = 'missed',
    sayyiat = 200,
    hasanat = 0
WHERE status = 'qada';

-- ─── STEP 2: احذف الاعتماديات (function أولاً ثم view) ─────
DROP FUNCTION IF EXISTS get_ledger(uuid, integer, integer) CASCADE;
DROP VIEW IF EXISTS hasanat_ledger CASCADE;

-- ─── STEP 3: الآن تقدر تحذف الأعمدة بأمان ─────────────────
ALTER TABLE prayer_logs DROP COLUMN IF EXISTS sayyiat_repented;
ALTER TABLE prayer_logs DROP COLUMN IF EXISTS repented_at;

-- ─── STEP 4: حدّث قيد الحالات المسموحة ─────────────────────
ALTER TABLE prayer_logs DROP CONSTRAINT IF EXISTS prayer_logs_status_check;
ALTER TABLE prayer_logs
  ADD CONSTRAINT prayer_logs_status_check
  CHECK (status IN ('pending','congregation','individual','missed'));

-- ─── STEP 5: فهرس لتسريع sweep ─────────────────────────────
CREATE INDEX IF NOT EXISTS idx_prayer_logs_user_date
  ON prayer_logs (user_id, date);

-- ─── STEP 6: أعد إنشاء hasanat_ledger (بدون sayyiat_repented) ──
-- ⚠️ إذا كان الـ view الأصلي فيه UNION لجداول أخرى (qiyam_logs, badges, إلخ)،
--    ضيف الـ UNION في نهاية هذا التعريف. النسخة هنا تغطي prayer_logs فقط.
CREATE OR REPLACE VIEW hasanat_ledger AS
SELECT
  pl.id,
  pl.user_id,
  pl.recorded_at        AS event_at,
  pl.date               AS event_date,
  CASE
    WHEN pl.status = 'congregation' THEN 'prayer_congregation'
    WHEN pl.status = 'individual'   THEN 'prayer_individual'
    WHEN pl.status = 'missed'       THEN 'missed_prayer'
    ELSE 'prayer'
  END                    AS source,
  pl.id                  AS ref_key,
  CASE
    WHEN pl.status = 'congregation' THEN 'صلاة جماعة'
    WHEN pl.status = 'individual'   THEN 'صلاة منفردة'
    WHEN pl.status = 'missed'       THEN 'صلاة فائتة'
    ELSE 'صلاة'
  END                    AS description,
  (CASE WHEN pl.hasanat > 0 THEN pl.hasanat ELSE -pl.sayyiat END) AS amount,
  NULL::text             AS note
FROM prayer_logs pl
WHERE pl.status IN ('congregation','individual','missed')
  AND pl.recorded_at IS NOT NULL;

-- ─── STEP 7: أعد إنشاء get_ledger ──────────────────────────
CREATE OR REPLACE FUNCTION get_ledger(
  p_user_id uuid,
  p_limit   integer DEFAULT 50,
  p_offset  integer DEFAULT 0
)
RETURNS SETOF hasanat_ledger
LANGUAGE sql STABLE AS $$
  SELECT * FROM hasanat_ledger
  WHERE user_id = p_user_id
  ORDER BY event_at DESC
  LIMIT p_limit OFFSET p_offset;
$$;

-- ─── STEP 8: تحقق ───────────────────────────────────────────
-- SELECT * FROM hasanat_ledger LIMIT 5;
-- SELECT * FROM get_ledger('YOUR_USER_ID'::uuid, 10, 0);