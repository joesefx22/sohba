import 'enums.dart';

class User {
  final String id;
  final String familyId;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final String? pin;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.familyId,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.pin,
    required this.createdAt,
  });

  bool get isParent => role == UserRole.parent;
  bool get isChild => role == UserRole.child;
  bool get hasPin => pin != null && pin!.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'name': name,
      'email': email,
      'role': role.name,
      'avatarUrl': avatarUrl,
      'pin': pin,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.byName(json['role'] as String),
      avatarUrl: json['avatarUrl'] as String?,
      pin: json['pin'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  User copyWith({
    String? id,
    String? familyId,
    String? name,
    String? email,
    UserRole? role,
    String? avatarUrl,
    String? pin,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pin: pin ?? this.pin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
