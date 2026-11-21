/// Sohba — Environment configuration.
///
/// ✅ Approach: القيم الحقيقية هنا كـ `defaultValue`.
/// تقدر تعمل override وقت البناء بـ `--dart-define` (للـ staging/prod).
///
/// ─── Development ─────────────────────────────────────────────
///   flutter run                              ← يستخدم القيم هنا
///
/// ─── Release ────────────────────────────────────────────────
///   flutter build apk --release              ← يستخدم القيم هنا
///
/// ─── Override (اختياري) ─────────────────────────────────────
///   flutter build apk --release \
///     --dart-define=SUPABASE_URL=https://staging.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxx
class EnvConfig {
  EnvConfig._();

  /// ⚠️ SUPABASE_ANON_KEY من نوع `sb_publishable_*` — مصمم يكون public،
  /// آمن إنه يكون في الكود. الحماية الحقيقية عبر RLS في قاعدة البيانات.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://updsclkuglvdxllhptru.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_BJG083YVFK0RmaJbNydKHQ_eYYgdqr8',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Kept for backward compatibility — no-op now.
  static Future<void> load() async {}
}