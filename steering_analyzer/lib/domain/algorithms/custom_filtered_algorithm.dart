// custom_filtered_algorithm.dart
//
// Algorithm #5: a chain of user-selectable filters applied to the
// integrated gyroscope angle.  This algorithm is useful for A/B
// testing - the user can tweak the filter parameters from the
// settings page and immediately see the effect on the wheel.
//
// The filter chain (in order) is:
//   1. Median filter on the raw rate (spike rejection).
//   2. Low-pass filter on the rate.
//   3. Complementary filter that blends the integrated angle with
//      the absolute rotation vector / orientation reference.

import '../../core/filters/complementary_filter.dart';
import '../../core/filters/low_pass_filter.dart';
import '../../core/filters/median_filter.dart';
import '../../core/math/math_utils.dart';
import '../../core/math/quaternion_utils.dart';
import '../../data/models/sensor_sample.dart';
import 'steering_algorithm.dart';
import 'steering_measurement.dart';

class CustomFilteredAlgorithm implements SteeringAlgorithm {
  @override
  AlgorithmId get id => AlgorithmId.customFiltered;
  @override
  String get name => 'Custom Filtered';

  static const double _radToDeg = 57.29577951308232;

  final MedianFilter _median = MedianFilter(window: 5);
  final LowPassFilter _lpf = LowPassFilter(alpha: 0.3);
  final ComplementaryFilter _cf = ComplementaryFilter(alpha: 0.98);

  double _accumulatedDeg = 0.0;
  double _angleDeg = 0.0;
  double _lastTimestampUs = 0.0;
  bool _seeded = false;
  double _driftDeg = 0.0;
  double _biasDps = 0.0;
  double _correctionDeg = 0.0;
  double _lastReferenceDeg = 0.0;
  bool _refSeeded = false;

  double _sensitivity = 1.0;
  double _lpfAlpha = 0.3;
  double _cfAlpha = 0.98;

  @override
  void reset() {
    _median.reset();
    _lpf.reset();
    _cf.reset();
    _accumulatedDeg = 0.0;
    _angleDeg = 0.0;
    _lastTimestampUs = 0.0;
    _seeded = false;
    _driftDeg = 0.0;
    _biasDps = 0.0;
    _correctionDeg = 0.0;
    _lastReferenceDeg = 0.0;
    _refSeeded = false;
  }

  void setAlpha(double lpfAlpha, double cfAlpha) {
    _lpfAlpha = lpfAlpha;
    _cfAlpha = cfAlpha;
    _lpf.setAlpha(lpfAlpha);
    _cf.setAlpha(cfAlpha);
  }

  double get lpfAlpha => _lpfAlpha;
  double get cfAlpha => _cfAlpha;
  double get sensitivity => _sensitivity;
  void setSensitivity(double s) => _sensitivity = s;

  @override
  SteeringMeasurement process(SensorSample s) {
    final double dt = _seeded
        ? (s.timestampUs - _lastTimestampUs) / 1e6
        : 0.0;
    _lastTimestampUs = s.timestampUs;
    _seeded = true;
    final double dtClamped = dt < 0.0 ? 0.0 : (dt > 0.1 ? 0.1 : dt);

    // 1. Median filter on the raw rate (rad/s).
    final double rateFiltered = _median.process(s.gz);
    // 2. Low-pass filter on the rate.
    final double rateSmoothed = _lpf.process(rateFiltered);
    final double rateDps = rateSmoothed * _radToDeg;

    // 3. Complementary filter that blends the integrated angle with
    //    the absolute reference.
    double? refDeg;
    if (s.rotation != null) {
      final List<double> e = quatToEulerDeg(s.rotation!);
      refDeg = e[2];
    } else if (s.azimuthDeg != null) {
      refDeg = s.azimuthDeg;
    }

    final double integratedBefore = _accumulatedDeg;
    _accumulatedDeg += rateDps * dtClamped * _sensitivity;
    _angleDeg = wrapAngle180(_accumulatedDeg);

    if (refDeg != null) {
      // The complementary filter operates on the absolute reference.
      // First we express the reference as a "rate delta" that would
      // have taken us from our previous reference to the new one.
      // Then we feed that as a low-rate correction.
      if (!_refSeeded) {
        _lastReferenceDeg = refDeg;
        _refSeeded = true;
      } else {
        double dRef = refDeg - _lastReferenceDeg;
        if (dRef > 180.0) dRef -= 360.0;
        if (dRef < -180.0) dRef += 360.0;
        _lastReferenceDeg = refDeg;
        _correctionDeg = 0.02 * dRef; // low-rate correction
        _accumulatedDeg += _correctionDeg;
        _angleDeg = wrapAngle180(_accumulatedDeg);
      }
    }

    // Bias estimate: when rate is small we add to a slow-moving average.
    if (rateDps.abs() < 0.6) {
      _biasDps = 0.99 * _biasDps + 0.01 * rateDps;
    }
    // Drift estimate.
    _driftDeg = 0.99 * _driftDeg + 0.01 * (_accumulatedDeg - integratedBefore);

    return SteeringMeasurement(
      wallClockMs: s.wallClockMs,
      timestampUs: s.timestampUs,
      algorithm: id,
      angleDeg: _angleDeg,
      rateDps: rateDps,
      accumulatedDeg: _accumulatedDeg,
      turns: _accumulatedDeg / 360.0,
      biasDps: _biasDps,
      driftDeg: _driftDeg,
      correctionDeg: _correctionDeg,
      confidence: _confidenceFor(s),
    );
  }

  double _confidenceFor(SensorSample s) {
    if (s.rotation == null && s.azimuthDeg == null) return 0.5;
    return 0.85;
  }
}
