import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            Text(message, textAlign: TextAlign.center,
                style: AppText.section.copyWith(fontSize: 17)),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(details!,
                  textAlign: TextAlign.center,
                  style: AppText.caption),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton.primary(
                label: 'أعد المحاولة',
                onPressed: onRetry,
                icon: Icons.refresh,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withAlpha(90)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 16, color: AppColors.error),
            const SizedBox(width: 8),
            Flexible(
              child: Text(message,
                  style: AppText.caption.copyWith(color: AppColors.error)),
            ),
          ],
        ),
      );
}

/// Unified snackbar — no shake, only a subtle border highlight.
class AppSnackbar {
  static void error(BuildContext context, String message, {VoidCallback? onRetry}) =>
      _show(context,
          message: message,
          icon: Icons.error_outline,
          accent: AppColors.error,
          action: onRetry);

  static void success(BuildContext context, String message) => _show(
        context,
        message: message,
        icon: Icons.check_circle_outline,
        accent: AppColors.emerald,
      );

  static void info(BuildContext context, String message) => _show(
        context,
        message: message,
        icon: Icons.info_outline,
        accent: AppColors.iman,
      );

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color accent,
    VoidCallback? action,
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: accent.withAlpha(120)),
          ),
          action: action != null
              ? SnackBarAction(
                  label: 'إعادة',
                  textColor: accent,
                  onPressed: action,
                )
              : null,
        ),
      );
  }
}