import 'package:flutter/material.dart';

/// Central icon registry for Mochi Points.
/// Maps string keys to Material IconData for consistent, theme-conforming display.
class AppIcons {
  AppIcons._();

  static const Map<String, IconData> _icons = {
    // Quest icons
    'edit': Icons.edit_note,
    'cleaning': Icons.cleaning_services,
    'restaurant': Icons.restaurant,
    'bed': Icons.bed,
    'book': Icons.menu_book,
    'target': Icons.gps_fixed,
    'run': Icons.directions_run,
    'palette': Icons.palette,
    'music': Icons.music_note,
    'nature': Icons.eco,
    'pets': Icons.pets,
    'car': Icons.directions_car,
    'fitness': Icons.fitness_center,
    'self_care': Icons.self_improvement,
    'apple': Icons.apple,
    'water': Icons.water_drop,

    // Reward icons (additional)
    'gift': Icons.card_giftcard,
    'gaming': Icons.sports_esports,
    'pizza': Icons.local_pizza,
    'icecream': Icons.icecream,
    'movie': Icons.movie,
    'phone': Icons.phone_iphone,
    'art': Icons.palette,
    'soccer': Icons.sports_soccer,
    'basketball': Icons.sports_basketball,
    'circus': Icons.attractions,
    'ride': Icons.roller_skating,
    'swim': Icons.pool,
    'bike': Icons.directions_bike,
    'star': Icons.star,
    'diamond': Icons.diamond,
    'balloon': Icons.celebration,
    'party': Icons.celebration,
    'confetti': Icons.auto_awesome,
    'trophy': Icons.emoji_events,
    'crown': Icons.workspace_premium,
    'hero': Icons.shield,
    'sparkle': Icons.auto_awesome,

    // Achievement icons (additional)
    'fire': Icons.local_fire_department,
    'bee': Icons.hive,
    'coins': Icons.savings,
    'medal': Icons.military_tech,
    'cart': Icons.shopping_cart,
    'sunrise': Icons.wb_twilight,
    'owl': Icons.nightlight,

    // Notification icons
    'level_up': Icons.emoji_events,     // 🎉 level up
    'approved': Icons.check_circle,      // ✅ quest approved
    'rejected': Icons.cancel,            // ❌ quest rejected
    'hourglass': Icons.hourglass_top,    // ⏳ quest pending approval
    'streak_lost': Icons.heart_broken,   // 💔 streak lost
    'streak_out': Icons.air,             // 💨 streak inactive / not yet started
  };

  /// Available quest icons (ordered for picker)
  static const List<String> questIcons = [
    'edit', 'cleaning', 'restaurant', 'bed', 'book', 'target', 'run', 'palette',
    'music', 'nature', 'pets', 'car', 'fitness', 'self_care', 'apple', 'water',
  ];

  /// Available reward icons (ordered for picker)
  static const List<String> rewardIcons = [
    'gift', 'gaming', 'pizza', 'icecream', 'movie', 'phone', 'art', 'music',
    'soccer', 'basketball', 'target', 'circus', 'ride', 'swim', 'bike', 'star',
    'diamond', 'balloon', 'party', 'confetti', 'trophy', 'crown', 'hero', 'sparkle',
  ];

  /// Look up an IconData by key, with fallback for unknown keys and legacy emojis.
  static IconData get(String key) {
    final icon = _icons[key];
    if (icon != null) return icon;

    // Legacy emoji fallback: if the string looks like an emoji, return a default icon
    if (_isEmoji(key)) return Icons.help_outline;

    return Icons.help_outline;
  }

  /// Check if a string is likely an emoji (not an icon key).
  static bool _isEmoji(String s) {
    if (s.isEmpty) return false;
    final codeUnit = s.codeUnits.first;
    // Emoji code points are generally above basic ASCII/Latin
    return s.length > 1 || codeUnit > 0xFF;
  }
}
