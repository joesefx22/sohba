class DailyLesson {
  final String id;
  final String title;
  final String? audioUrl;
  final int? durationSeconds;
  final String? transcript;
  final String? sourceId;
  final DateTime? publishDate;

  const DailyLesson({
    required this.id,
    required this.title,
    this.audioUrl,
    this.durationSeconds,
    this.transcript,
    this.sourceId,
    this.publishDate,
  });

  String get durationLabel {
    final s = durationSeconds ?? 0;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:'
        '${(s % 60).toString().padLeft(2, '0')}';
  }

  factory DailyLesson.fromJson(Map<String, dynamic> j) => DailyLesson(
        id: j['id'] as String,
        title: j['title'] as String,
        audioUrl: j['audio_url'] as String?,
        durationSeconds: j['duration_seconds'] as int?,
        transcript: j['transcript'] as String?,
        sourceId: j['source_id'] as String?,
        publishDate: j['publish_date'] != null
            ? DateTime.parse(j['publish_date'])
            : null,
      );
}