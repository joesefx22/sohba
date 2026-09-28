import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_scaffold.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: const GlassAppBar(
        title: Text('Hilfe & Support'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 24, 16, 32),
          children: [
            // FAQ Section
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Häufige Fragen',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFaqTile(
                    'Was sind Mochi Points?',
                    'Mochi Points sind die Belohnungspunkte, die Kinder '
                        'durch das Abschließen von Quests verdienen können. '
                        'Diese Punkte können im Shop gegen Belohnungen '
                        'eingetauscht werden.',
                  ),
                  _buildFaqTile(
                    'Wie erstelle ich einen Quest?',
                    'Navigiere zum Quests-Tab und tippe auf das + Symbol. '
                        'Dort kannst du Name, Beschreibung, Punkte und '
                        'Schwierigkeit des Quests festlegen.',
                  ),
                  _buildFaqTile(
                    'Wie funktioniert das Level-System?',
                    'Kinder verdienen XP durch das Abschließen von Quests. '
                        'Je mehr XP gesammelt werden, desto höher das Level. '
                        'Höhere Levels schalten neue Erfolge frei.',
                  ),
                  _buildFaqTile(
                    'Was sind Streaks?',
                    'Streaks zählen aufeinanderfolgende Tage, an denen '
                        'mindestens ein Quest abgeschlossen wurde. '
                        'Längere Streaks geben Bonus-Punkte!',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact Section
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kontakt',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.email_outlined,
                      color: AppColors.teal,
                    ),
                    title: const Text(
                      'E-Mail Support',
                      style: TextStyle(color: AppColors.text),
                    ),
                    subtitle: const Text(
                      'support@mochipoints.app',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // App Info Section
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'App Info',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Version', '1.0.0 (MVP)'),
                  _buildInfoRow('Flutter', '3.41+'),
                  _buildInfoRow('Build', 'Debug'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          question,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              answer,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
