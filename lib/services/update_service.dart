import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateInfo {
  final String version;
  final int versionCode;
  final String downloadUrl;
  final String releaseNotes;
  final bool force;
  const UpdateInfo({
    required this.version, required this.versionCode,
    required this.downloadUrl, required this.releaseNotes, required this.force,
  });
}

class UpdateService {
  UpdateService._();
  static final _client = Supabase.instance.client;

  static Future<UpdateInfo?> check() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      final code = int.tryParse(pkg.buildNumber) ?? 0;
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final res = await _client.rpc('check_app_update', params: {
        'p_platform': platform, 'p_current_code': code,
      });
      if (res == null) return null;
      final m = Map<String, dynamic>.from(res as Map);
      return UpdateInfo(
        version: m['version'] as String,
        versionCode: m['version_code'] as int,
        downloadUrl: m['download_url'] as String,
        releaseNotes: m['release_notes'] as String? ?? '',
        force: m['force'] as bool? ?? false,
      );
    } catch (_) { return null; }
  }
}