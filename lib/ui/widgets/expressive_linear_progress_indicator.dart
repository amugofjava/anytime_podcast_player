// Adapted from gidrokolbaska/flutter_material3_expressive_progress_indicator.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class ExpressiveLinearProgressIndicator extends StatefulWidget {
  final double? value;
  final double minHeight;
  final double amplitude;
  final double frequency;
  final double phaseCycles;
  final bool animated;
  final Duration animationDuration;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadiusGeometry borderRadius;

  const ExpressiveLinearProgressIndicator({
    super.key,
    this.value,
    this.minHeight = 4.0,
    this.amplitude = 5.0,
    this.frequency = 10.0,
    this.phaseCycles = 2.0,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 720),
    this.color,
    this.backgroundColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(999.0)),
  }) : assert(minHeight > 0);

  @override
  State<ExpressiveLinearProgressIndicator> createState() => _ExpressiveLinearProgressIndicatorState();
}

class _ExpressiveLinearProgressIndicatorState extends State<ExpressiveLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.animationDuration);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant ExpressiveLinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationDuration != widget.animationDuration) {
      _controller.duration = widget.animationDuration;
    }

    _syncAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncAnimation() {
    if (widget.animated) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else if (_controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: (widget.value ?? 0.0).clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, _) {
            return SizedBox(
              width: double.infinity,
              height: widget.minHeight,
              child: CustomPaint(
                painter: _ExpressiveIndicatorPainter(
                  value: widget.value == null ? null : animatedValue,
                  phase: _controller.value * widget.phaseCycles * 2 * math.pi,
                  color: widget.color ?? theme.colorScheme.primary,
                  backgroundColor: widget.backgroundColor ?? theme.colorScheme.secondaryContainer,
                  borderRadius: widget.borderRadius.resolve(Directionality.of(context)),
                  amplitude: widget.amplitude,
                  frequency: widget.frequency,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ExpressiveIndicatorPainter extends CustomPainter {
  final double? value;
  final double phase;
  final Color color;
  final Color backgroundColor;
  final BorderRadius borderRadius;
  final double amplitude;
  final double frequency;

  const _ExpressiveIndicatorPainter({
    required this.value,
    required this.phase,
    required this.color,
    required this.backgroundColor,
    required this.borderRadius,
    required this.amplitude,
    required this.frequency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()..color = backgroundColor;
    final trackRRect = borderRadius.toRRect(Offset.zero & size);
    canvas.drawRRect(trackRRect, trackPaint);

    final progress = value;
    if (progress == null || progress <= 0.0) {
      return;
    }

    final width = size.width * progress.clamp(0.0, 1.0);
    final leftInset = size.height / 2;
    final rightInset = width - size.height / 2;
    final strokeWidth = size.height;

    final wavePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (width <= strokeWidth * 2) {
      final rect = Rect.fromLTWH(0.0, 0.0, width, size.height);
      canvas.drawRRect(borderRadius.toRRect(rect), Paint()..color = color);
      return;
    }

    final path = Path();
    final verticalOffset = size.height / 2;
    final easedAmplitude = amplitude * _fade(progress);
    final angularFrequency = 2 * math.pi / size.width * frequency;

    for (double dx = 0.0; dx <= rightInset - leftInset; dx++) {
      final x = leftInset + dx;
      final y = easedAmplitude * math.sin(angularFrequency * x + phase) + verticalOffset;

      if (dx == 0.0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, wavePaint);
  }

  double _fade(double progress) {
    double smoothStep(double edge0, double edge1, double x) {
      final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
      return t * t * (3 - 2 * t);
    }

    const fadeWidth = 0.05;
    final fadeIn = smoothStep(0.05, 0.05 + fadeWidth, progress);
    final fadeOut = 1.0 - smoothStep(0.95 - fadeWidth, 0.95, progress);
    return fadeIn * fadeOut;
  }

  @override
  bool shouldRepaint(covariant _ExpressiveIndicatorPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.phase != phase ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.frequency != frequency;
  }
}
