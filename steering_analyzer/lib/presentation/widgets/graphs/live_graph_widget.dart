import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/steering_provider.dart';
import 'live_graph_painter.dart';

class LiveGraphWidget extends StatelessWidget {
  final String title;
  final List<double> Function(SteeringProvider) dataGetter;
  final Color color;
  final double minY;
  final double maxY;
  final String unit;

  const LiveGraphWidget({
    super.key,
    required this.title,
    required this.dataGetter,
    required this.color,
    required this.minY,
    required this.maxY,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SteeringProvider>(
      builder: (context, p, _) {
        final data = dataGetter(p);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                '$title$unit',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8A93A3),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            SizedBox(
              height: 60,
              child: CustomPaint(
                size: Size.infinite,
                painter: LiveGraphPainter(
                  data: data,
                  color: color,
                  minY: minY,
                  maxY: maxY,
                  head: p.historyHead,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
