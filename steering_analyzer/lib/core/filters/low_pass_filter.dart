class LowPassFilter {
  double alpha;
  double _y = 0.0;
  bool _seeded = false;

  LowPassFilter({this.alpha = 0.2});

  double process(double x) {
    if (!_seeded) {
      _y = x;
      _seeded = true;
      return _y;
    }
    _y = alpha * x + (1.0 - alpha) * _y;
    return _y;
  }

  void setAlpha(double a) => alpha = a;

  void reset() {
    _y = 0.0;
    _seeded = false;
  }

  void processTriple(double x, double y, double z, List<double> out) {
    out[0] = process(x);
    out[1] = process(y);
    out[2] = process(z);
  }
}

class HighPassFilter {
  final LowPassFilter _lpf;
  bool _seeded = false;

  HighPassFilter({double alpha = 0.1}) : _lpf = LowPassFilter(alpha: alpha);

  double process(double x) {
    final double lp = _lpf.process(x);
    if (!_seeded) {
      _seeded = true;
      return 0.0;
    }
    return x - lp;
  }

  void setAlpha(double a) => _lpf.setAlpha(a);

  void reset() {
    _lpf.reset();
    _seeded = false;
  }
}
