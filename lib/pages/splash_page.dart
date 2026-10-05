import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/prayer_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/athkar_provider.dart';
import '../providers/lock_provider.dart';
import '../providers/daily_lesson_provider.dart';
import '../providers/challenge_provider.dart';
import '../services/adhan_service.dart';
import '../services/location_service.dart';
import '../services/scheduler_service.dart';
import '../config/app_config.dart';
import 'auth/login_page.dart';
import 'group/join_group_page.dart';
import 'home/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    // Capture all providers BEFORE any await
    final auth = context.read<AuthProvider>();
    final streakProvider = context.read<StreakProvider>();
    final groupProvider = context.read<GroupProvider>();
    final prayerProvider = context.read<PrayerProvider>();
    final badgeProvider = context.read<BadgeProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final athkarProvider = context.read<AthkarProvider>();
    final lessonProvider = context.read<DailyLessonProvider>();
    final lockProvider = context.read<LockProvider>();
    final challengeProvider = context.read<ChallengeProvider>();

    final loc = await LocationService.current();
    AdhanService.setLocation(loc.lat, loc.lng);

    for (int i = 0; i < 20 && auth.status == AuthStatus.unknown; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    if (!auth.isLoggedIn) {
      _go(const LoginPage());
      return;
    }

    final userId = auth.user!.id;

    try {
      await SchedulerService.runDailyMaintenance(
        userId: userId,
        streakProvider: streakProvider,
      );
    } catch (e) {
      debugPrint('SchedulerService error: $e');
    }

    if (!mounted) return;

    await Future.wait([
      groupProvider.loadForUser(userId),
      prayerProvider.loadToday(userId),
      badgeProvider.loadForUser(userId),
      streakProvider.loadForUser(userId),
      notificationProvider.loadForUser(userId),
      athkarProvider.loadAll(userId),
      auth.refreshProfile(),
    ]);

    if (!mounted) return;

    lockProvider.syncFromProfile(auth.profile);

    await lessonProvider.loadForUser(userId);
    final g = groupProvider.group;
    if (g != null) {
      await challengeProvider.loadForGroup(g['id'] as String);
    }

    if (!mounted) return;

    if (lockProvider.isLocked) {
      _go(const HomePage());
    } else {
      _go(groupProvider.hasGroup ? const HomePage() : const JoinGroupPage());
    }
  }

  void _go(Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mosque, size: 96, color: Color(0xFFD4AF37)),
            const SizedBox(height: 32),
            const Text(
              AppConfig.appName,
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppConfig.appTagline,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withAlpha(180),
              ),
            ),
            const SizedBox(height: 64),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF198754),
              ),
            ),
          ],
        ),
      ),
    );
  }
}