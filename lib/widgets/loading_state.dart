import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A reusable loading state widget with consistent styling.
///
/// Use this widget when loading data or waiting for an operation to complete.
class LoadingState extends StatelessWidget {
  /// Optional message to display below the loading indicator.
  final String? message;

  /// Size of the loading indicator.
  final double size;

  /// Whether to use a compact layout.
  final bool compact;

  const LoadingState({
    super.key,
    this.message,
    this.size = 40,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// A loading overlay that covers its child widget.
class LoadingOverlay extends StatelessWidget {
  /// Whether the loading overlay is visible.
  final bool isLoading;

  /// The child widget to cover.
  final Widget child;

  /// Optional message to display.
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(128),
              child: LoadingState(message: message, compact: true),
            ),
          ),
      ],
    );
  }
}

/// A shimmer loading placeholder for list items.
class ShimmerLoadingItem extends StatefulWidget {
  /// Height of the shimmer item.
  final double height;

  /// Border radius of the shimmer item.
  final double borderRadius;

  const ShimmerLoadingItem({
    super.key,
    this.height = 80,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerLoadingItem> createState() => _ShimmerLoadingItemState();
}

class _ShimmerLoadingItemState extends State<ShimmerLoadingItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.surface,
                AppColors.surfaceElevated,
                AppColors.surface,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A list of shimmer loading placeholders.
class ShimmerLoadingList extends StatelessWidget {
  /// Number of shimmer items to show.
  final int itemCount;

  /// Height of each shimmer item.
  final double itemHeight;

  const ShimmerLoadingList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => ShimmerLoadingItem(height: itemHeight),
    );
  }
}
