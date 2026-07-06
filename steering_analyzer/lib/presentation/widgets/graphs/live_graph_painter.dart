import 'package:flutter/material.dart';

class LiveGraphPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double minY;
  final double maxY;
  final int head;

  LiveGraphPainter({
    required this.data,
    required this.color,
    required this.minY,
    required this.maxY,
    required this.head,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final len = data.length;
    if (len == 0) return;

    final range = maxY - minY;
    if (range <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final dx = size.width / len;

    for (int i = 0; i < len; i++) {
      final idx = (head + i) % len;
      final value = data[idx];
      final x = i * dx;
      final y = size.height - ((value - minY) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y.clamp(0, size.height));
      } else {
        path.lineTo(x, y.clamp(0, size.height));
      }
    }

    canvas.drawPath(path, paint);

    // Center line
    final centerPaint = Paint()
      ..color = const Color(0xFF1F242C)
      ..strokeWidth = 0.5;
    final centerY = size.height / 2;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(LiveGraphPainter oldDelegate) => true;
}
