class LedgerEntry {
  final String id;
  final String userId;
  final DateTime eventAt;
  final DateTime eventDate;
  final String source;
  final String? refKey;
  final String description;
  final int amount;
  final String? note;

  const LedgerEntry({
    required this.id,
    required this.userId,
    required this.eventAt,
    required this.eventDate,
    required this.source,
    this.refKey,
    required this.description,
    required this.amount,
    this.note,
  });

  bool get isCredit => amount > 0;

  String get sourceLabelAr {
    switch (source) {
      case 'prayer': return 'صلاة';
      case 'sayyiat': return 'سيئة';
      case 'prayer_congregation': return 'جماعة';
      case 'prayer_individual': return 'منفرد';
      case 'sunnah': return 'سنة';
      case 'qiyam': return 'قيام';
      case 'dhikr': return 'ذكر';
      case 'missed_prayer': return 'تفويت';
      case 'tawbah': return 'توبة';
      case 'bonus': return 'مكافأة';
      case 'badge_unlock': return 'ميدالية';
      default: return source;
    }
  }

  factory LedgerEntry.fromJson(Map<String, dynamic> j) => LedgerEntry(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        eventAt: DateTime.parse(j['event_at'] as String),
        eventDate: DateTime.parse(j['event_date'] as String),
        source: j['source'] as String,
        refKey: j['ref_key'] as String?,
        description: j['description'] as String,
        amount: (j['amount'] as num).toInt(),
        note: j['note'] as String?,
      );
}