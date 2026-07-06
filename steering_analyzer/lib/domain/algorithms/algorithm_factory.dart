// algorithm_factory.dart
//
// Single switchboard for building a `SteeringAlgorithm` by id.  UI
// code asks the factory for an instance; the factory hides the
// concrete type.  This keeps the UI free of `if` ladders when
// switching algorithms and makes it trivial to add a new algorithm
// in the future.

import 'custom_filtered_algorithm.dart';
import 'gyro_integration_algorithm.dart';
import 'orientation_algorithm.dart';
import 'rotation_vector_algorithm.dart';
import 'sensor_fusion_algorithm.dart';
import 'steering_algorithm.dart';
import 'steering_measurement.dart';

class AlgorithmFactory {
  static SteeringAlgorithm create(AlgorithmId id) {
    switch (id) {
      case AlgorithmId.gyroIntegration: return GyroIntegrationAlgorithm();
      case AlgorithmId.rotationVector:  return RotationVectorAlgorithm();
      case AlgorithmId.orientation:      return OrientationAlgorithm();
      case AlgorithmId.sensorFusion:     return SensorFusionAlgorithm();
      case AlgorithmId.customFiltered:   return CustomFilteredAlgorithm();
    }
  }

  static List<AlgorithmId> get all => AlgorithmId.values;
}
