import 'dart:math' as math;
import 'package:flutter/material.dart';

class RingProgress extends StatelessWidget {
  final double size;
  final double strokeWidth;

  final double progress;

  final Color? color;

  final List<Color>? gradient;

  final Color? backgroundColor;

  final Widget? child;

  const RingProgress({
    super.key,
    this.size = 120,
    this.strokeWidth = 12,
    required this.progress,
    this.color,
    this.gradient,
    this.backgroundColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final effectiveBg = backgroundColor ??
        Theme.of(context).dividerColor.withValues(alpha: 0.15);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress.clamp(0.0, 1.0),
              color: effectiveColor,
              gradient: gradient,
              backgroundColor: effectiveBg,
              strokeWidth: strokeWidth,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final List<Color>? gradient;
  final Color backgroundColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // ── Background track ──────────────────────────────────────────────────
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    // ── Progress arc ──────────────────────────────────────────────────────
    final sweepAngle = 2 * math.pi * progress;
    const startAngle = -math.pi / 2; // top

    final fgPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (gradient != null && gradient!.length >= 2) {
      // Build a SweepGradient that covers the swept arc.
      // We rotate the gradient so it starts at the top (−90°).
      final gradientColors = gradient!;

      // Create gradient shader covering the full circle so the visible
      // arc portion picks up the correct color stops.
      fgPaint.shader = SweepGradient(
        center: Alignment.center,
        startAngle: startAngle,
        endAngle: startAngle + 2 * math.pi,
        colors: [
          ...gradientColors,
          gradientColors.last, // repeat last to avoid hard edge at wrap
        ],
        stops: List.generate(
          gradientColors.length + 1,
          (i) => i < gradientColors.length
              ? i / (gradientColors.length - 1) * progress
              : 1.0,
        ),
        tileMode: TileMode.clamp,
      ).createShader(rect);
    } else {
      fgPaint.color = color;
    }

    canvas.drawArc(rect, startAngle, sweepAngle, false, fgPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.gradient != gradient ||
      old.backgroundColor != backgroundColor ||
      old.strokeWidth != strokeWidth;
}
