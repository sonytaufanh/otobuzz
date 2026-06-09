import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/usecases/health_score_calculator.dart';

/// Circular animated health score widget.
///
/// Shows the score (0-100) in a circular progress ring with the grade letter
/// in the center, animated from 0 to the actual score.
class HealthScoreWidget extends StatefulWidget {
  final HealthScoreResult result;
  final double size;
  final bool compact;
  final VoidCallback? onTap;

  const HealthScoreWidget({
    super.key,
    required this.result,
    this.size = 160,
    this.compact = false,
    this.onTap,
  });

  @override
  State<HealthScoreWidget> createState() => _HealthScoreWidgetState();
}

class _HealthScoreWidgetState extends State<HealthScoreWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.result.score.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(HealthScoreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result.score != widget.result.score) {
      _animation = Tween<double>(
        begin: 0,
        end: widget.result.score.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    final size = widget.size;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final animatedScore = _animation.value;
          return SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _ScoreRingPainter(
                progress: animatedScore / 100,
                color: widget.result.color,
                strokeWidth: size * 0.08,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.result.grade,
                      style: TextStyle(
                        fontSize: size * 0.3,
                        fontWeight: FontWeight.bold,
                        color: widget.result.color,
                      ),
                    ),
                    Text(
                      '${animatedScore.round()}',
                      style: TextStyle(
                        fontSize: size * 0.15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    final size = widget.size;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final animatedScore = _animation.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _ScoreRingPainter(
                    progress: animatedScore / 100,
                    color: widget.result.color,
                    strokeWidth: size * 0.08,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.result.grade,
                          style: TextStyle(
                            fontSize: size * 0.28,
                            fontWeight: FontWeight.bold,
                            color: widget.result.color,
                          ),
                        ),
                        Text(
                          '${animatedScore.round()}/100',
                          style: TextStyle(
                            fontSize: size * 0.12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.result.description,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: widget.result.color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Custom painter that draws a circular progress ring.
class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final Color backgroundColor;

  _ScoreRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// A compact health score indicator for use in vehicle list cards.
class CompactHealthScore extends StatelessWidget {
  final HealthScoreResult result;
  final VoidCallback? onTap;

  const CompactHealthScore({
    super.key,
    required this.result,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: result.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: result.color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.grade,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: result.color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${result.score}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: result.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
