import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../models/prayer_log.dart';
import '../../services/adhan_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_scheduler.dart';
import '../../services/notification_service.dart';
import '../../services/prayer_engine.dart';
import '../../services/push_notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
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
  bool _systemPermission = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      NotificationService.isEnabled(),
      NotificationService.isAdhanEnabled(),
      NotificationService.isStreakReminderEnabled(),
      NotificationService.reminderMinutes(),
      LocationService.current(),
      PushNotificationService.hasPermission(),
    ]);

    if (!mounted) return;
    setState(() {
      _notifEnabled = results[0] as bool;
      _adhanEnabled = results[1] as bool;
      _streakReminder = results[2] as bool;
      _reminderMinutes = results[3] as int;
      _city = (results[4] as ({double lat, double lng, String city})).city;
      _systemPermission = results[5] as bool;
      _loading = false;
    });
  }

  Future<void> _requestPermission() async {
    final granted = await PushNotificationService.requestPermissions();
    if (!mounted) return;
    setState(() => _systemPermission = granted);
    if (granted) {
      AppSnackbar.success(context, 'تم تفعيل الإشعارات');
      await NotificationScheduler.rescheduleAll();
    } else {
      AppSnackbar.error(
          context, 'لم تُفعَّل الإشعارات — افتح إعدادات النظام');
    }
  }

  Future<void> _reschedule() async {
    try {
      await NotificationScheduler.rescheduleAll();
    } catch (e) {
      debugPrint('reschedule error: $e');
    }
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
                child: CircularProgressIndicator(color: AppColors.mint),
              )
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

                  // System permission banner
                  if (!_systemPermission) ...[
                    _permissionBanner(),
                    const SizedBox(height: 12),
                  ],

                  _switch(
                    'تفعيل الإشعارات',
                    'استقبل تنبيهات الصلاة والمواصلة',
                    _notifEnabled,
                    (v) async {
                      setState(() => _notifEnabled = v);
                      await NotificationService.setEnabled(v);
                      await _reschedule();
                    },
                  ),
                  _switch(
                    'الأذان',
                    'إشعار بصوت مرتفع عند دخول الوقت',
                    _adhanEnabled,
                    (v) async {
                      setState(() => _adhanEnabled = v);
                      await NotificationService.setAdhanEnabled(v);
                      await _reschedule();
                    },
                  ),
                  _switch(
                    'تذكير المواصلة',
                    'تنبيه 9 مساءً قبل منتصف الليل',
                    _streakReminder,
                    (v) async {
                      setState(() => _streakReminder = v);
                      await NotificationService.setStreakReminderEnabled(v);
                      await _reschedule();
                    },
                  ),
                  _tile(
                    icon: Icons.timer_outlined,
                    title: 'تذكير قبل الأذان',
                    subtitle: _reminderMinutes == 0
                        ? 'معطّل'
                        : '$_reminderMinutes دقيقة',
                    onTap: _pickReminderMinutes,
                  ),
                  const SizedBox(height: 12),
                  _testButton(),
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
          color: AppColors.goldBright,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _permissionBanner() {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      tintColor: AppColors.warning.withAlpha(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'الإشعارات غير مسموح بها في النظام',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'افتح الإعدادات واسمح بالإشعارات حتى تصلك تنبيهات الصلاة.',
            style: AppText.caption,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.notifications_active, size: 18),
              label: const Text('سماح'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _testButton() {
    return GlassContainer(
      child: ListTile(
        leading: const Icon(Icons.notification_add, color: AppColors.mint),
        title: const Text(
          'إشعار تجريبي',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w500),
        ),
        subtitle: Text('سيصل خلال 5 ثوانٍ', style: AppText.caption),
        trailing: const Icon(Icons.chevron_left),
        onTap: () async {
          await NotificationScheduler.sendTest();
          if (!mounted) return;
          AppSnackbar.info(context, 'أُرسل — سيصل خلال 5 ثوانٍ');
        },
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
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(subtitle, style: AppText.caption),
        value: value,
        onChanged: onChange,
        activeThumbColor: AppColors.emerald,
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
        leading: Icon(icon, color: AppColors.mint),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(subtitle, style: AppText.caption),
        trailing: onTap != null ? const Icon(Icons.chevron_left) : null,
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
                Icon(e.key.icon, size: 18, color: AppColors.mint),
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
            title: Text(c.$1, style: const TextStyle(color: AppColors.text)),
            onTap: () => Navigator.pop(context, c),
            selected: c.$1 == _city,
            selectedTileColor: AppColors.mint.withAlpha(30),
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
      await _reschedule();
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
          final label = m == 0 ? 'معطّل' : '$m دقيقة';
          return ListTile(
            title: Text(label,
                style: const TextStyle(color: AppColors.text)),
            selected: m == _reminderMinutes,
            selectedTileColor: AppColors.mint.withAlpha(30),
            onTap: () => Navigator.pop(context, m),
          );
        }).toList(),
      ),
    );

    if (choice != null) {
      await NotificationService.setReminderMinutes(choice);
      await _reschedule();
      if (mounted) setState(() => _reminderMinutes = choice);
    }
  }
}