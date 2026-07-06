import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CalibrationConfig {
  final double centerOffset;
  final double gyroBias;
  final double steeringLock;
  final double deadzone;
  final double sensitivity;
  final bool useSmoothing;
  final double smoothingAlpha;
  final bool useDriftCompensation;

  const CalibrationConfig({
    this.centerOffset = 0.0,
    this.gyroBias = 0.0,
    this.steeringLock = 900.0,
    this.deadzone = 0.0,
    this.sensitivity = 1.0,
    this.useSmoothing = false,
    this.smoothingAlpha = 0.3,
    this.useDriftCompensation = false,
  });

  CalibrationConfig copyWith({
    double? centerOffset,
    double? gyroBias,
    double? steeringLock,
    double? deadzone,
    double? sensitivity,
    bool? useSmoothing,
    double? smoothingAlpha,
    bool? useDriftCompensation,
  }) {
    return CalibrationConfig(
      centerOffset: centerOffset ?? this.centerOffset,
      gyroBias: gyroBias ?? this.gyroBias,
      steeringLock: steeringLock ?? this.steeringLock,
      deadzone: deadzone ?? this.deadzone,
      sensitivity: sensitivity ?? this.sensitivity,
      useSmoothing: useSmoothing ?? this.useSmoothing,
      smoothingAlpha: smoothingAlpha ?? this.smoothingAlpha,
      useDriftCompensation: useDriftCompensation ?? this.useDriftCompensation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'centerOffset': centerOffset,
      'gyroBias': gyroBias,
      'steeringLock': steeringLock,
      'deadzone': deadzone,
      'sensitivity': sensitivity,
      'useSmoothing': useSmoothing,
      'smoothingAlpha': smoothingAlpha,
      'useDriftCompensation': useDriftCompensation,
    };
  }

  factory CalibrationConfig.fromJson(Map<String, dynamic> json) {
    return CalibrationConfig(
      centerOffset: (json['centerOffset'] as num?)?.toDouble() ?? 0.0,
      gyroBias: (json['gyroBias'] as num?)?.toDouble() ?? 0.0,
      steeringLock: (json['steeringLock'] as num?)?.toDouble() ?? 900.0,
      deadzone: (json['deadzone'] as num?)?.toDouble() ?? 0.0,
      sensitivity: (json['sensitivity'] as num?)?.toDouble() ?? 1.0,
      useSmoothing: json['useSmoothing'] as bool? ?? false,
      smoothingAlpha: (json['smoothingAlpha'] as num?)?.toDouble() ?? 0.3,
      useDriftCompensation: json['useDriftCompensation'] as bool? ?? false,
    );
  }
}

class CalibrationStorage {
  static const String _fileName = 'calibration_config.json';

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<CalibrationConfig> loadConfig() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return const CalibrationConfig();
      }
      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      return CalibrationConfig.fromJson(json);
    } catch (e) {
      // Return defaults on read failure
      return const CalibrationConfig();
    }
  }

  Future<void> saveConfig(CalibrationConfig config) async {
    try {
      final file = await _getFile();
      final contents = jsonEncode(config.toJson());
      await file.writeAsString(contents);
    } catch (_) {
      // Ignore save failure
    }
  }
}
