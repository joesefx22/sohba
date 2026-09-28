import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/hero_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/points_provider.dart';
import '../providers/quest_provider.dart';
import '../providers/reward_provider.dart';
import '../widgets/glass_scaffold.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final authProvider = context.read<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final heroProvider = context.read<HeroProvider>();
    final pointsProvider = context.read<PointsProvider>();
    final questProvider = context.read<QuestProvider>();
    final rewardProvider = context.read<RewardProvider>();

    await authProvider.initialize();

    // Load every provider's persisted data before routing anywhere.
    // Without this, earlier bugs let providers present empty state until
    // a write operation lazily re-seeded them — which then overwrote
    // storage with in-memory zeros. See #205.
    await Future.wait([
      notificationProvider.loadData(),
      heroProvider.loadData(),
      pointsProvider.loadData(),
      questProvider.loadQuests(),
      rewardProvider.loadData(),
    ]);

    if (!mounted) return;

    // Check if family exists
    if (authProvider.currentFamily == null) {
      // No family -> Family Setup
      Navigator.of(context).pushReplacementNamed('/family-setup');
    } else if (authProvider.isLoggedIn) {
      // Family exists and user logged in -> Dashboard
      if (authProvider.isParent) {
        Navigator.of(context).pushReplacementNamed('/parent-dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/hero-home');
      }
    } else {
      // Family exists but no user logged in -> Login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
