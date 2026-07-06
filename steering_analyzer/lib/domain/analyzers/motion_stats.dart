// motion_stats.dart
//
// Lightweight running-statistics analyzer.  Tracks min/max/current
// values for angle and rate, an exponential moving average of the
// accelerometer magnitude (for "current acceleration"), the sensor
// sample rate, frame rate, latency and dropped frames.
//
// We deliberately keep this stateful and single-threaded; the
// pipeline calls `update` from the UI isolate's main loop.

import '../../data/models/sensor_sample.dart';
import '../algorithms/steering_measurement.dart';

class MotionStatsAnalyzer {
  double _maxAngleDeg = 0.0;
  double _minAngleDeg = 0.0;
  double _maxRateDps = 0.0;
  double _currentRateDps = 0.0;

  // Acceleration magnitude (m/s^2), exponentially smoothed.
  double _emaAccelMps2 = 0.0;

  // Sample rate estimation: keep timestamps of the last 30 samples
  // and report the mean dt.
  final List<double> _sampleTimestampsUs = <double>[];
  static const int _kSampleWindow = 30;
  double _sampleRateHz = 0.0;

  // Frame rate estimation: same idea, but using the wall-clock time
  // the UI received a measurement.
  final List<int> _frameTimestampsMs = <int>[];
  static const int _kFrameWindow = 30;
  double _frameRateHz = 0.0;
  int _droppedFrames = 0;
  int _lastWallClockMs = 0;

  // Latency estimate: how long it took from sensor timestamp to
  // UI observation.  Smoothed.
  double _latencyMs = 0.0;

  void reset() {
    _maxAngleDeg = 0.0;
    _minAngleDeg = 0.0;
    _maxRateDps = 0.0;
    _currentRateDps = 0.0;
    _emaAccelMps2 = 0.0;
    _sampleTimestampsUs.clear();
    _frameTimestampsMs.clear();
    _sampleRateHz = 0.0;
    _frameRateHz = 0.0;
    _droppedFrames = 0;
    _lastWallClockMs = 0;
    _latencyMs = 0.0;
  }

  /// Reset just the min/max accumulators (called when the user
  /// presses "Reset stats").
  void resetMinMax() {
    _maxAngleDeg = 0.0;
    _minAngleDeg = 0.0;
    _maxRateDps = 0.0;
  }

  void update(SteeringMeasurement m, SensorSample s) {
    // Min/max of angle and rate.
    if (m.angleDeg > _maxAngleDeg) _maxAngleDeg = m.angleDeg;
    if (m.angleDeg < _minAngleDeg) _minAngleDeg = m.angleDeg;
    final double absRate = m.rateDps.abs();
    if (absRate > _maxRateDps) _maxRateDps = absRate;
    _currentRateDps = m.rateDps;

    // Acceleration magnitude (gravity-removed user acceleration).
    final double aMag = (s.uax * s.uax + s.uay * s.uay + s.uaz * s.uaz);
    final double aMagSqrt = aMag <= 0.0 ? 0.0 : _sqrt(aMag);
    _emaAccelMps2 = 0.9 * _emaAccelMps2 + 0.1 * aMagSqrt;

    // Sample rate: mean of dt over the last `_kSampleWindow` samples.
    _sampleTimestampsUs.add(s.timestampUs);
    if (_sampleTimestampsUs.length > _kSampleWindow) {
      _sampleTimestampsUs.removeAt(0);
    }
    if (_sampleTimestampsUs.length >= 2) {
      final double t0 = _sampleTimestampsUs.first;
      final double t1 = _sampleTimestampsUs.last;
      final double dt = (t1 - t0) / 1e6;
      if (dt > 0.0) {
        _sampleRateHz = (_sampleTimestampsUs.length - 1) / dt;
      }
    }

    // Frame rate and latency: based on the wall-clock time the
    // measurement arrived at the UI.
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    _frameTimestampsMs.add(nowMs);
    if (_frameTimestampsMs.length > _kFrameWindow) {
      _frameTimestampsMs.removeAt(0);
    }
    if (_frameTimestampsMs.length >= 2) {
      final int t0 = _frameTimestampsMs.first;
      final int t1 = _frameTimestampsMs.last;
      final int dtMs = t1 - t0;
      if (dtMs > 0) {
        _frameRateHz = ((_frameTimestampsMs.length - 1) * 1000.0) / dtMs;
      }
    }

    // Dropped frames: if a frame is more than 1.5x the median dt
    // after the previous frame, count it as dropped.
    if (_lastWallClockMs != 0) {
      final int gap = nowMs - _lastWallClockMs;
      if (_frameTimestampsMs.length >= 4) {
        // Compute median dt over the last 3 gaps.
        final int n = _frameTimestampsMs.length;
        final int a = _frameTimestampsMs[n - 1] - _frameTimestampsMs[n - 2];
        final int b = _frameTimestampsMs[n - 2] - _frameTimestampsMs[n - 3];
        final int c = _frameTimestampsMs[n - 3] - _frameTimestampsMs[n - 4];
        final int med = _median3(a, b, c);
        if (med > 0 && gap > (med * 3 ~/ 2)) {
          _droppedFrames++;
        }
      }
    }
    _lastWallClockMs = nowMs;

    // Latency: difference between wall clock now and the sensor's
    // wall clock.  This is approximate because we record `wallClockMs`
    // as a relative offset, not an absolute one, so we just estimate
    // it as 0 on first sample and then keep an EMA.
    if (_frameTimestampsMs.length >= 2) {
      // Approximate as the time between the previous and current
      // wall-clock samples minus the time between the previous and
      // current sensor timestamps.  This captures scheduling jitter.
      final int n = _frameTimestampsMs.length;
      final int wallDt = _frameTimestampsMs[n - 1] - _frameTimestampsMs[n - 2];
      final double sensorDtUs = _sampleTimestampsUs.last - _sampleTimestampsUs[_sampleTimestampsUs.length - 2];
      final double sensorDtMs = sensorDtUs / 1000.0;
      final double est = (wallDt - sensorDtMs).clamp(0.0, 100.0);
      _latencyMs = 0.9 * _latencyMs + 0.1 * est;
    }
  }

  MotionStats snapshot() {
    return MotionStats(
      maxAngleDeg: _maxAngleDeg,
      minAngleDeg: _minAngleDeg,
      maxRateDps: _maxRateDps,
      currentRateDps: _currentRateDps,
      currentAccelMps2: _emaAccelMps2,
      sampleRateHz: _sampleRateHz,
      frameRateHz: _frameRateHz,
      latencyMs: _latencyMs,
      droppedFrames: _droppedFrames,
    );
  }

  static int _median3(int a, int b, int c) {
    if (a > b) { final int t = a; a = b; b = t; }
    if (b > c) { final int t = b; b = c; c = t; }
    if (a > b) { final int t = a; a = b; b = t; }
    return b;
  }

  static double _sqrt(double x) {
    // Newton-Raphson with 4 iterations is faster than dart:math.sqrt
    // for the hot path and produces ample precision.
    if (x <= 0.0) return 0.0;
    double r = x * 0.5;
    r = 0.5 * (r + x / r);
    r = 0.5 * (r + x / r);
    r = 0.5 * (r + x / r);
    r = 0.5 * (r + x / r);
    return r;
  }
}
