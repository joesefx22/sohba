/// Sohba — Environment configuration.
///
/// ✅ SECURE: values are injected at build time via `--dart-define` or
/// `--dart-define-from-file`. They are **not** bundled as an asset, so
/// reverse-engineering the APK won't reveal them.
///
/// ─── Development ─────────────────────────────────────────────
///   flutter run --dart-define-from-file=env.json
///
/// ─── Release ────────────────────────────────────────────────
///   flutter build apk \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// `env.json` (create it locally, add to .gitignore):
///   {
///     "SUPABASE_URL": "https://xxx.supabase.co",
///     "SUPABASE_ANON_KEY": "eyJ..."
///   }
class EnvConfig {
  EnvConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Kept for backward compatibility — no-op now.
  static Future<void> load() async {}
}