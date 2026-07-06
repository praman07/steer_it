// math_utils.dart
//
// Small set of stateless math helpers used throughout the steering pipeline.
// Every operation is allocation-free in the inner loops. The steering loop
// runs at sensor sample rate (often >100 Hz) and any per-frame allocation
// will show up as dropped frames.
//
// All angle inputs/outputs are in degrees unless otherwise noted. The
// underlying math is performed in radians where trigonometry is needed
// because Dart's sin/cos/tan are radian-based.

import 'dart:math' as math;

/// Converts degrees to radians.
///
/// `rad = deg * pi / 180`
double degToRad(double deg) => deg * math.pi / 180.0;

/// Converts radians to degrees.
///
/// `deg = rad * 180 / pi`
double radToDeg(double rad) => rad * 180.0 / math.pi;

/// Wraps an angle in degrees into the range `[-180, 180]`.
///
/// Used to keep the displayed steering angle bounded so that, for example,
/// +540° and +180° represent the same wheel position.
double wrapAngle180(double deg) {
  // fmod then push into the [-180, 180] interval.
  double w = deg % 360.0;
  if (w > 180.0) w -= 360.0;
  if (w < -180.0) w += 360.0;
  return w;
}

/// Wraps an angle in degrees into the range `[0, 360)`.
double wrapAngle360(double deg) {
  double w = deg % 360.0;
  if (w < 0.0) w += 360.0;
  return w;
}

/// Linear interpolation between two values.
///
/// `out = a + (b - a) * t`, with `t` clamped to [0, 1].
double lerp(double a, double b, double t) {
  if (t < 0.0) return a;
  if (t > 1.0) return b;
  return a + (b - a) * t;
}

/// Linear interpolation used for quaternion blending (slerp with the cosine
/// precomputed). Both `a` and `b` are unit quaternions in `[x, y, z, w]` order.
double clamp(double v, double lo, double hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

/// Returns true if the floating point value is finite (not NaN or infinity).
bool isFiniteNumber(double v) => v.isFinite;

/// Running mean / variance using Welford's algorithm. This is more numerically
/// stable than the naive `sum/n` and `sumSq/n - mean^2` form.
///
/// We use it to estimate sensor noise in real time. A small allocation-free
/// implementation is critical because we instantiate one per stream.
class RunningStats {
  int _n = 0;
  double _mean = 0.0;
  double _m2 = 0.0;

  int get count => _n;
  double get mean => _mean;
  /// Sample variance (divide by n, not n-1). Fine for live noise estimation.
  double get variance => _n == 0 ? 0.0 : _m2 / _n;
  double get stddev => math.sqrt(variance);
  double get min => _min;
  double get max => _max;
  double _min = double.infinity;
  double _max = double.negativeInfinity;

  /// Push a new sample.
  ///
  /// Welford update:
  ///   delta  = x - mean
  ///   mean'  = mean + delta / n
  ///   delta2 = x - mean'
  ///   m2'    = m2 + delta * delta2
  void push(double x) {
    _n += 1;
    final double delta = x - _mean;
    _mean += delta / _n;
    final double delta2 = x - _mean;
    _m2 += delta * delta2;
    if (x < _min) _min = x;
    if (x > _max) _max = x;
  }

  /// Reset all accumulators.
  void reset() {
    _n = 0;
    _mean = 0.0;
    _m2 = 0.0;
    _min = double.infinity;
    _max = double.negativeInfinity;
  }
}

/// Tiny ring buffer used by the median filter and the graph widgets. We
/// intentionally don't use `Queue` because we want predictable memory: the
/// backing array is allocated once at construction time and reused forever.
class RingBuffer<T> {
  final List<T?> _buf;
  int _head = 0;
  int _size = 0;
  final int capacity;

  RingBuffer(this.capacity) : _buf = List<T?>.filled(capacity, null, growable: false);

  int get length => _size;
  bool get isEmpty => _size == 0;
  bool get isFull => _size == capacity;

  /// Append a new value, overwriting the oldest one if the buffer is full.
  void add(T v) {
    _buf[_head] = v;
    _head = (_head + 1) % capacity;
    if (_size < capacity) _size++;
  }

  /// Most recently added value, or null if the buffer is empty.
  T? get last {
    if (_size == 0) return null;
    final int idx = (_head - 1 + capacity) % capacity;
    return _buf[idx];
  }

  /// Read value at logical index 0 (oldest) up to length-1 (newest).
  T? operator [](int i) {
    if (i < 0 || i >= _size) {
      throw RangeError.index(i, this);
    }
    final int start = isFull ? _head : 0;
    return _buf[(start + i) % capacity];
  }

  void clear() {
    for (int i = 0; i < capacity; i++) {
      _buf[i] = null;
    }
    _head = 0;
    _size = 0;
  }
}
