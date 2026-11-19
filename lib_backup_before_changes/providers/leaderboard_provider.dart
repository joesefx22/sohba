import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int currentStreak;
  final int weeklyPoints;
  final int rank;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.currentStreak,
    required this.weeklyPoints,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) =>
      LeaderboardEntry(
        userId: j['user_id'] as String,
        displayName: j['display_name'] as String,
        avatarUrl: j['avatar_url'] as String?,
        currentStreak: j['current_streak'] as int? ?? 0,
        weeklyPoints: j['weekly_points'] as int? ?? 0,
        rank: j['rank'] as int? ?? 0,
      );
}

class LeaderboardProvider extends ChangeNotifier {
  List<LeaderboardEntry> _entries = [];
  bool _loading = false;
  String? _error;

  List<LeaderboardEntry> get entries => List.unmodifiable(_entries);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await Supabase.instance.client.rpc(
        'get_leaderboard_weekly',
        params: {'p_limit': 50},
      );
      _entries = (res as List)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('LeaderboardProvider.load: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}