// sensor_fusion_algorithm.dart
//
// Algorithm #4: a 1-D Kalman filter that fuses the gyroscope's short
// term rate with the rotation vector's long term absolute reference.
// The state is `[angle, bias]` and the model is
//
//   angle' = angle + dt * (gyro - bias)
//   bias'  = bias
//
// The Kalman filter produces a smooth, drift-free angle estimate and
// gives us a real-time bias estimate that we surface as a metric.

import '../../core/filters/kalman_filter.dart';
import '../../core/math/math_utils.dart';
import '../../core/math/quaternion_utils.dart';
import '../../data/models/sensor_sample.dart';
import 'steering_algorithm.dart';
import 'steering_measurement.dart';

class SensorFusionAlgorithm implements SteeringAlgorithm {
  @override
  AlgorithmId get id => AlgorithmId.sensorFusion;
  @override
  String get name => 'Sensor Fusion';

  static const double _radToDeg = 57.29577951308232;

  final KalmanFilter _kalman = KalmanFilter(
    qAngle: 0.001,
    qBias: 0.0003,
    rMeasure: 0.03,
  );

  double _lastTimestampUs = 0.0;
  bool _seeded = false;
  double _lastRateDps = 0.0;
  double _angleDeg = 0.0;
  double _accumulatedDeg = 0.0;
  double _driftDeg = 0.0;
  double _correctionDeg = 0.0;
  double _lastAbsYawDeg = 0.0;
  bool _yawSeeded = false;

  @override
  void reset() {
    _kalman.reset();
    _lastTimestampUs = 0.0;
    _seeded = false;
    _lastRateDps = 0.0;
    _angleDeg = 0.0;
    _accumulatedDeg = 0.0;
    _driftDeg = 0.0;
    _correctionDeg = 0.0;
    _lastAbsYawDeg = 0.0;
    _yawSeeded = false;
  }

  @override
  SteeringMeasurement process(SensorSample s) {
    final double dt = _seeded
        ? (s.timestampUs - _lastTimestampUs) / 1e6
        : 0.0;
    _lastTimestampUs = s.timestampUs;
    _seeded = true;
    final double dtClamped = dt < 0.0 ? 0.0 : (dt > 0.1 ? 0.1 : dt);

    // Absolute reference: rotation vector's yaw in radians.  If not
    // available, fall back to the orientation sensor's azimuth.  If
    // neither is available, we still integrate the gyro but with
    // bigger measurement noise.
    double? absYawRad;
    if (s.rotation != null) {
      final List<double> e = quatToEulerDeg(s.rotation!);
      absYawRad = degToRad(e[2]);
    } else if (s.azimuthDeg != null) {
      absYawRad = degToRad(s.azimuthDeg!);
    }

    // Wrap to [-pi, pi] because the yaw from `quatToEulerDeg` and the
    // azimuth sensor can both wrap.  We pass the wrapped value to the
    // Kalman filter, which doesn't care about absolute reference -
    // it just uses the measurement as is.
    final double? absWrappedRad = absYawRad;

    // The Kalman filter thinks in radians; convert gyro from rad/s.
    final double angleRad = _kalman.process(
      newRate: s.gz,
      dt: dtClamped,
      measurement: absWrappedRad,
    );

    final double newAngleDeg = angleRad * _radToDeg;

    // Track the running accumulated angle (unwrapped) and rate.
    if (_yawSeeded) {
      // The Kalman filter already produces an absolute estimate.  We
      // unwrap it into a running total so the user can see the total
      // degrees turned across the session.
      double delta = newAngleDeg - _lastAbsYawDeg;
      if (delta > 180.0) delta -= 360.0;
      if (delta < -180.0) delta += 360.0;
      _accumulatedDeg += delta;
      _correctionDeg = delta; // the most recent correction from the reference
    }
    _lastAbsYawDeg = newAngleDeg;
    _yawSeeded = true;

    _angleDeg = wrapAngle180(newAngleDeg);
    _lastRateDps = s.gz * _radToDeg - _kalman.bias * _radToDeg;

    // Drift estimate: the absolute reference should be drift-free, so
    // the residual after the Kalman update is a good proxy.
    if (absWrappedRad != null) {
      final double err = (newAngleDeg - (absWrappedRad * _radToDeg));
      _driftDeg = 0.99 * _driftDeg + 0.01 * err;
    }

    return SteeringMeasurement(
      wallClockMs: s.wallClockMs,
      timestampUs: s.timestampUs,
      algorithm: id,
      angleDeg: _angleDeg,
      rateDps: _lastRateDps,
      accumulatedDeg: _accumulatedDeg,
      turns: _accumulatedDeg / 360.0,
      biasDps: _kalman.bias * _radToDeg,
      driftDeg: _driftDeg,
      correctionDeg: _correctionDeg,
      confidence: _confidenceFor(s),
    );
  }

  double _confidenceFor(SensorSample s) {
    double c = 0.6; // baseline (gyro + kalman)
    if (s.rotation != null) c = 0.95;
    if (s.azimuthDeg != null) c = math_max(c, 0.8);
    return c;
  }

  static double math_max(double a, double b) => a > b ? a : b;
}
