import 'package:flutter/material.dart';

class Title {
  final String id;
  final String nameAr;
  final String description;
  final String? icon;
  final String category;
  final String? sourceBadgeId;
  final int displayOrder;

  const Title({
    required this.id,
    required this.nameAr,
    required this.description,
    this.icon,
    required this.category,
    this.sourceBadgeId,
    this.displayOrder = 0,
  });

  IconData get iconData {
    const map = {
      'wb_twilight': Icons.wb_twilight,
      'wb_sunny': Icons.wb_sunny,
      'nightlight': Icons.nightlight,
      'star': Icons.star,
      'crown': Icons.workspace_premium,
      'local_fire_department': Icons.local_fire_department,
      'workspace_premium': Icons.workspace_premium,
    };
    return map[icon] ?? Icons.emoji_events;
  }

  factory Title.fromJson(Map<String, dynamic> j) => Title(
        id: j['id'] as String,
        nameAr: j['name_ar'] as String,
        description: j['description'] as String,
        icon: j['icon'] as String?,
        category: j['category'] as String,
        sourceBadgeId: j['source_badge_id'] as String?,
        displayOrder: j['display_order'] as int? ?? 0,
      );
}

class UserTitle {
  final String titleId;
  final DateTime unlockedAt;
  final bool isActive;

  const UserTitle({
    required this.titleId,
    required this.unlockedAt,
    this.isActive = false,
  });

  factory UserTitle.fromJson(Map<String, dynamic> j) => UserTitle(
        titleId: j['title_id'] as String,
        unlockedAt: DateTime.parse(j['unlocked_at'] as String),
        isActive: j['is_active'] == true,
      );
}