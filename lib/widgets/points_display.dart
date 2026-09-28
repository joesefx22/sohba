import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum PointsDisplayVariant { compact, large }

class PointsDisplay extends StatefulWidget {
  final int points;
  final PointsDisplayVariant variant;
  final bool showChange;
  final int? changeAmount;

  const PointsDisplay({
    super.key,
    required this.points,
    this.variant = PointsDisplayVariant.compact,
    this.showChange = false,
    this.changeAmount,
  });

  @override
  State<PointsDisplay> createState() => _PointsDisplayState();
}

class _PointsDisplayState extends State<PointsDisplay>
    with TickerProviderStateMixin {
  static const Color mochiGold = AppColors.gold;
  static const Color mochiGoldDark = AppColors.warning;

  late AnimationController _countController;
  late AnimationController _changeController;
  late Animation<double> _changeAnimation;
  late Animation<double> _changeFadeAnimation;

  int _displayedPoints = 0;
  int _previousPoints = 0;

  @override
  void initState() {
    super.initState();
    _displayedPoints = widget.points;
    _previousPoints = widget.points;

    _countController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _changeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _changeAnimation = Tween<double>(begin: 0, end: -30).animate(
      CurvedAnimation(
        parent: _changeController,
        curve: Curves.easeOut,
      ),
    );

    _changeFadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _changeController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _countController.addListener(_updateDisplayedPoints);
  }

  void _updateDisplayedPoints() {
    setState(() {
      _displayedPoints = (_previousPoints +
              (widget.points - _previousPoints) * _countController.value)
          .round();
    });
  }

  @override
  void didUpdateWidget(PointsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.points != widget.points) {
      _previousPoints = _displayedPoints;
      _countController.forward(from: 0);

      if (widget.showChange && widget.changeAmount != null) {
        _changeController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _countController.removeListener(_updateDisplayedPoints);
    _countController.dispose();
    _changeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.variant == PointsDisplayVariant.compact
        ? _buildCompact()
        : _buildLarge();
  }

  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [mochiGold, AppColors.gold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: mochiGold.withAlpha(100),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Colors.black87,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            '$_displayedPoints',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (widget.showChange && widget.changeAmount != null)
            _buildChangeIndicator(compact: true),
        ],
      ),
    );
  }

  Widget _buildLarge() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [mochiGold, AppColors.gold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: mochiGold.withAlpha(150),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: mochiGoldDark.withAlpha(50),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.black87,
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                '$_displayedPoints',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mochi Punkte',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
        if (widget.showChange && widget.changeAmount != null)
          Positioned(
            top: -10,
            right: -10,
            child: _buildChangeIndicator(compact: false),
          ),
      ],
    );
  }

  Widget _buildChangeIndicator({required bool compact}) {
    final isPositive = (widget.changeAmount ?? 0) > 0;
    final changeText =
        isPositive ? '+${widget.changeAmount}' : '${widget.changeAmount}';
    final color = isPositive ? Colors.green : Colors.red;

    return AnimatedBuilder(
      animation: _changeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _changeAnimation.value),
          child: Opacity(
            opacity: _changeFadeAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 6 : 8,
                vertical: compact ? 2 : 4,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(100),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                changeText,
                style: TextStyle(
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
