import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════
/// PrayerStatus — الحالات الجديدة (بدون qada)
/// ═══════════════════════════════════════════════════════════
/// - upcoming:     الأذان لسه ما جاش
/// - pending:      الأذان جه + لسه قابل للتسجيل (لحد فجر اليوم التالي)
/// - congregation: اتسجلت جماعة (+27 حسنة)
/// - individual:   اتسجلت فردي (+1 حسنة)
/// - missed:       انتهى اليوم بدون تسجيل (+200 سيئة)
enum PrayerStatus { upcoming, pending, congregation, individual, missed }

enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

extension PrayerNameX on PrayerName {
  String get arabicName {
    switch (this) {
      case PrayerName.fajr: return 'الفجر';
      case PrayerName.dhuhr: return 'الظهر';
      case PrayerName.asr: return 'العصر';
      case PrayerName.maghrib: return 'المغرب';
      case PrayerName.isha: return 'العشاء';
    }
  }

  String get englishKey => name;

  IconData get icon {
    switch (this) {
      case PrayerName.fajr: return Icons.wb_twilight;
      case PrayerName.dhuhr: return Icons.wb_sunny;
      case PrayerName.asr: return Icons.wb_sunny_outlined;
      case PrayerName.maghrib: return Icons.nights_stay;
      case PrayerName.isha: return Icons.nightlight;
    }
  }
}

extension PrayerStatusX on PrayerStatus {
  String get arabicLabel {
    switch (this) {
      case PrayerStatus.upcoming: return 'لم يأذّن بعد';
      case PrayerStatus.pending: return 'لم تُسجَّل بعد';
      case PrayerStatus.congregation: return 'جماعة';
      case PrayerStatus.individual: return 'منفردًا';
      case PrayerStatus.missed: return 'فائتة';
    }
  }

  Color get color {
    switch (this) {
      case PrayerStatus.upcoming: return const Color(0xFF9EAEA7);
      case PrayerStatus.pending: return const Color(0xFFE0A458);
      case PrayerStatus.congregation: return const Color(0xFF35C98A);
      case PrayerStatus.individual: return const Color(0xFF5DD6D0);
      case PrayerStatus.missed: return const Color(0xFFD96B6B);
    }
  }

  bool get isRecorded =>
      this == PrayerStatus.congregation || this == PrayerStatus.individual;
  bool get isRecordable => this == PrayerStatus.pending;
}

class PrayerLog {
  final String id;
  final String userId;
  final DateTime date;
  final PrayerName prayer;
  final PrayerStatus status;
  final int hasanat;
  final int sayyiat;
  final DateTime? recordedAt;

  const PrayerLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.prayer,
    this.status = PrayerStatus.pending,
    this.hasanat = 0,
    this.sayyiat = 0,
    this.recordedAt,
  });

  bool get isRecorded => status.isRecorded;
  bool get isMissed => status == PrayerStatus.missed;

  static String makeId(String userId, DateTime date, PrayerName prayer) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${userId}_${y}${m}${d}_${prayer.name}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'date': _dateOnly(date),
        'prayer': prayer.name,
        'status': status.name,
        'hasanat': hasanat,
        'sayyiat': sayyiat,
        'recorded_at': recordedAt?.toIso8601String(),
      };

  factory PrayerLog.fromJson(Map<String, dynamic> j) => PrayerLog(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        date: DateTime.parse(j['date'] as String),
        prayer: PrayerName.values.byName(j['prayer'] as String),
        status: PrayerStatus.values.byName(j['status'] as String),
        hasanat: (j['hasanat'] as num?)?.toInt() ?? 0,
        sayyiat: (j['sayyiat'] as num?)?.toInt() ?? 0,
        recordedAt: j['recorded_at'] != null
            ? DateTime.parse(j['recorded_at'] as String) : null,
      );

  PrayerLog copyWith({
    String? id, String? userId, DateTime? date, PrayerName? prayer,
    PrayerStatus? status, int? hasanat, int? sayyiat, DateTime? recordedAt,
  }) => PrayerLog(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        date: date ?? this.date,
        prayer: prayer ?? this.prayer,
        status: status ?? this.status,
        hasanat: hasanat ?? this.hasanat,
        sayyiat: sayyiat ?? this.sayyiat,
        recordedAt: recordedAt ?? this.recordedAt,
      );

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final d2 = d.day.toString().padLeft(2, '0');
    return '$y-$m-$d2';
  }
}