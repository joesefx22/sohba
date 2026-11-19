import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: AppColors.textSecondary.withAlpha(100)),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: AppText.section.copyWith(color: AppColors.textSecondary)),
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(description!,
                    textAlign: TextAlign.center,
                    style: AppText.caption),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                AppButton.primary(
                  label: actionLabel!,
                  onPressed: onAction,
                  icon: Icons.add,
                  expanded: false,
                ),
              ],
            ],
          ),
        ),
      );
}