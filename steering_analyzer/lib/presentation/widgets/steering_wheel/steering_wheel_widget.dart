import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/steering_provider.dart';
import 'steering_wheel_painter.dart';

class SteeringWheelWidget extends StatelessWidget {
  const SteeringWheelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SteeringProvider>(
      builder: (context, p, _) {
        final angle = p.latestMeasurement?.angleDeg ?? 0.0;
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.maxWidth;
            return CustomPaint(
              size: Size(size, size),
              painter: SteeringWheelPainter(angleDeg: angle),
            );
          },
        );
      },
    );
  }
}
