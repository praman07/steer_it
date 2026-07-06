import 'dart:math' as math;
import 'package:flutter/material.dart';

class SteeringWheelPainter extends CustomPainter {
  final double angleDeg;

  SteeringWheelPainter({this.angleDeg = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    final angleRad = angleDeg * math.pi / 180.0;

    // Draw Stationary Reference Indicators (static, do not rotate)
    final Paint staticIndicatorPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    
    // Tiny arrow pointing down at 12 o'clock
    final Path arrowPath = Path();
    arrowPath.moveTo(center.dx, center.dy - radius - 16);
    arrowPath.lineTo(center.dx - 6, center.dy - radius - 24);
    arrowPath.lineTo(center.dx + 6, center.dy - radius - 24);
    arrowPath.close();
    canvas.drawPath(arrowPath, staticIndicatorPaint);

    // Save canvas to perform rotation around center
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleRad); // rotate clockwise by the steering angle

    // 1. Draw Outer Rim (Thick grip area)
    final Paint gripPaint = Paint()
      ..color = const Color(0xFF161616)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(Offset.zero, radius, gripPaint);

    // 2. Draw Metallic Inner Rim Accent
    final Paint innerRimAccent = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset.zero, radius - 6, innerRimAccent);

    // 3. Draw 12 o'clock Racing Stripe (White indicator)
    final Paint stripePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    
    // Draw top stripe centered at (0, -radius)
    final Rect stripeRect = Rect.fromCenter(
      center: Offset(0, -radius),
      width: 14,
      height: 12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(stripeRect, const Radius.circular(2)),
      stripePaint,
    );

    // 4. Draw Spokes (GT-style 3-spoke design: Left, Right, Bottom)
    final Paint spokePaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;

    final Paint spokeBorderPaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // We define three spokes using polygon paths
    // Left Spoke (around 180 degrees)
    final Path leftSpoke = Path();
    leftSpoke.moveTo(-15, -6);
    leftSpoke.lineTo(-radius + 8, -12);
    leftSpoke.lineTo(-radius + 8, 12);
    leftSpoke.lineTo(-15, 6);
    leftSpoke.close();

    // Right Spoke (around 0 degrees)
    final Path rightSpoke = Path();
    rightSpoke.moveTo(15, -6);
    rightSpoke.lineTo(radius - 8, -12);
    rightSpoke.lineTo(radius - 8, 12);
    rightSpoke.lineTo(15, 6);
    rightSpoke.close();

    // Bottom Spoke (around 90 degrees / straight down)
    final Path bottomSpoke = Path();
    bottomSpoke.moveTo(-8, 15);
    bottomSpoke.lineTo(-12, radius - 8);
    bottomSpoke.lineTo(12, radius - 8);
    bottomSpoke.lineTo(8, 15);
    bottomSpoke.close();

    // Draw paths
    canvas.drawPath(leftSpoke, spokePaint);
    canvas.drawPath(leftSpoke, spokeBorderPaint);
    canvas.drawPath(rightSpoke, spokePaint);
    canvas.drawPath(rightSpoke, spokeBorderPaint);
    canvas.drawPath(bottomSpoke, spokePaint);
    canvas.drawPath(bottomSpoke, spokeBorderPaint);

    // 5. Draw Center Hub
    final Paint hubOuterPaint = Paint()
      ..color = const Color(0xFF0F0F0F)
      ..style = PaintingStyle.fill;
    
    final Paint hubBorderPaint = Paint()
      ..color = const Color(0xFF444444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset.zero, 28, hubOuterPaint);
    canvas.drawCircle(Offset.zero, 28, hubBorderPaint);

    // Inner horn button/center emblem
    final Paint hornPaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 16, hornPaint);
    canvas.drawCircle(Offset.zero, 16, hubBorderPaint);

    // Small detail: 3 hub bolts/screws (spaced 120 deg apart)
    final Paint boltPaint = Paint()
      ..color = const Color(0xFF555555)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 3; i++) {
      final double angle = i * 2.0 * math.pi / 3.0 - math.pi / 2.0;
      final double bx = math.cos(angle) * 22.0;
      final double by = math.sin(angle) * 22.0;
      canvas.drawCircle(Offset(bx, by), 2.2, boltPaint);
    }

    // Restore canvas
    canvas.restore();
  }

  @override
  bool shouldRepaint(SteeringWheelPainter oldDelegate) =>
      oldDelegate.angleDeg != angleDeg;
}
