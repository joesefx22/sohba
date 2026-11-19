import 'package:flutter/material.dart';

import '../../models/prayer_log.dart';
import '../../services/adhan_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_scheduler.dart';
import '../../services/notification_service.dart';
import '../../services/prayer_engine.dart';
import '../../services/push_notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/error_state.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/ribbon_card.dart';

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
                child: CircularProgressIndicator(color: AppColors.goldBright),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _section('الموقع'),
                  _tile(
                    icon: Icons.location_on,
                    title: 'المدينة',
                    subtitle: _city,
                    onTap: _pickCity,
                    accent: AppColors.iman,
                  ),
                  const SizedBox(height: 16),

                  _section('توقيتات اليوم'),
                  _timesCard(),
                  const SizedBox(height: 16),

                  _section('الإشعارات'),

                  if (!_systemPermission) ...[
                    _permissionBanner(),
                    const SizedBox(height: 10),
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
                    accent: AppColors.mint,
                  ),
                  const SizedBox(height: 12),
                  _testButton(),
                  const SizedBox(height: 16),

                  _section('عن التطبيق'),
                  _tile(
                    icon: Icons.info_outline,
                    title: 'الإصدار',
                    subtitle: '0.1.0 (MVP)',
                    onTap: null,
                    accent: AppColors.textSecondary,
                  ),
                  _tile(
                    icon: Icons.mosque,
                    title: 'طريقة الحساب',
                    subtitle: 'الهيئة المصرية العامة للمساحة — شافعي',
                    onTap: null,
                    accent: AppColors.gold,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 4, top: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.goldBright,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionBanner() {
    return RibbonCard(
      accent: AppColors.warning,
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'الإشعارات غير مسموح بها في النظام',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'افتح الإعدادات واسمح بالإشعارات حتى تصلك تنبيهات الصلاة.',
            style: AppText.caption.copyWith(fontSize: 12),
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
                foregroundColor: AppColors.background,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _testButton() {
    return RibbonCard(
      accent: AppColors.mint,
      radius: 20,
      padding: EdgeInsets.zero,
      onTap: () async {
        await NotificationScheduler.sendTest();
        if (!mounted) return;
        AppSnackbar.info(context, 'أُرسل — سيصل خلال 5 ثوانٍ');
      },
      child: ListTile(
        leading: const Icon(Icons.notification_add, color: AppColors.mint),
        title: const Text(
          'إشعار تجريبي',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text('سيصل خلال 5 ثوانٍ', style: AppText.caption),
        trailing: const Icon(Icons.chevron_left,
            color: AppColors.textSecondary),
      ),
    );
  }

  Widget _switch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChange,
  ) {
    return RibbonCard(
      accent: value ? AppColors.emerald : AppColors.textSecondary,
      radius: 18,
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(subtitle, style: AppText.caption.copyWith(fontSize: 11)),
        value: value,
        onChanged: onChange,
        activeThumbColor: AppColors.goldBright,
        activeTrackColor: AppColors.gold.withValues(alpha: .35),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color accent = AppColors.mint,
  }) {
    return RibbonCard(
      accent: accent,
      radius: 18,
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: accent.withValues(alpha: .38)),
          ),
          child: Icon(icon, color: accent, size: 19),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(subtitle, style: AppText.caption.copyWith(fontSize: 11)),
        trailing:
            onTap != null ? const Icon(Icons.chevron_left, size: 18) : null,
      ),
    );
  }

  Widget _timesCard() {
    final timelines = PrayerEngine.computeAllTimelines();
    return RibbonCard(
      accent: AppColors.gold,
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: timelines.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(e.key.icon,
                      size: 16, color: AppColors.goldBright),
                ),
                const SizedBox(width: 10),
                Text(e.key.arabicName,
                    style: const TextStyle(
                        color: AppColors.text, fontSize: 13)),
                const Spacer(),
                Text(
                  AdhanService.formatTime(e.value.adhan),
                  style: const TextStyle(
                    color: AppColors.goldBright,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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
      backgroundColor: AppColors.surfaceElevated,
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
            selectedTileColor: AppColors.gold.withValues(alpha: .15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
      backgroundColor: AppColors.surfaceElevated,
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
            selectedTileColor: AppColors.gold.withValues(alpha: .15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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