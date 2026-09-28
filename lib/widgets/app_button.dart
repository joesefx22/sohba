import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// A styled app button with haptic feedback and consistent styling.
///
/// Provides primary, secondary, and text button variants with
/// proper tap feedback and optional loading state.
class AppButton extends StatefulWidget {
  /// Button label text.
  final String label;

  /// Callback when button is pressed.
  final VoidCallback? onPressed;

  /// Button variant style.
  final AppButtonVariant variant;

  /// Whether the button is in loading state.
  final bool isLoading;

  /// Optional icon to show before the label.
  final IconData? icon;

  /// Whether to expand to full width.
  final bool expanded;

  /// Custom padding.
  final EdgeInsets? padding;

  /// Custom background color (overrides variant default).
  final Color? backgroundColor;

  /// Custom foreground color (overrides variant default).
  final Color? foregroundColor;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expanded = false,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// Creates a primary button.
  factory AppButton.primary({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    bool expanded = false,
    EdgeInsets? padding,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.primary,
      isLoading: isLoading,
      icon: icon,
      expanded: expanded,
      padding: padding,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }

  /// Creates a secondary button.
  factory AppButton.secondary({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    bool expanded = false,
    EdgeInsets? padding,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.secondary,
      isLoading: isLoading,
      icon: icon,
      expanded: expanded,
      padding: padding,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }

  /// Creates a text button.
  factory AppButton.text({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    Color? foregroundColor,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.text,
      isLoading: isLoading,
      icon: icon,
      foregroundColor: foregroundColor,
    );
  }

  /// Creates a destructive button.
  factory AppButton.destructive({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    bool expanded = false,
    EdgeInsets? padding,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.destructive,
      isLoading: isLoading,
      icon: icon,
      expanded: expanded,
      padding: padding,
    );
  }

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  void _handleTap() {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: _buildButton(isDisabled),
      ),
    );
  }

  Widget _buildButton(bool isDisabled) {
    final colors = _getColors();
    final defaultPadding = widget.padding ??
        const EdgeInsets.symmetric(horizontal: 24, vertical: 14);

    Widget content = Row(
      mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colors.foreground),
            ),
          ),
          const SizedBox(width: 12),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: colors.foreground),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: TextStyle(
            color: colors.foreground,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (widget.variant == AppButtonVariant.text) {
      return Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Padding(
          padding: defaultPadding,
          child: content,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: defaultPadding,
      decoration: BoxDecoration(
        color: isDisabled ? colors.background.withAlpha(128) : colors.background,
        borderRadius: BorderRadius.circular(12),
        border: widget.variant == AppButtonVariant.secondary
            ? Border.all(color: colors.border, width: 2)
            : null,
        boxShadow: null,
      ),
      child: content,
    );
  }

  _ButtonColors _getColors() {
    final _ButtonColors defaults;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        defaults = _ButtonColors(
          background: AppColors.teal.withAlpha(200),
          foreground: Colors.white,
          border: Colors.transparent,
        );
      case AppButtonVariant.secondary:
        defaults = _ButtonColors(
          background: Colors.transparent,
          foreground: AppColors.teal,
          border: AppColors.teal,
        );
      case AppButtonVariant.text:
        defaults = _ButtonColors(
          background: Colors.transparent,
          foreground: AppColors.teal,
          border: Colors.transparent,
        );
      case AppButtonVariant.destructive:
        defaults = _ButtonColors(
          background: AppColors.error.withAlpha(200),
          foreground: Colors.white,
          border: Colors.transparent,
        );
    }
    return _ButtonColors(
      background: widget.backgroundColor ?? defaults.background,
      foreground: widget.foregroundColor ?? defaults.foreground,
      border: defaults.border,
    );
  }
}

enum AppButtonVariant {
  primary,
  secondary,
  text,
  destructive,
}

class _ButtonColors {
  final Color background;
  final Color foreground;
  final Color border;

  _ButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
  });
}

/// An icon button with haptic feedback.
class AppIconButton extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Callback when button is pressed.
  final VoidCallback? onPressed;

  /// Icon color.
  final Color? color;

  /// Icon size.
  final double size;

  /// Optional tooltip.
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 24,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      icon: Icon(icon, size: size),
      color: color ?? AppColors.textSecondary,
      onPressed: onPressed != null
          ? () {
              HapticFeedback.lightImpact();
              onPressed!();
            }
          : null,
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
