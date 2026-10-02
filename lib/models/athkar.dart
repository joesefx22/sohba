class AthkarCategory {
  final String id;
  final String nameAr;
  final String? nameEn;
  final String icon;
  final int displayOrder;
  final bool isMandatory;
  final List<AthkarItem> items;

  const AthkarCategory({
    required this.id,
    required this.nameAr,
    this.nameEn,
    required this.icon,
    this.displayOrder = 0,
    this.isMandatory = false,
    this.items = const [],
  });

  int get totalCount => items.length;
}

class AthkarItem {
  final String id;
  final String categoryId;
  final int displayOrder;
  final String arabic;
  final String? transliteration;
  final String? translation;
  final int repeatCount;
  final String? reference;
  final String? virtue;

  const AthkarItem({
    required this.id,
    required this.categoryId,
    required this.displayOrder,
    required this.arabic,
    this.transliteration,
    this.translation,
    this.repeatCount = 1,
    this.reference,
    this.virtue,
  });
}

class UserAthkarProgress {
  final String athkarItemId;
  final DateTime date;
  final int count;
  final bool completed;
  final DateTime? completedAt;

  const UserAthkarProgress({
    required this.athkarItemId,
    required this.date,
    this.count = 0,
    this.completed = false,
    this.completedAt,
  });

  factory UserAthkarProgress.fromJson(Map<String, dynamic> json) {
    return UserAthkarProgress(
      athkarItemId: json['athkar_item_id'] as String,
      date: DateTime.parse(json['date'] as String),
      count: json['count'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }
}