// steering_measurement.dart
//
// The output of one steering algorithm step: the current angle in
// degrees, the rate, the timestamp, and bookkeeping state for the
// rotation counter and drift analysis.
//
// This is the canonical type the UI consumes.  Algorithms never
// produce UI types - they produce these.

import 'package:flutter/foundation.dart';

enum AlgorithmId {
  gyroIntegration,
  rotationVector,
  orientation,
  sensorFusion,
  customFiltered,
}

extension AlgorithmIdLabel on AlgorithmId {
  String get label {
    switch (this) {
      case AlgorithmId.gyroIntegration: return 'Gyroscope Integration';
      case AlgorithmId.rotationVector:  return 'Rotation Vector';
      case AlgorithmId.orientation:      return 'Orientation Sensor';
      case AlgorithmId.sensorFusion:     return 'Sensor Fusion';
      case AlgorithmId.customFiltered:   return 'Custom Filtered';
    }
  }
}

@immutable
class SteeringMeasurement {
  /// Wall-clock timestamp when the algorithm emitted this measurement.
  final int wallClockMs;

  /// Monotonic timestamp in microseconds, suitable for dt math.
  final double timestampUs;

  /// Algorithm id that produced this measurement.
  final AlgorithmId algorithm;

  /// Steering angle in degrees, wrapped into [-180, 180].  This is the
  /// "current" reading shown on the wheel and the big numeric readout.
  final double angleDeg;

  /// Steering rate in degrees/second.  Positive = rotating clockwise as
  /// viewed from behind the wheel (i.e. right turn).
  final double rateDps;

  /// Total accumulated rotation in degrees, never wrapped, never reset
  /// (except by the explicit "Reset accumulated turns" button).  Used
  /// to compute the turn count.
  final double accumulatedDeg;

  /// Number of full 360-degree turns in `accumulatedDeg` (signed).
  final double turns;

  /// Estimated gyro bias in degrees/second (post-filter).
  final double biasDps;

  /// Estimated drift in degrees (algorithm's own idea, e.g. how far
  /// the integrated angle has wandered from a reference).
  final double driftDeg;

  /// Magnitude of the most-recent correction applied by the algorithm
  /// in degrees.  0 if no correction was applied this step.
  final double correctionDeg;

  /// Sensor confidence score in [0, 1].  Computed by the analyzer
  /// from sensor availability + noise.
  final double confidence;

  const SteeringMeasurement({
    required this.wallClockMs,
    required this.timestampUs,
    required this.algorithm,
    required this.angleDeg,
    required this.rateDps,
    required this.accumulatedDeg,
    required this.turns,
    required this.biasDps,
    required this.driftDeg,
    required this.correctionDeg,
    required this.confidence,
  });
}

/// Snapshot of running statistics.  Updated at ~10 Hz by the analyzer.
@immutable
class MotionStats {
  final double maxAngleDeg;
  final double minAngleDeg;
  final double maxRateDps;
  final double currentRateDps;
  final double currentAccelMps2;
  final double sampleRateHz;
  final double frameRateHz;
  final double latencyMs;
  final int droppedFrames;

  const MotionStats({
    required this.maxAngleDeg,
    required this.minAngleDeg,
    required this.maxRateDps,
    required this.currentRateDps,
    required this.currentAccelMps2,
    required this.sampleRateHz,
    required this.frameRateHz,
    required this.latencyMs,
    required this.droppedFrames,
  });
}
