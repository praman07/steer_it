// gyro_integration_algorithm.dart
//
// The simplest possible algorithm: integrate the gyroscope's z-axis
// reading over time.  The gyroscope measures angular velocity in rad/s;
// multiplying by dt and adding to the running estimate gives the
// change in angle.  The result drifts because the gyroscope has a
// non-zero bias that gets summed on every step.  This is the
// "naive" baseline; we use it to visualise the drift problem.

import '../../core/math/math_utils.dart';
import '../../data/models/sensor_sample.dart';
import 'steering_algorithm.dart';
import 'steering_measurement.dart';

class GyroIntegrationAlgorithm implements SteeringAlgorithm {
  @override
  AlgorithmId get id => AlgorithmId.gyroIntegration;
  @override
  String get name => 'Gyroscope Integration';

  // Configuration settings (all optional improvements)
  double centerOffset = 0.0;
  double staticBiasDps = 0.0;
  double steeringLock = 900.0;
  double deadzoneDps = 0.0;
  double sensitivity = 1.0;
  bool useSmoothing = false;
  double smoothingAlpha = 0.3;

  // Running state.
  double _angleDeg = 0.0;       // wrapped angle in degrees
  double _accumulatedDeg = 0.0; // unwrapped
  double _lastTimestampUs = 0.0;
  bool _seeded = false;

  // Drift tracking: how much the integrated angle has wandered from
  // a (very rough) reference signal.  We use the magnetometer-derived
  // heading as a low-pass reference.
  double _driftDeg = 0.0;
  double _biasDps = 0.0;
  double _correctionDeg = 0.0;
  double _referenceHeading = 0.0;
  bool _refSeeded = false;

  /// Used to convert rad/s to deg/s.  1 rad/s = 57.29577... deg/s.
  static const double _radToDeg = 57.29577951308232;

  @override
  void reset() {
    _angleDeg = 0.0;
    _accumulatedDeg = 0.0;
    _lastTimestampUs = 0.0;
    _seeded = false;
    _driftDeg = 0.0;
    _biasDps = 0.0;
    _correctionDeg = 0.0;
    _referenceHeading = 0.0;
    _refSeeded = false;
  }

  @override
  SteeringMeasurement process(SensorSample s) {
    final double dt = _seeded
        ? (s.timestampUs - _lastTimestampUs) / 1e6
        : 0.0;
    _lastTimestampUs = s.timestampUs;
    _seeded = true;

    // Clamp dt to avoid blow-ups when the app has been backgrounded
    // and the gyroscope fires a giant first-sample delta.
    final double dtClamped = dt < 0.0 ? 0.0 : (dt > 0.1 ? 0.1 : dt);

    // Z-axis rotation in rad/s -> deg/s.
    double rateDps = s.gz * _radToDeg;

    // 1. Subtract manual bias calibration offset
    rateDps -= staticBiasDps;

    // 2. Apply deadzone filtering
    if (rateDps.abs() < deadzoneDps) {
      rateDps = 0.0;
    }

    // 3. Apply sensitivity scaling
    rateDps *= sensitivity;

    // Integrate.
    final double delta = rateDps * dtClamped;
    double newAccumulated = _accumulatedDeg + delta;

    // 4. Apply steering lock limit: maximum range of rotation
    final double maxExcursion = steeringLock / 2.0;
    if (newAccumulated > maxExcursion) {
      newAccumulated = maxExcursion;
    } else if (newAccumulated < -maxExcursion) {
      newAccumulated = -maxExcursion;
    }
    _accumulatedDeg = newAccumulated;

    // 5. Subtract center offset calibration
    final double targetAngle = wrapAngle180(_accumulatedDeg - centerOffset);

    // 6. Apply optional output low-pass filter smoothing
    if (useSmoothing) {
      _angleDeg = smoothingAlpha * targetAngle + (1.0 - smoothingAlpha) * _angleDeg;
    } else {
      _angleDeg = targetAngle;
    }

    // Estimate gyro bias from still samples: when the magnitude of
    // the gyro is below ~0.6 deg/s, we average the reading into a
    // slow-moving bias estimate.  This is intentionally crude - the
    // Kalman algorithm does it properly.
    final double mag = s.gz.abs() * _radToDeg;
    if (mag < 0.6) {
      _biasDps = 0.99 * _biasDps + 0.01 * rateDps;
    }

    // Track drift against the heading reference (if any).
    if (s.headingDeg != null) {
      if (!_refSeeded) {
        _referenceHeading = s.headingDeg!;
        _refSeeded = true;
      } else {
        // The magnetometer is subject to wild jumps when nearby
        // metal is moved, so we only let it nudge the drift
        // estimate when the change is small.
        final double dHeading = wrapAngle180(s.headingDeg! - _referenceHeading);
        if (dHeading.abs() < 5.0) {
          _driftDeg = 0.99 * _driftDeg + 0.01 * (_accumulatedDeg - dHeading);
          _referenceHeading = s.headingDeg!;
        }
      }
    }

    final double turns = _accumulatedDeg / 360.0;
    return SteeringMeasurement(
      wallClockMs: s.wallClockMs,
      timestampUs: s.timestampUs,
      algorithm: id,
      angleDeg: _angleDeg,
      rateDps: rateDps,
      accumulatedDeg: _accumulatedDeg,
      turns: turns,
      biasDps: _biasDps,
      driftDeg: _driftDeg,
      correctionDeg: _correctionDeg,
      confidence: _confidenceFor(s),
    );
  }

  double _confidenceFor(SensorSample s) {
    if (s.gx == 0 && s.gy == 0 && s.gz == 0) return 0.0;
    if (s.headingDeg != null) return 0.7;
    return 0.5;
  }
}
