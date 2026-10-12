/// One night of qiyam al-layl for a single user on a single date.
class QiyamLog {
  final String id;
  final String userId;
  final DateTime date; // midnight of the day
  final int rakat;
  final int duaCount;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const QiyamLog({
    required this.id,
    required this.userId,
    required this.date,
    this.rakat = 2,
    this.duaCount = 0,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Normalized day (year, month, day) — used as map key.
  DateTime get dayKey => DateTime(date.year, date.month, date.day);

  factory QiyamLog.fromJson(Map<String, dynamic> json) {
    return QiyamLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      rakat: json['rakat'] as int? ?? 2,
      duaCount: json['dua_count'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'date': date.toIso8601String().split('T').first,
        'rakat': rakat,
        'dua_count': duaCount,
        'notes': notes,
      };
}