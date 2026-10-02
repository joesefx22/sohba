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
    final loc = await LocationService.current();
    AdhanService.setLocation(loc.lat, loc.lng);

    final auth = context.read<AuthProvider>();
    for (int i = 0; i < 20 && auth.status == AuthStatus.unknown; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    if (!auth.isLoggedIn) {
      _go(const LoginPage());
      return;
    }

    final userId = auth.user!.id;

    // Run daily maintenance (sweep missed prayers + detect streak loss) FIRST
    try {
      await SchedulerService.runDailyMaintenance(
        userId: userId,
        streakProvider: context.read<StreakProvider>(),
      );
    } catch (e) {
      debugPrint('SchedulerService error: $e');
    }

    if (!mounted) return;

    // Then load everything in parallel
    await Future.wait([
      context.read<GroupProvider>().loadForUser(userId),
      context.read<PrayerProvider>().loadToday(userId),
      context.read<BadgeProvider>().loadForUser(userId),
      context.read<StreakProvider>().loadForUser(userId),
      context.read<NotificationProvider>().loadForUser(userId),
      context.read<AthkarProvider>().loadAll(userId),
      auth.refreshProfile(),
    ]);

    if (!mounted) return;

    // Sync lock state from freshly-refreshed profile
    context.read<LockProvider>().syncFromProfile(auth.profile);

    // Load daily lesson + group challenges (if in a group)
    await Future.wait([
      context.read<DailyLessonProvider>().loadForUser(userId),
      if (context.read<GroupProvider>().group != null)
        context.read<ChallengeProvider>().loadForGroup(
              context.read<GroupProvider>().group!['id'] as String,
            ),
    ]);

    if (!mounted) return;

    final lock = context.read<LockProvider>();
    final group = context.read<GroupProvider>();
    if (lock.isLocked) {
      _go(const HomePage()); // LockScreen will gate inside HomePage
    } else {
      _go(group.hasGroup ? const HomePage() : const JoinGroupPage());
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