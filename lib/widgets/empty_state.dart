import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

/// A reusable empty state widget with consistent styling.
///
/// Use this widget when there is no data to display.
class EmptyState extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Title text.
  final String title;

  /// Optional description text.
  final String? description;

  /// Optional action button text.
  final String? actionLabel;

  /// Optional callback when action button is pressed.
  final VoidCallback? onAction;

  /// Size of the icon.
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
  });

  /// Creates an empty state for quests.
  factory EmptyState.quests({VoidCallback? onCreateQuest}) {
    return EmptyState(
      icon: Icons.explore_outlined,
      title: 'Keine Quests verfügbar',
      description: 'Es gibt gerade keine Quests zu erledigen.',
      actionLabel: onCreateQuest != null ? 'Quest erstellen' : null,
      onAction: onCreateQuest,
    );
  }

  /// Creates an empty state for rewards.
  factory EmptyState.rewards({VoidCallback? onCreateReward}) {
    return EmptyState(
      icon: Icons.card_giftcard_outlined,
      title: 'Keine Belohnungen verfügbar',
      description: 'Deine Eltern können neue Belohnungen erstellen.',
      actionLabel: onCreateReward != null ? 'Belohnung erstellen' : null,
      onAction: onCreateReward,
    );
  }

  /// Creates an empty state for transactions.
  factory EmptyState.transactions() {
    return const EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'Keine Transaktionen',
      description: 'Deine Punkte-Historie ist noch leer.',
    );
  }

  /// Creates an empty state for achievements.
  factory EmptyState.achievements() {
    return const EmptyState(
      icon: Icons.emoji_events_outlined,
      title: 'Noch keine Erfolge',
      description: 'Schließe Quests ab, um Erfolge freizuschalten!',
    );
  }

  /// Creates an empty state for approvals.
  factory EmptyState.approvals() {
    return const EmptyState(
      icon: Icons.check_circle_outlined,
      title: 'Keine ausstehenden Genehmigungen',
      description: 'Alle Quests wurden bereits überprüft.',
    );
  }

  /// Creates an empty state for search results.
  factory EmptyState.searchResults({String? query}) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'Keine Ergebnisse',
      description: query != null
          ? 'Keine Ergebnisse für "$query" gefunden.'
          : 'Versuche es mit anderen Suchbegriffen.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: AppColors.textSecondary.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withAlpha(179),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              AppButton.primary(
                onPressed: onAction,
                label: actionLabel!,
                icon: Icons.add,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
