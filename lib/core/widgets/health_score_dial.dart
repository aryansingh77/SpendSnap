import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Custom-painted arc dial showing the Spending Health Score (0–100).
class HealthScoreDial extends StatefulWidget {
  const HealthScoreDial({super.key, required this.score});
  final int score;

  @override
  State<HealthScoreDial> createState() => _HealthScoreDialState();
}

class _HealthScoreDialState extends State<HealthScoreDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _progressAnim = Tween<double>(begin: 0, end: widget.score / 100.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(HealthScoreDial old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _progressAnim = Tween<double>(
        begin: _progressAnim.value,
        end: widget.score / 100.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _colorForScore(int score) {
    if (score >= 75) return AppColors.primary;
    if (score >= 50) return AppColors.warning;
    return AppColors.expense;
  }

  String _labelForScore(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Good';
    if (score >= 45) return 'Fair';
    return 'Needs Work';
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForScore(widget.score);
    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (_, __) => SizedBox(
        width: 160,
        height: 100,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(160, 100),
              painter: _DialPainter(
                progress: _progressAnim.value,
                color: color,
                trackColor: AppColors.cardBorder,
              ),
            ),
            Positioned(
              bottom: 4,
              child: Column(
                children: [
                  Text(
                    '${(_progressAnim.value * 100).round()}',
                    style: AppTypography.textTheme.displayLarge?.copyWith(
                      fontSize: 28,
                      color: color,
                    ),
                  ),
                  Text(
                    _labelForScore(widget.score),
                    style: AppTypography.textTheme.labelMedium?.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });
  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 10;
    final radius = size.width / 2 - 12;
    const startAngle = math.pi;
    const sweepTotal = math.pi;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepTotal * progress,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.progress != progress || old.color != color;
}
