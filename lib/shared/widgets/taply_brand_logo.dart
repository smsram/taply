import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Simple, scalable brand logo for Taply – Assistive Touch.
/// Features a minimalist concentric touch emblem without robot imagery or literal hands.
class TaplyBrandLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const TaplyBrandLogo({super.key, this.size = 64.0, this.showShadow = true});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Taply Brand Logo',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: _TaplyLogoPainter(showShadow: showShadow),
        ),
      ),
    );
  }
}

class _TaplyLogoPainter extends CustomPainter {
  final bool showShadow;

  _TaplyLogoPainter({required this.showShadow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Optional subtle elevation shadow
    if (showShadow) {
      final shadowPaint = Paint()
        ..color = AppColors.primary.withOpacity(0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.25);
      canvas.drawCircle(
        center.translate(0, radius * 0.08),
        radius * 0.88,
        shadowPaint,
      );
    }

    // Outer Foundation Disc
    final basePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.92, basePaint);

    // Inner Concentric Wave Ring
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius * 0.62, ringPaint);

    // Subtle Secondary Accent Arc
    final accentPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.62),
      -0.5,
      1.8,
      false,
      accentPaint,
    );

    // Center Responsive Touch Core
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.28, corePaint);
  }

  @override
  bool shouldRepaint(covariant _TaplyLogoPainter oldDelegate) =>
      oldDelegate.showShadow != showShadow;
}
