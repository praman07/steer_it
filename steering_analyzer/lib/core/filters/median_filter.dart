// median_filter.dart
//
// 1-D median filter over a sliding window.  Used to reject single-sample
// spikes (e.g. someone bumping the phone) which would otherwise feed
// large erroneous angular deltas into the integration step.
//
// We use insertion sort because the window is small (typically 3-7
// samples) and the constants are tiny; for larger windows a counting
// sort or quickselect would be better.

import '../math/math_utils.dart';

class MedianFilter {
  final int window;
  final RingBuffer<double> _buf;
  // Pre-allocated scratch list to avoid per-frame allocation.
  final List<double> _scratch;

  MedianFilter({this.window = 5})
      : assert(window >= 1 && window % 2 == 1,
            'Median filter window must be a positive odd number'),
        _buf = RingBuffer<double>(window),
        _scratch = List<double>.filled(window, 0.0, growable: false);

  /// Add a new sample and return the median of the last `window` samples.
  double process(double x) {
    _buf.add(x);
    final int n = _buf.length;
    for (int i = 0; i < n; i++) {
      _scratch[i] = _buf[i]!;
    }
    // Insertion sort over the first `n` entries.
    for (int i = 1; i < n; i++) {
      final double key = _scratch[i];
      int j = i - 1;
      while (j >= 0 && _scratch[j] > key) {
        _scratch[j + 1] = _scratch[j];
        j--;
      }
      _scratch[j + 1] = key;
    }
    return _scratch[n ~/ 2];
  }

  void reset() => _buf.clear();
}
