class Challenge {
  final String id;
  final String groupId;
  final String title;
  final String type;
  final int targetDays;
  final DateTime startsAt;
  final DateTime endsAt;
  final int participantCount;

  const Challenge({
    required this.id,
    required this.groupId,
    required this.title,
    required this.type,
    required this.targetDays,
    required this.startsAt,
    required this.endsAt,
    this.participantCount = 0,
  });

  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
        id: j['id'] as String,
        groupId: j['group_id'] as String,
        title: j['title'] as String,
        type: j['type'] as String,
        targetDays: j['target_days'] as int,
        startsAt: DateTime.parse(j['starts_at']),
        endsAt: DateTime.parse(j['ends_at']),
        participantCount: (j['participant_count'] as int?) ?? 0,
      );
}

class ChallengeParticipant {
  final String challengeId;
  final String userId;
  final int progress;
  final bool completed;

  const ChallengeParticipant({
    required this.challengeId,
    required this.userId,
    required this.progress,
    required this.completed,
  });

  factory ChallengeParticipant.fromJson(Map<String, dynamic> j) =>
      ChallengeParticipant(
        challengeId: j['challenge_id'] as String,
        userId: j['user_id'] as String,
        progress: j['progress'] as int? ?? 0,
        completed: j['completed'] == true,
      );
}