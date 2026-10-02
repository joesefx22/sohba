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
import 'pages/splash_page.dart';
import 'widgets/error_boundary.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvConfig.load();

  if (!EnvConfig.isConfigured) {
    runApp(const _ConfigErrorApp());
    return;
  }

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
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
        ],
        child: MaterialApp(
          title: 'صحبة',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0A1F1A),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF198754),
              secondary: Color(0xFFD4AF37),
              surface: Color(0xFF1E3A32),
              error: Color(0xFFEF4444),
            ),
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar'), Locale('en')],
          locale: const Locale('ar'),
          home: const SplashPage(),
          routes: {
            '/splash': (_) => const SplashPage(),
          },
        ),
      ),
    );
  }
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A1F1A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.error_outline,
                    size: 64, color: Color(0xFFEF4444)),
                SizedBox(height: 16),
                Text(
                  'إعدادات ناقصة',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'تأكد من وجود ملف .env فيه SUPABASE_URL و SUPABASE_ANON_KEY',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}