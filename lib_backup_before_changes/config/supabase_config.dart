/// Sohba — Supabase Configuration
///
/// ⚠️ IMPORTANT: Replace the placeholders below with your actual
/// Supabase project URL and anon key from:
///   https://supabase.com/dashboard/project/_/settings/api
///
/// The anon key is SAFE to ship in the client — it's designed to be
/// public. Security is enforced via Row Level Security (RLS) policies.
///
/// NEVER put the `service_role` key here. It bypasses RLS and must
/// only live on the server.
class SupabaseConfig {
  SupabaseConfig._();

  // ============================================
  // ⚠️ TODO: Replace these two values
  // ============================================
  static const String url = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String anonKey = 'YOUR_ANON_KEY_HERE';

  // ============================================
  // Deep links (for email confirmation redirect)
  // ============================================
  static const String authRedirectUrl = 'sohba://auth-callback';

  // ============================================
  // Realtime channels
  // ============================================
  static const String groupMembersChannel = 'group_members';
  static const String prayerLogsChannel = 'prayer_logs';
}