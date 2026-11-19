class AdminAlert {
  final String id;
  final String userId;
  final String? groupId;
  final String type;
  final String severity;
  final String title;
  final String message;
  final Map<String, dynamic>? payload;
  final bool isResolved;
  final DateTime createdAt;

  const AdminAlert({
    required this.id,
    required this.userId,
    this.groupId,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.payload,
    this.isResolved = false,
    required this.createdAt,
  });

  factory AdminAlert.fromJson(Map<String, dynamic> json) => AdminAlert(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        groupId: json['group_id'] as String?,
        type: json['type'] as String,
        severity: json['severity'] as String? ?? 'normal',
        title: json['title'] as String,
        message: json['message'] as String,
        payload: json['payload'] as Map<String, dynamic>?,
        isResolved: json['is_resolved'] == true,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}