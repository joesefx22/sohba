import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Global error handling for the app.
///
/// Flutter does NOT support widget-scoped error boundaries like React.
/// The real mechanism is [ErrorWidget.builder] — a global hook that
/// replaces any widget that throws during build/layout/paint.
///
/// Usage in `main.dart`:
/// ```dart
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   ErrorBoundary.install();
///   runApp(const SohbaApp());
/// }
/// ```
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  /// Optional hook for logging (e.g. to Sentry / Crashlytics).
  final void Function(Object error, StackTrace? stack)? onError;

  const ErrorBoundary({super.key, required this.child, this.onError});

  /// Install global handlers. Call once in `main()`.
  static void install({
    void Function(Object error, StackTrace? stack)? onError,
  }) {
    // 1) Catch framework errors (build/layout/paint).
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exception}\n${details.stack}');
      onError?.call(details.exception, details.stack);
    };

    // 2) Catch asynchronous errors that escape the framework.
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('PlatformError: $error\n$stack');
      onError?.call(error, stack);
      return true;
    };

    // 3) Replace the red screen with our friendly fallback.
    ErrorWidget.builder = (details) => _FriendlyErrorWidget(
          exception: details.exception,
        );
  }

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  ErrorWidgetBuilder? _previousBuilder;
  int _retryKey = 0;

  @override
  void initState() {
    super.initState();
    _previousBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (details) {
      widget.onError?.call(details.exception, details.stack);
      _scheduleError(details.exception);
      return _previousBuilder?.call(details) ??
          _FriendlyErrorWidget(exception: details.exception);
    };
  }

  @override
  void dispose() {
    if (_previousBuilder != null) {
      ErrorWidget.builder = _previousBuilder!;
    }
    super.dispose();
  }

  void _scheduleError(Object error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _error != null) return;
      setState(() => _error = error);
    });
  }

  void _retry() {
    setState(() {
      _error = null;
      _retryKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorFallback(error: _error, onRetry: _retry);
    }
    return KeyedSubtree(key: ValueKey(_retryKey), child: widget.child);
  }
}

/// Friendly full-screen fallback shown by [ErrorBoundary].
class _ErrorFallback extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _ErrorFallback({this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                const Text(
                  'حدث خطأ غير متوقع',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                if (error != null)
                  Text(
                    error.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mint,
                    foregroundColor: AppColors.background,
                  ),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders in place of a widget that threw during build.
class _FriendlyErrorWidget extends StatelessWidget {
  final Object? exception;
  const _FriendlyErrorWidget({this.exception});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: AppColors.background.withAlpha(200),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 28),
            const SizedBox(height: 6),
            const Text(
              'خطأ في هذا العنصر',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            if (kDebugMode && exception != null) ...[
              const SizedBox(height: 4),
              Text(
                exception.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}