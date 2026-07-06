// kalman_filter.dart
//
// 1-D Kalman filter specialised for sensor rate integration.  We model a
// constant-velocity random walk: state is `[angle, bias]`, the rate
// measurement is `gyro - bias`, and the state evolves with the kinematic
// equation
//
//   angle' = angle + dt * (gyro - bias)
//   bias'  = bias
//
// The bias state lets us estimate and subtract the slow-moving zero-rate
// offset that is responsible for the "drift" we see when the gyro is
// left sitting on the table.  The filter is the textbook linear Kalman
// filter with two parameters to tune:
//
//   `qAngle`   - process noise on the angle  (larger = trust gyro less)
//   `qBias`    - process noise on the bias   (larger = bias changes faster)
//   `rMeasure` - measurement noise            (larger = trust the model more)

class KalmanFilter {
  final double qAngle;   // Process noise variance for the angle state.
  final double qBias;    // Process noise variance for the bias state.
  final double rMeasure; // Measurement noise variance.

  double _angle = 0.0;
  double _bias = 0.0;
  double _p00 = 1.0, _p01 = 0.0, _p10 = 0.0, _p11 = 1.0;
  bool _seeded = false;

  KalmanFilter({
    this.qAngle = 0.001,
    this.qBias = 0.003,
    this.rMeasure = 0.03,
  });

  /// Apply the prediction + update step.
  ///
  /// `newRate` is the gyroscope reading in rad/s.  `dt` is the time delta
  /// in seconds.  `measurement` is the absolute reference angle in
  /// radians (from rotation vector / orientation sensor).  If `dt <= 0`
  /// the call is a no-op.
  double process({
    required double newRate,
    required double dt,
    double? measurement,
  }) {
    if (dt <= 0.0) return _angle;

    if (!_seeded && measurement != null) {
      // Seed the angle state with the first absolute reference so we
      // don't have a startup transient.
      _angle = measurement;
      _seeded = true;
    }

    // ---- Predict ----
    //   x_pred = F * x    where F = [[1, -dt], [0, 1]]
    //   P_pred = F P F^T + Q
    final double rate = newRate - _bias;
    _angle += dt * rate;

    _p00 += dt * (dt * _p11 - _p01 - _p10) + qAngle;
    _p01 -= dt * _p11;
    _p10 -= dt * _p11;
    _p11 += qBias;

    // ---- Update (optional) ----
    if (measurement != null) {
      //   y = z - H * x_pred   with H = [1, 0]
      //   S = H P_pred H^T + R
      //   K = P_pred H^T S^-1
      final double y = measurement - _angle;
      final double s = _p00 + rMeasure;
      final double k0 = _p00 / s;
      final double k1 = _p10 / s;

      _angle += k0 * y;
      _bias += k1 * y;

      //   P = (I - K H) P_pred
      _p00 -= k0 * _p00;
      _p01 -= k0 * _p01;
      _p10 -= k1 * _p00;
      _p11 -= k1 * _p01;
    }

    return _angle;
  }

  double get angle => _angle;
  double get bias => _bias;
  void reset() {
    _angle = 0.0;
    _bias = 0.0;
    _p00 = 1.0; _p01 = 0.0; _p10 = 0.0; _p11 = 1.0;
    _seeded = false;
  }
}
