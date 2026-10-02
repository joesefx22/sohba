import 'package:flutter/material.dart';

/// Status of a single prayer for a given day.
enum PrayerStatus {
  /// Not yet recorded — day is still in progress.
  pending,

  /// Prayed in congregation at the mosque.
  congregation,

  /// Prayed individually (at home / work).
  individual,

  /// Prayed after the individual window closed (qada).
  qada,

  /// Missed entirely — no record and window expired.
  missed,
}

/// One of the five daily prayers.
enum PrayerName {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha,
}

extension PrayerNameX on PrayerName {
  String get arabicName {
    switch (this) {
      case PrayerName.fajr:
        return 'الفجر';
      case PrayerName.dhuhr:
        return 'الظهر';
      case PrayerName.asr:
        return 'العصر';
      case PrayerName.maghrib:
        return 'المغرب';
      case PrayerName.isha:
        return 'العشاء';
    }
  }

  String get englishKey => name;

  IconData get icon {
    switch (this) {
      case PrayerName.fajr:
        return Icons.wb_twilight;
      case PrayerName.dhuhr:
        return Icons.wb_sunny;
      case PrayerName.asr:
        return Icons.wb_sunny_outlined;
      case PrayerName.maghrib:
        return Icons.nights_stay;
      case PrayerName.isha:
        return Icons.nightlight;
    }
  }
}

extension PrayerStatusX on PrayerStatus {
  String get arabicLabel {
    switch (this) {
      case PrayerStatus.pending:
        return 'لم تُسجَّل بعد';
      case PrayerStatus.congregation:
        return 'جماعة';
      case PrayerStatus.individual:
        return 'منفردًا';
      case PrayerStatus.qada:
        return 'قضاء';
      case PrayerStatus.missed:
        return 'فائتة';
    }
  }

  Color get color {
    switch (this) {
      case PrayerStatus.pending:
        return const Color(0xFF9E9E9E);
      case PrayerStatus.congregation:
        return const Color(0xFF198754);
      case PrayerStatus.individual:
        return const Color(0xFF4A9DFF);
      case PrayerStatus.qada:
        return const Color(0xFFF59E0B);
      case PrayerStatus.missed:
        return const Color(0xFFEF4444);
    }
  }
}

/// Represents a single prayer log for a user on a given day.
class PrayerLog {
  final String id;
  final String userId;
  final DateTime date; // midnight of the day
  final PrayerName prayer;
  final PrayerStatus status;

  /// Hasanat awarded (positive int).
  final int hasanat;

  /// Sayyiat recorded (negative impact).
  final int sayyiat;

  /// Whether the sayyiat has been repented (tawbah).
  final bool sayyiatRepented;

  final DateTime? recordedAt;
  final DateTime? repentedAt;

  const PrayerLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.prayer,
    this.status = PrayerStatus.pending,
    this.hasanat = 0,
    this.sayyiat = 0,
    this.sayyiatRepented = false,
    this.recordedAt,
    this.repentedAt,
  });

  // ============================================
  // COMPUTED
  // ============================================

  bool get isRecorded => status != PrayerStatus.pending;

  bool get isMissed => status == PrayerStatus.missed;

  bool get hasUnrepentedSayyiat => sayyiat > 0 && !sayyiatRepented;

  /// Net effect on the iman balance.
  double get netImanEffect {
    final positive = hasanat / 100.0;
    final negative = sayyiatRepented ? 0.0 : (sayyiat / 50.0);
    return positive - negative;
  }

  // ============================================
  // FACTORY HELPERS
  // ============================================

  /// Create a fresh, unrecorded log.
  factory PrayerLog.empty({
    required String userId,
    required DateTime date,
    required PrayerName prayer,
  }) {
    return PrayerLog(
      id: '${userId}_${date.year}${date.month.toString().padLeft(2, '0')}'
          '${date.day.toString().padLeft(2, '0')}_${prayer.name}',
      userId: userId,
      date: DateTime(date.year, date.month, date.day),
      prayer: prayer,
    );
  }

  // ============================================
  // SERIALIZATION
  // ============================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T').first,
      'prayer': prayer.name,
      'status': status.name,
      'hasanat': hasanat,
      'sayyiat': sayyiat,
      'sayyiat_repented': sayyiatRepented,
      'recorded_at': recordedAt?.toIso8601String(),
      'repented_at': repentedAt?.toIso8601String(),
    };
  }

  factory PrayerLog.fromJson(Map<String, dynamic> json) {
    return PrayerLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      prayer: PrayerName.values.byName(json['prayer'] as String),
      status: PrayerStatus.values.byName(json['status'] as String),
      hasanat: json['hasanat'] as int? ?? 0,
      sayyiat: json['sayyiat'] as int? ?? 0,
      sayyiatRepented: json['sayyiat_repented'] as bool? ?? false,
      recordedAt: json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'] as String)
          : null,
      repentedAt: json['repented_at'] != null
          ? DateTime.parse(json['repented_at'] as String)
          : null,
    );
  }

  PrayerLog copyWith({
    String? id,
    String? userId,
    DateTime? date,
    PrayerName? prayer,
    PrayerStatus? status,
    int? hasanat,
    int? sayyiat,
    bool? sayyiatRepented,
    DateTime? recordedAt,
    DateTime? repentedAt,
  }) {
    return PrayerLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      prayer: prayer ?? this.prayer,
      status: status ?? this.status,
      hasanat: hasanat ?? this.hasanat,
      sayyiat: sayyiat ?? this.sayyiat,
      sayyiatRepented: sayyiatRepented ?? this.sayyiatRepented,
      recordedAt: recordedAt ?? this.recordedAt,
      repentedAt: repentedAt ?? this.repentedAt,
    );
  }
}