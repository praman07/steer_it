// steering_algorithm.dart
//
// Abstract base class for the five algorithms we expose in the UI.
// All algorithms are stateful (they need a previous timestamp and a
// running estimate) but never allocate inside `process`.

import '../../data/models/sensor_sample.dart';
import 'steering_measurement.dart';

abstract class SteeringAlgorithm {
  AlgorithmId get id;
  String get name;

  /// Reset all internal state.  Called when the user hits "Calibrate
  /// center" or "Zero gyroscope bias".
  void reset();

  /// Apply one sample, return a measurement.
  SteeringMeasurement process(SensorSample s);
}
