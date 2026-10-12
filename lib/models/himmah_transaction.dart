/// One row from `himmah_transactions`.
///
/// Positive [amount] = credit (award), negative = debit (spend).
class HimmahTransaction {
  final String id;
  final String userId;
  final int amount;
  final String reason;
  final String? referenceId;
  final DateTime createdAt;

  const HimmahTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.reason,
    this.referenceId,
    required this.createdAt,
  });

  bool get isCredit => amount > 0;
  bool get isDebit => amount < 0;

  /// Arabic label for the reason code.
  String get reasonAr {
    switch (reason) {
      case 'streak_day':
        return 'مواصلة يومية';
      case 'milestone_7':
        return 'وسام 7 أيام';
      case 'milestone_14':
        return 'وسام 14 يومًا';
      case 'milestone_30':
        return 'وسام 30 يومًا';
      case 'milestone_60':
        return 'وسام 60 يومًا';
      case 'milestone_100':
        return 'وسام 100 يوم';
      case 'milestone_365':
        return 'وسام سنة كاملة';
      case 'protect_streak':
        return 'حماية المواصلة';
      case 'skip_optional':
        return 'تخطي السنن';
      case 'challenge_win':
        return 'فوز بتحدٍّ';
      default:
        return reason;
    }
  }

  factory HimmahTransaction.fromJson(Map<String, dynamic> j) {
    return HimmahTransaction(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      amount: (j['amount'] as num).toInt(),
      reason: j['reason'] as String,
      referenceId: j['reference_id'] as String?,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}