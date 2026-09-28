import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

/// A reusable error state widget with retry functionality.
///
/// Use this widget when an operation fails and the user can retry.
class ErrorState extends StatelessWidget {
  /// Error message to display.
  final String message;

  /// Optional detailed error description.
  final String? details;

  /// Callback when retry button is pressed.
  final VoidCallback? onRetry;

  /// Icon to display.
  final IconData icon;

  /// Size of the icon.
  final double iconSize;

  const ErrorState({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.iconSize = 64,
  });

  /// Creates an error state for network errors.
  factory ErrorState.network({VoidCallback? onRetry}) {
    return ErrorState(
      icon: Icons.wifi_off,
      message: 'Keine Internetverbindung',
      details: 'Bitte überprüfe deine Verbindung und versuche es erneut.',
      onRetry: onRetry,
    );
  }

  /// Creates an error state for server errors.
  factory ErrorState.server({VoidCallback? onRetry}) {
    return ErrorState(
      icon: Icons.cloud_off,
      message: 'Server nicht erreichbar',
      details: 'Es gab ein Problem mit dem Server. Bitte versuche es später erneut.',
      onRetry: onRetry,
    );
  }

  /// Creates an error state for loading errors.
  factory ErrorState.loading({String? itemType, VoidCallback? onRetry}) {
    return ErrorState(
      icon: Icons.refresh,
      message: 'Laden fehlgeschlagen',
      details: itemType != null
          ? '$itemType konnten nicht geladen werden.'
          : 'Die Daten konnten nicht geladen werden.',
      onRetry: onRetry,
    );
  }

  /// Creates an error state for generic errors.
  factory ErrorState.generic({String? message, VoidCallback? onRetry}) {
    return ErrorState(
      icon: Icons.error_outline,
      message: message ?? 'Etwas ist schiefgelaufen',
      details: 'Bitte versuche es erneut.',
      onRetry: onRetry,
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton.primary(
                onPressed: onRetry,
                label: 'Erneut versuchen',
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small inline error widget for form fields or compact spaces.
class InlineError extends StatelessWidget {
  /// Error message to display.
  final String message;

  const InlineError({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withAlpha(77),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Unified snackbar helper for error and success notifications.
class AppSnackbar {
  static void error(BuildContext context, String message, {VoidCallback? onRetry}) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: AppColors.error,
      action: onRetry != null
          ? SnackBarAction(label: 'Erneut', textColor: Colors.white, onPressed: onRetry)
          : null,
    );
  }

  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: AppColors.teal,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }
}
