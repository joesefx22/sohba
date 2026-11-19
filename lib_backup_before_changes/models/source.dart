class Source {
  final String id;
  final String textAr;
  final String reference;
  final String? grade;
  final String? url;

  const Source({
    required this.id,
    required this.textAr,
    required this.reference,
    this.grade,
    this.url,
  });

  factory Source.fromJson(Map<String, dynamic> json) => Source(
        id: json['id'] as String,
        textAr: json['text_ar'] as String,
        reference: json['reference'] as String,
        grade: json['grade'] as String?,
        url: json['url'] as String?,
      );
}