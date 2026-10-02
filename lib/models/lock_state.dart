class LockState {
  final bool isLocked;
  final DateTime? lockedAt;
  final String? reason;
  final String? prayer;

  const LockState({
    this.isLocked = false,
    this.lockedAt,
    this.reason,
    this.prayer,
  });

  factory LockState.fromProfile(Map<String, dynamic>? p) {
    if (p == null) return const LockState();
    return LockState(
      isLocked: p['is_locked'] == true,
      lockedAt: p['locked_at'] != null ? DateTime.parse(p['locked_at']) : null,
      reason: p['locked_reason'],
      prayer: p['locked_prayer'],
    );
  }
}