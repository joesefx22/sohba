import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// Service that discovers background images bundled under
/// `assets/backgrounds/` and provides a persistent user selection.
///
/// Discovery is done **at runtime** via [AssetManifest]. The list of
/// available backgrounds is therefore derived directly from what Flutter
/// has bundled — there is no hard-coded list of filenames. To add a new
/// background:
///
///   1. Drop the image file in `assets/backgrounds/`
///   2. Full-restart or rebuild (hot-reload does not pick up new assets)
///
/// The `pubspec.yaml` already declares `assets/backgrounds/` (directory
/// form with trailing slash) which bundles every file in that folder;
/// filename-level changes do not require `pubspec.yaml` edits.
///
/// Supported file extensions: `.png`, `.jpg`, `.jpeg`, `.webp`.
///
/// See `docs/BACKGROUND_AUTO_DISCOVERY.md` for the full spec.
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  static const String _prefsKey = 'selected_background';
  static const String _prefix = 'assets/backgrounds/';
  static const Set<String> _allowedExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
  };

  List<String> _backgrounds = const <String>[];
  String? _currentBackground;

  /// The currently selected background image asset path.
  ///
  /// Returns an empty string if no backgrounds are available (should not
  /// happen in practice — there must be at least one image bundled).
  String get currentBackground =>
      _currentBackground ??
      (_backgrounds.isNotEmpty ? _backgrounds.first : '');

  /// All discovered background asset paths, sorted alphabetically.
  List<String> get availableBackgrounds => List.unmodifiable(_backgrounds);

  /// Enumerate bundled assets and restore the saved selection.
  ///
  /// Must be called after `WidgetsFlutterBinding.ensureInitialized()` and
  /// before `runApp()`. [rootBundleOverride] is only intended for tests
  /// and normally stays null.
  Future<void> init({AssetManifest? manifestOverride}) async {
    final manifest =
        manifestOverride ?? await AssetManifest.loadFromAssetBundle(rootBundle);

    // Enumerate, filter to our directory + allowed extensions, and sort
    // for stable, predictable ordering in the picker.
    _backgrounds = manifest
        .listAssets()
        .where((p) => p.startsWith(_prefix))
        .where(
          (p) => _allowedExtensions.any((e) => p.toLowerCase().endsWith(e)),
        )
        .toList()
      ..sort();

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);

    if (saved != null && _backgrounds.contains(saved)) {
      // Saved selection is still valid — restore it.
      _currentBackground = saved;
    } else if (saved != null &&
        saved.startsWith('assets/') &&
        !saved.startsWith(_prefix)) {
      // Migration: saved path is from the pre-auto-discovery layout
      // (`assets/<file>`). Try to map it to the new `assets/backgrounds/`
      // location. If the file is still bundled, persist the migrated path
      // so subsequent runs skip this branch.
      final migrated = _prefix + saved.substring('assets/'.length);
      if (_backgrounds.contains(migrated)) {
        _currentBackground = migrated;
        await prefs.setString(_prefsKey, migrated);
      } else {
        _currentBackground = _backgrounds.isNotEmpty ? _backgrounds.first : null;
      }
    } else {
      // First run or unknown/invalid saved path → fall back to default.
      _currentBackground = _backgrounds.isNotEmpty ? _backgrounds.first : null;
    }
  }

  /// Select and persist a new background.
  ///
  /// No-ops if [path] is not in [availableBackgrounds] — prevents bogus
  /// SharedPreferences state from the UI.
  Future<void> setBackground(String path) async {
    if (!_backgrounds.contains(path)) return;
    _currentBackground = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, path);
  }
}
