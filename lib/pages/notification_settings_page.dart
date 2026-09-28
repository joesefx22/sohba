import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_scaffold.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _questCompleted = true;
  bool _rewardRedeemed = true;
  bool _newQuest = true;
  bool _streakReminder = false;

  static const String _keyQuestCompleted = 'notify_quest_completed';
  static const String _keyRewardRedeemed = 'notify_reward_redeemed';
  static const String _keyNewQuest = 'notify_new_quest';
  static const String _keyStreakReminder = 'notify_streak_reminder';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _questCompleted = prefs.getBool(_keyQuestCompleted) ?? true;
      _rewardRedeemed = prefs.getBool(_keyRewardRedeemed) ?? true;
      _newQuest = prefs.getBool(_keyNewQuest) ?? true;
      _streakReminder = prefs.getBool(_keyStreakReminder) ?? false;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: const GlassAppBar(
        title: Text('Benachrichtigungen'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 24, 16, 32),
          children: [
            GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Push-Benachrichtigungen',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildToggle(
                    'Quest abgeschlossen',
                    'Benachrichtigung wenn ein Kind einen Quest abschließt',
                    _questCompleted,
                    (v) {
                      setState(() => _questCompleted = v);
                      _save(_keyQuestCompleted, v);
                    },
                  ),
                  _buildToggle(
                    'Belohnung eingelöst',
                    'Benachrichtigung wenn eine Belohnung eingelöst wird',
                    _rewardRedeemed,
                    (v) {
                      setState(() => _rewardRedeemed = v);
                      _save(_keyRewardRedeemed, v);
                    },
                  ),
                  _buildToggle(
                    'Neuer Quest verfügbar',
                    'Benachrichtigung bei neuen Quests',
                    _newQuest,
                    (v) {
                      setState(() => _newQuest = v);
                      _save(_keyNewQuest, v);
                    },
                  ),
                  _buildToggle(
                    'Streak-Erinnerung',
                    'Tägliche Erinnerung um den Streak zu halten',
                    _streakReminder,
                    (v) {
                      setState(() => _streakReminder = v);
                      _save(_keyStreakReminder, v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Push-Benachrichtigungen sind noch nicht aktiv. '
                'Diese Einstellungen werden gespeichert und gelten, '
                'sobald Push-Benachrichtigungen verfügbar sind.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.teal,
    );
  }
}
