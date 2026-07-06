import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/steering_provider.dart';

class CalibrationPage extends StatefulWidget {
  const CalibrationPage({super.key});

  @override
  State<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        foregroundColor: const Color(0xFFFFFFFF),
        title: const Text(
          'CALIBRATION WIZARD',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFF1E1E1E),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar / Steps indicator
            _buildProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: _buildStepContent(),
              ),
            ),
            _buildNavigationRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: const Color(0xFF0A0A0A),
      child: Row(
        children: List.generate(5, (index) {
          final isCompleted = index < _currentStep;
          final isActive = index == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFFFFFFFF)
                          : isActive
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFF333333),
                      width: isActive ? 2 : 1,
                    ),
                    color: isCompleted ? const Color(0xFFFFFFFF) : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
                if (index < 4)
                  Expanded(
                    child: Container(
                      height: 1,
                      color: index < _currentStep
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF222222),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return const _StepSetCenter();
      case 1:
        return const _StepGyroBias();
      case 2:
        return const _StepLimits();
      case 3:
        return const _StepDrift();
      case 4:
        return const _StepValidation();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(
          top: BorderSide(color: Color(0xFF1E1E1E), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFFFFF),
                side: const BorderSide(color: Color(0xFF333333)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              child: const Text('BACK'),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: () {
              if (_currentStep < 4) {
                setState(() {
                  _currentStep++;
                });
              } else {
                // Done! Navigate back
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFFFFF),
              foregroundColor: const Color(0xFF000000),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              elevation: 0,
            ),
            child: Text(_currentStep == 4 ? 'FINISH' : 'NEXT'),
          ),
        ],
      ),
    );
  }
}

// ---- Step 1: Set Center ----
class _StepSetCenter extends StatelessWidget {
  const _StepSetCenter();

  @override
  Widget build(BuildContext context) {
    return Consumer<SteeringProvider>(
      builder: (context, p, _) {
        final currentAngle = p.latestMeasurement?.angleDeg ?? 0.0;
        final centerOffset = p.config.centerOffset;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '01 / ALIGN CENTER',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Mount the phone firmly onto the steering rig, center the physical wheel, and level the phone.',
              style: TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E1E1E)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                children: [
                  const Text(
                    'CURRENT ANGLE',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${currentAngle.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 64,
                      fontWeight: FontWeight.w200,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Center Offset: ${centerOffset.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => p.calibrateCenter(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFFFFF),
                  side: const BorderSide(color: Color(0xFFFFFFFF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'ALIGN CENTER POINT',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---- Step 2: Gyro Bias Calibration ----
class _StepGyroBias extends StatelessWidget {
  const _StepGyroBias();

  @override
  Widget build(BuildContext context) {
    return Consumer<SteeringProvider>(
      builder: (context, p, _) {
        final double bias = p.config.gyroBias;
        final bool isCalibrating = p.isCalibratingBias;
        final double progress = p.biasCalProgress;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '02 / SENSOR BIAS CORRECTION',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Static gyroscope bias leads to steering drift over time. Place the wheel in a stable position and keep it completely stationary during the test.',
              style: TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E1E1E)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'CALIBRATED STATIC BIAS',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${bias.toStringAsFixed(4)}°/s',
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isCalibrating) ...[
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFF1E1E1E),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFFFFF)),
                      minHeight: 4,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sampling raw values... ${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                      ),
                    ),
                  ] else
                    const Text(
                      'Ready to calibrate static bias.',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: isCalibrating ? null : () => p.startBiasCalibration(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFFFFF),
                  disabledForegroundColor: const Color(0xFF333333),
                  side: BorderSide(
                    color: isCalibrating ? const Color(0xFF333333) : const Color(0xFFFFFFFF),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'CALIBRATE STATIC BIAS',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---- Step 3: Limits & Sensitivity ----
class _StepLimits extends StatelessWidget {
  const _StepLimits();

  @override
  Widget build(BuildContext context) {
    return Consumer<SteeringProvider>(
      builder: (context, p, _) {
        final double currentLock = p.config.steeringLock;
        final double sensitivity = p.config.sensitivity;
        final double deadzone = p.config.deadzone;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '03 / STEERING CONFIGURATION',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Configure responsiveness coefficients and maximum physical rotation limits.',
              style: TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Steering Lock selector
            _buildSectionHeader('STEERING LOCK (MAX ANGLE)'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [360.0, 540.0, 900.0, 1080.0].map((lock) {
                final isSelected = currentLock == lock;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('${lock.toInt()}°'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          p.updateConfig(p.config.copyWith(steeringLock: lock));
                        }
                      },
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      selectedColor: const Color(0xFFFFFFFF),
                      backgroundColor: const Color(0xFF121212),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFFFFFFFF) : const Color(0xFF222222),
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Sensitivity slider
            _buildSliderRow(
              title: 'SENSITIVITY',
              value: sensitivity,
              min: 0.5,
              max: 2.5,
              divisions: 20,
              displayValue: '${sensitivity.toStringAsFixed(2)}x',
              onChanged: (v) {
                p.updateConfig(p.config.copyWith(sensitivity: v));
              },
            ),
            const SizedBox(height: 24),

            // Deadzone slider
            _buildSliderRow(
              title: 'DEADZONE THRESHOLD',
              value: deadzone,
              min: 0.0,
              max: 5.0,
              divisions: 50,
              displayValue: '${deadzone.toStringAsFixed(2)}°/s',
              onChanged: (v) {
                p.updateConfig(p.config.copyWith(deadzone: v));
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF888888),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSliderRow({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(title),
            Text(
              displayValue,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFFFFFFFF),
            inactiveTrackColor: const Color(0xFF1E1E1E),
            thumbColor: const Color(0xFFFFFFFF),
            overlayColor: const Color(0xFFFFFFFF).withValues(alpha: 0.1),
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ---- Step 4: Drift Calibration & Reference ----
class _StepDrift extends StatelessWidget {
  const _StepDrift();

  @override
  Widget build(BuildContext context) {
    return Consumer<SteeringProvider>(
      builder: (context, p, _) {
        final bool useDrift = p.config.useDriftCompensation;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '04 / DRIFT COMPENSATION',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enable optional drift correction. This blends the high-rate gyroscope with the phone\'s magnetometer reference to correct slow yaw drift.',
              style: TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E1E1E)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'COMPASS REFERENCE FUSION',
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                subtitle: const Text(
                  'Fuses magnetometer heading to damp long-term drift.',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 11),
                ),
                value: useDrift,
                activeThumbColor: const Color(0xFFFFFFFF),
                activeTrackColor: const Color(0xFF333333),
                inactiveThumbColor: const Color(0xFF888888),
                inactiveTrackColor: const Color(0xFF111111),
                onChanged: (val) {
                  p.updateConfig(p.config.copyWith(useDriftCompensation: val));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---- Step 5: Validation Run ----
class _StepValidation extends StatelessWidget {
  const _StepValidation();

  @override
  Widget build(BuildContext context) {
    return Consumer<SteeringProvider>(
      builder: (context, p, _) {
        final currentAngle = p.latestMeasurement?.angleDeg ?? 0.0;
        final bool isRTC = p.isRTCValidationActive;
        final bool? rtcPassed = p.rtcPassedRaw;
        final double deviation = p.maxRTCDeviation;

        final bool isAccuracy = p.isAccuracyValidationActive;
        final bool? accuracyPassed = p.accuracyPassed;
        final double accuracyError = p.accuracyError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '05 / ACCURACY VALIDATION',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Perform accuracy checks on your current configuration to verify latency and drift boundaries.',
              style: TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Live Angle Readout
            Center(
              child: Column(
                children: [
                  const Text(
                    'LIVE STEERING ANGLE',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '${currentAngle.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 36,
                      fontWeight: FontWeight.w200,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Test 1: Return-to-Center
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E1E1E)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RETURN-TO-CENTER TEST',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      _buildStatusIndicator(rtcPassed),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rotate the wheel past 90°, then align it back to center.',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  if (isRTC)
                    ElevatedButton(
                      onPressed: () => p.endRTCValidation(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFFFF),
                        foregroundColor: const Color(0xFF000000),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('SUBMIT CENTER ALIGNMENT'),
                    )
                  else
                    OutlinedButton(
                      onPressed: () => p.startRTCValidation(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFFFFF),
                        side: const BorderSide(color: Color(0xFF333333)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text(rtcPassed == null ? 'START TEST' : 'RETEST'),
                    ),
                  if (rtcPassed != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Rest Deviation: ${deviation.toStringAsFixed(2)}° (Target: < 2.5°)',
                        style: TextStyle(
                          color: rtcPassed ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Test 2: Angle Accuracy
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E1E1E)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ANGLE ACCURACY TEST',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      _buildStatusIndicator(accuracyPassed),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Position the wheel at exactly 90° (turn right).',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  if (isAccuracy)
                    ElevatedButton(
                      onPressed: () => p.checkAccuracyValidation(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFFFF),
                        foregroundColor: const Color(0xFF000000),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('SUBMIT ACCURACY CHECK'),
                    )
                  else
                    OutlinedButton(
                      onPressed: () => p.startAccuracyValidation(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFFFFF),
                        side: const BorderSide(color: Color(0xFF333333)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text(accuracyPassed == null ? 'START TEST' : 'RETEST'),
                    ),
                  if (accuracyPassed != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Sensor reference deviation: ${accuracyError.toStringAsFixed(2)}° (Target: < 4.0°)',
                        style: TextStyle(
                          color: accuracyPassed ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusIndicator(bool? passed) {
    if (passed == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'PENDING',
          style: TextStyle(color: Color(0xFF888888), fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: passed ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        passed ? 'PASSED' : 'FAILED',
        style: TextStyle(
          color: passed ? Colors.green : Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
