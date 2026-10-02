import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/adhan_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/prayer_engine.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/error_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifEnabled = true;
  bool _adhanEnabled = true;
  bool _streakReminder = true;
  int _reminderMinutes = 5;
  String _city = 'القاهرة';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _notifEnabled = await NotificationService.isEnabled();
    _adhanEnabled = await NotificationService.isAdhanEnabled();
    _streakReminder = await NotificationService.isStreakReminderEnabled();
    _reminderMinutes = await NotificationService.reminderMinutes();
    final loc = await LocationService.current();
    _city = loc.city;
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.teal))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Location ────────────────────────────────────────
                  _section('الموقع'),
                  _tile(
                    icon: Icons.location_on,
                    title: 'المدينة',
                    subtitle: _city,
                    onTap: _pickCity,
                  ),
                  const SizedBox(height: 16),

                  // ── Prayer times preview ───────────────────────────
                  _section('توقيتات اليوم'),
                  _timesCard(),
                  const SizedBox(height: 16),

                  // ── Notifications ──────────────────────────────────
                  _section('الإشعارات'),
                  _switch(
                    'تفعيل الإشعارات',
                    'استقبل تنبيهات الصلاة والمواصلة',
                    _notifEnabled,
                    (v) async {
                      setState(() => _notifEnabled = v);
                      await NotificationService.setEnabled(v);
                    },
                  ),
                  _switch(
                    'أذان الصلاة',
                    'تشغيل صوت الأذان عند دخول الوقت',
                    _adhanEnabled,
                    (v) async {
                      setState(() => _adhanEnabled = v);
                      await NotificationService.setAdhanEnabled(v);
                    },
                  ),
                  _switch(
                    'تذكير المواصلة',
                    'تنبيه يومي قبل منتصف الليل للحفاظ على سلسلتك',
                    _streakReminder,
                    (v) async {
                      setState(() => _streakReminder = v);
                      await NotificationService.setStreakReminderEnabled(v);
                    },
                  ),
                  _tile(
                    icon: Icons.timer_outlined,
                    title: 'التذكير قبل الأذان',
                    subtitle: '$_reminderMinutes دقيقة',
                    onTap: _pickReminderMinutes,
                  ),
                  const SizedBox(height: 16),

                  // ── About ───────────────────────────────────────────
                  _section('عن التطبيق'),
                  _tile(
                    icon: Icons.info_outline,
                    title: 'الإصدار',
                    subtitle: '0.1.0 (MVP)',
                    onTap: null,
                  ),
                  _tile(
                    icon: Icons.mosque,
                    title: 'طريقة الحساب',
                    subtitle: 'الهيئة المصرية العامة للمساحة — شافعي',
                    onTap: null,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.gold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _switch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChange,
  ) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title,
            style: const TextStyle(
                color: AppColors.text, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
        value: value,
        onChanged: onChange,
        activeThumbColor: AppColors.teal,
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.teal),
        title: Text(title,
            style: const TextStyle(
                color: AppColors.text, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
        trailing:
            onTap != null ? const Icon(Icons.chevron_left) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _timesCard() {
    final timelines = PrayerEngine.computeAllTimelines();
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: timelines.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(e.key.icon, size: 18, color: AppColors.teal),
                const SizedBox(width: 10),
                Text(e.key.arabicName,
                    style: const TextStyle(color: AppColors.text)),
                const Spacer(),
                Text(
                  AdhanService.formatTime(e.value.adhan),
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _pickCity() async {
    final selected = await showModalBottomSheet<(String, double, double)>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: LocationService.presetCities.map((c) {
          return ListTile(
            title: Text(c.$1,
                style: const TextStyle(color: AppColors.text)),
            onTap: () => Navigator.pop(context, c),
            selected: c.$1 == _city,
            selectedTileColor: AppColors.teal.withAlpha(30),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      await LocationService.set(
        lat: selected.$2,
        lng: selected.$3,
        city: selected.$1,
      );
      AdhanService.setLocation(selected.$2, selected.$3);
      if (mounted) {
        setState(() => _city = selected.$1);
        AppSnackbar.success(context, 'تم تحديث الموقع');
      }
    }
  }

  Future<void> _pickReminderMinutes() async {
    final options = [0, 5, 10, 15, 30];
    final choice = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: options.map((m) {
          final label = m == 0 ? 'عند الأذان مباشرة' : '$m دقيقة';
          return ListTile(
            title: Text(label,
                style: const TextStyle(color: AppColors.text)),
            selected: m == _reminderMinutes,
            selectedTileColor: AppColors.teal.withAlpha(30),
            onTap: () => Navigator.pop(context, m),
          );
        }).toList(),
      ),
    );

    if (choice != null) {
      await NotificationService.setReminderMinutes(choice);
      if (mounted) setState(() => _reminderMinutes = choice);
    }
  }
}