class ComplementaryFilter {
  double alpha;
  double _theta = 0.0;
  bool _seeded = false;

  ComplementaryFilter({this.alpha = 0.98});

  double process(double gyroRate, double reference, double dt) {
    if (!_seeded) {
      _theta = reference;
      _seeded = true;
      return _theta;
    }
    final double integrated = _theta + gyroRate * dt;
    _theta = alpha * integrated + (1.0 - alpha) * reference;
    return _theta;
  }

  void setAlpha(double a) => alpha = a;

  void reset() {
    _theta = 0.0;
    _seeded = false;
  }
}
