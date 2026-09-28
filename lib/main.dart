import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/hero_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/notification_provider.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SohbaApp());
}

class SohbaApp extends StatelessWidget {
  const SohbaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HeroProvider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'صحبة',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        locale: const Locale('ar'),
        home: const _BootstrapPage(),
      ),
    );
  }
}

/// Placeholder page — will be replaced with SplashPage once we add Supabase
class _BootstrapPage extends StatelessWidget {
  const _BootstrapPage();

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
              'صحبة',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'رفيقك على طريق الطاعة',
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
            const SizedBox(height: 24),
            Text(
              'قيد التهيئة...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withAlpha(120),
              ),
            ),
          ],
        ),
      ),
    );
  }
}