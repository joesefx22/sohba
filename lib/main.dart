import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env_config.dart';
import 'providers/auth_provider.dart';
import 'providers/group_provider.dart';
import 'providers/prayer_provider.dart';
import 'providers/athkar_provider.dart';
import 'providers/badge_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/streak_provider.dart';
import 'providers/lock_provider.dart';
import 'providers/daily_lesson_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/himmah_provider.dart';                   // ← جديد
import 'pages/splash_page.dart';
import 'services/push_notification_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_text.dart';
import 'theme/app_theme.dart';
import 'widgets/error_boundary.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ← 1. Global error handling (must be FIRST)
  ErrorBoundary.install();

  // ← 2. Load env
  await EnvConfig.load();
  if (!EnvConfig.isConfigured) {
    runApp(const _ConfigErrorApp());
    return;
  }

  // ← 3. Supabase
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: EnvConfig.supabaseAnonKey,
  );

  // ← 4. Notifications (needs Supabase already up for logging)
  await PushNotificationService.init(
    onTap: (payload) {
      debugPrint('Notification tapped: $payload');
      // TODO: navigate to relevant screen based on payload
    },
  );

  runApp(const SohbaApp());
}

class SohbaApp extends StatelessWidget {
  const SohbaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
          ChangeNotifierProvider(create: (_) => GroupProvider()),
          ChangeNotifierProvider(create: (_) => PrayerProvider()),
          ChangeNotifierProvider(create: (_) => AthkarProvider()),
          ChangeNotifierProvider(create: (_) => BadgeProvider()),
          ChangeNotifierProvider(create: (_) => StreakProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => LockProvider()),
          ChangeNotifierProvider(create: (_) => DailyLessonProvider()),
          ChangeNotifierProvider(create: (_) => ChallengeProvider()),
          ChangeNotifierProvider(create: (_) => HimmahProvider()), // ← جديد
        ],
        child: MaterialApp(
          title: 'صحبة',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar'), Locale('en')],
          locale: const Locale('ar'),
          home: const SplashPage(),
          routes: {'/splash': (_) => const SplashPage()},
        ),
      ),
    );
  }
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('إعدادات ناقصة',
                      style: AppText.heading.copyWith(fontSize: 22)),
                  const SizedBox(height: 12),
                  Text(
                    'تأكد من وجود .env فيه SUPABASE_URL و SUPABASE_ANON_KEY',
                    textAlign: TextAlign.center,
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}