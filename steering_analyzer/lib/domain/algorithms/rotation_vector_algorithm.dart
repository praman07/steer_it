// rotation_vector_algorithm.dart
//
// Algorithm #2: derive the steering angle directly from the rotation
// vector sensor.  The rotation vector is a fused quaternion from the
// device's accelerometer + gyroscope (and magnetometer, if available)
// and is the most accurate absolute attitude source we have.
//
// We convert the quaternion to Euler angles (roll/pitch/yaw), take
// the yaw (z-axis) and treat that as the steering angle.  Because
// yaw is computed as `atan2(...)` it has a discontinuity at +/-180;
// we unwrap it by tracking the running accumulated value.

import '../../core/math/math_utils.dart';
import '../../core/math/quaternion_utils.dart';
import '../../data/models/sensor_sample.dart';
import 'steering_algorithm.dart';
import 'steering_measurement.dart';

class RotationVectorAlgorithm implements SteeringAlgorithm {
  @override
  AlgorithmId get id => AlgorithmId.rotationVector;
  @override
  String get name => 'Rotation Vector';

  double _prevYaw = 0.0;
  double _angleDeg = 0.0;
  double _accumulatedDeg = 0.0;
  bool _seeded = false;

  double _lastTimestampUs = 0.0;
  double _lastRateDps = 0.0;

  // For the unwrap step we need to know the smallest signed delta
  // from one yaw to the next.  When that delta exceeds 180 we must
  // add/subtract 360 to keep continuity.
  double _driftDeg = 0.0;
  double _biasDps = 0.0;
  double _correctionDeg = 0.0;

  @override
  void reset() {
    _prevYaw = 0.0;
    _angleDeg = 0.0;
    _accumulatedDeg = 0.0;
    _seeded = false;
    _lastTimestampUs = 0.0;
    _lastRateDps = 0.0;
    _driftDeg = 0.0;
    _biasDps = 0.0;
    _correctionDeg = 0.0;
  }

  @override
  SteeringMeasurement process(SensorSample s) {
    if (s.rotation == null) {
      // Without a rotation vector, this algorithm can't produce a
      // sensible measurement.  Return a zeroed one so the UI keeps
      // updating.
      return SteeringMeasurement(
        wallClockMs: s.wallClockMs,
        timestampUs: s.timestampUs,
        algorithm: id,
        angleDeg: 0.0,
        rateDps: 0.0,
        accumulatedDeg: 0.0,
        turns: 0.0,
        biasDps: 0.0,
        driftDeg: 0.0,
        correctionDeg: 0.0,
        confidence: 0.0,
      );
    }

    // Convert the quaternion to Euler angles (roll, pitch, yaw), all
    // in degrees.  We want yaw - the rotation about the device's z
    // axis - because that's the natural "steering" axis when the
    // phone is held in landscape with the screen facing the driver.
    final List<double> euler = quatToEulerDeg(s.rotation!);
    final double yaw = euler[2];

    if (!_seeded) {
      _prevYaw = yaw;
      _angleDeg = 0.0;
      _accumulatedDeg = 0.0;
      _lastTimestampUs = s.timestampUs;
      _seeded = true;
    } else {
      // Unwrap: take the smallest signed delta and apply it to the
      // accumulated angle.
      double delta = yaw - _prevYaw;
      if (delta > 180.0) delta -= 360.0;
      if (delta < -180.0) delta += 360.0;
      _accumulatedDeg += delta;
      _angleDeg = wrapAngle180(_accumulatedDeg);

      // Rate of change.
      final double dt = (s.timestampUs - _lastTimestampUs) / 1e6;
      if (dt > 0.0) {
        _lastRateDps = delta / dt;
      }
      _lastTimestampUs = s.timestampUs;
      _prevYaw = yaw;

      // Bias estimate: when the rate is small we assume the device
      // is at rest and the residual is the bias.
      if (_lastRateDps.abs() < 0.6) {
        _biasDps = 0.99 * _biasDps + 0.01 * _lastRateDps;
      }
    }

    // Drift estimate: the rotation vector drifts far less than the
    // gyroscope, but it still jitters.  We estimate drift as the
    // 1-second running mean of the absolute rate.
    _driftDeg = 0.99 * _driftDeg + 0.01 * (_lastRateDps.abs() * 0.5);

    final double turns = _accumulatedDeg / 360.0;
    return SteeringMeasurement(
      wallClockMs: s.wallClockMs,
      timestampUs: s.timestampUs,
      algorithm: id,
      angleDeg: _angleDeg,
      rateDps: _lastRateDps,
      accumulatedDeg: _accumulatedDeg,
      turns: turns,
      biasDps: _biasDps,
      driftDeg: _driftDeg,
      correctionDeg: _correctionDeg,
      confidence: _confidenceFor(s),
    );
  }

  double _confidenceFor(SensorSample s) {
    if (s.rotation == null) return 0.0;
    // The accuracy field is in [0, 1] with 1 being best.  We blend
    // that with the previous confidence to avoid jitter.
    final double base = 0.5 + 0.5 * s.rotationAccuracy;
    return base;
  }
}
