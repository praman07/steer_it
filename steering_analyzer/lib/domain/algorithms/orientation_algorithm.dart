// orientation_algorithm.dart
//
// Algorithm #3: read the device's absolute orientation sensor
// (`azimuth`, `pitch`, `roll`) and use the azimuth as the steering
// angle.  This is the same approach as the rotation vector algorithm
// but consumes the higher-level orientation API, which is more
// widely available and easier to reason about.
//
// Note: the orientation sensor is deprecated in Android 4+.  We use
// it as a baseline; in practice the rotation vector is preferred.

import '../../core/math/math_utils.dart';
import '../../data/models/sensor_sample.dart';
import 'steering_algorithm.dart';
import 'steering_measurement.dart';

class OrientationAlgorithm implements SteeringAlgorithm {
  @override
  AlgorithmId get id => AlgorithmId.orientation;
  @override
  String get name => 'Orientation Sensor';

  double _prevAzimuth = 0.0;
  double _angleDeg = 0.0;
  double _accumulatedDeg = 0.0;
  bool _seeded = false;
  double _lastTimestampUs = 0.0;
  double _lastRateDps = 0.0;

  double _driftDeg = 0.0;
  double _biasDps = 0.0;
  double _correctionDeg = 0.0;

  @override
  void reset() {
    _prevAzimuth = 0.0;
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
    final double? az = s.azimuthDeg;
    if (az == null) {
      return SteeringMeasurement(
        wallClockMs: s.wallClockMs,
        timestampUs: s.timestampUs,
        algorithm: id,
        angleDeg: _angleDeg,
        rateDps: 0.0,
        accumulatedDeg: _accumulatedDeg,
        turns: _accumulatedDeg / 360.0,
        biasDps: 0.0,
        driftDeg: 0.0,
        correctionDeg: 0.0,
        confidence: 0.0,
      );
    }

    if (!_seeded) {
      _prevAzimuth = az;
      _lastTimestampUs = s.timestampUs;
      _seeded = true;
    } else {
      double delta = az - _prevAzimuth;
      if (delta > 180.0) delta -= 360.0;
      if (delta < -180.0) delta += 360.0;
      _accumulatedDeg += delta;
      _angleDeg = wrapAngle180(_accumulatedDeg);

      final double dt = (s.timestampUs - _lastTimestampUs) / 1e6;
      if (dt > 0.0) _lastRateDps = delta / dt;
      _lastTimestampUs = s.timestampUs;
      _prevAzimuth = az;
    }

    _driftDeg = 0.99 * _driftDeg + 0.01 * (_lastRateDps.abs() * 0.4);

    return SteeringMeasurement(
      wallClockMs: s.wallClockMs,
      timestampUs: s.timestampUs,
      algorithm: id,
      angleDeg: _angleDeg,
      rateDps: _lastRateDps,
      accumulatedDeg: _accumulatedDeg,
      turns: _accumulatedDeg / 360.0,
      biasDps: _biasDps,
      driftDeg: _driftDeg,
      correctionDeg: _correctionDeg,
      confidence: _confidenceFor(s),
    );
  }

  double _confidenceFor(SensorSample s) {
    if (s.azimuthDeg == null) return 0.0;
    return 0.75;
  }
}
