import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يشغّل صوت الأذان عند دخول الوقت.
///
/// - لو الملف `assets/audio/adhan.mp3` غير موجود → يعمل بصمت (no-op).
/// - لو المستخدم قافل الأذان من الإعدادات → لا يشغّل.
class AdhanAudioService {
  AdhanAudioService._();
  static final _player = AudioPlayer();
  static bool _ready = false;
  static bool _assetMissing = false;

  static Future<void> init() async {
    if (_ready || _assetMissing) return;
    try {
      await _player.setAsset('assets/audio/adhan.mp3');
      _ready = true;
    } catch (e) {
      debugPrint(
          'AdhanAudioService: asset not found ($e) — أدخل assets/audio/adhan.mp3 لتفعيل الصوت.');
      _assetMissing = true;
    }
  }

  /// يشغّل الأذان إذا كان مطلوباً وحسب تفضيل المستخدم.
  static Future<void> playIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_adhan') ?? true;
    if (!enabled) return;
    await init();
    if (!_ready) return;

    try {
      if (_player.playing) await _player.stop();
      await _player.seek(Duration.zero);
      _player.play(); // non-blocking
    } catch (e) {
      debugPrint('AdhanAudioService.play: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  static Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }
}