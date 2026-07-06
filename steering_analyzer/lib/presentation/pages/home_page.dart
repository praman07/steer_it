import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/steering_provider.dart';
import '../widgets/steering_wheel/steering_wheel_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Consumer<SteeringProvider>(
          builder: (context, p, _) {
            final double angle = p.latestMeasurement?.angleDeg ?? 0.0;
            final double rate = p.latestMeasurement?.rateDps ?? 0.0;
            final double accumulated = p.latestMeasurement?.accumulatedDeg ?? 0.0;
            final double turns = p.latestMeasurement?.turns ?? 0.0;
            final double confidence = p.latestMeasurement?.confidence ?? 0.0;

            final String stateText = p.isDriving ? 'ACTIVE TRANSMISSION' : 'STANDBY MODE';
            final Color stateColor = p.isDriving ? const Color(0xFFFFFFFF) : const Color(0xFF555555);

            return Column(
              children: [
                // Premium Status Bar
                _buildStatusBar(p, confidence),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Pulsing / Active state badge
                        _buildStateBadge(stateText, stateColor, p.isDriving),
                        const SizedBox(height: 24),

                        // Interactive Steering Wheel Box
                        Container(
                          height: 280,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF1E1E1E), width: 1.5),
                          ),
                          padding: const EdgeInsets.all(28),
                          child: const SteeringWheelWidget(),
                        ),
                        const SizedBox(height: 28),

                        // Readout Grid (2x2)
                        _buildReadoutGrid(angle, rate, accumulated, turns),
                        const SizedBox(height: 32),

                        // Secondary Calibration shortcut
                        _buildCalibrationShortcutCard(context, p),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Large Premium Action Button
                _buildDriveActionButton(p),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBar(SteeringProvider p, double confidence) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LOCAL ENGINE',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '100Hz processing active',
                    style: TextStyle(color: Color(0xFF555555), fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          // Right side
          Row(
            children: [
              // Battery
              Icon(
                p.batteryLevel > 20 ? Icons.battery_charging_full : Icons.battery_alert,
                color: const Color(0xFF888888),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${p.batteryLevel}%',
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
              const SizedBox(width: 16),
              // Confidence
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF222222)),
                ),
                child: Text(
                  'CONF: ${(confidence * 100).toInt()}%',
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateBadge(String text, Color color, bool isDriving) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDriving)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadoutGrid(double angle, double rate, double accumulated, double turns) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildReadoutTile(
                'STEERING ANGLE',
                '${angle.toStringAsFixed(1)}°',
                const Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildReadoutTile(
                'VELOCITY',
                '${rate.toStringAsFixed(0)}°/s',
                const Color(0xFFCCCCCC),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildReadoutTile(
                'ACCUMULATED',
                '${accumulated.toStringAsFixed(0)}°',
                const Color(0xFF888888),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildReadoutTile(
                'REVOLUTIONS',
                turns.toStringAsFixed(2),
                const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReadoutTile(String label, String value, Color valueColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 28,
              fontWeight: FontWeight.w200,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationShortcutCard(BuildContext context, SteeringProvider p) {
    final double bias = p.config.gyroBias;
    final double center = p.config.centerOffset;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CALIBRATION REFERENCE',
                style: TextStyle(color: Color(0xFF555555), fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Center: ${center.toStringAsFixed(1)}° | Gyro Bias: ${bias.toStringAsFixed(3)}°/s',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontFamily: 'Courier'),
              ),
            ],
          ),
          const Icon(
            Icons.chevron_right,
            color: Color(0xFF555555),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDriveActionButton(SteeringProvider p) {
    final bool active = p.isDriving;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(
          top: BorderSide(color: Color(0xFF1E1E1E), width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => p.toggleDriving(),
          style: ElevatedButton.styleFrom(
            backgroundColor: active ? const Color(0xFF161616) : const Color(0xFFFFFFFF),
            foregroundColor: active ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
            side: active ? const BorderSide(color: Color(0xFF333333)) : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: Text(
            active ? 'STOP TRANSMISSION' : 'START DRIVING',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
