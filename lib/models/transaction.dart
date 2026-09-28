import 'enums.dart';

class Transaction {
  final String id;
  final String userId;
  final TransactionType type;
  final int amount;
  final int balanceAfter;
  final String? referenceId;
  final String? description;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.referenceId,
    this.description,
    required this.createdAt,
  });

  bool get isEarned => amount > 0;
  bool get isSpent => amount < 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'referenceId': referenceId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: TransactionType.values.byName(json['type'] as String),
      amount: json['amount'] as int,
      balanceAfter: json['balanceAfter'] as int,
      referenceId: json['referenceId'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Transaction copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    int? amount,
    int? balanceAfter,
    String? referenceId,
    String? description,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      referenceId: referenceId ?? this.referenceId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
