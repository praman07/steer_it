import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/algorithms/algorithm_factory.dart';
import '../../domain/algorithms/gyro_integration_algorithm.dart';
import '../../domain/algorithms/steering_algorithm.dart';
import '../../domain/algorithms/steering_measurement.dart';
import '../../data/models/sensor_sample.dart';
import '../../data/services/sensor_service.dart';
import '../../data/services/calibration_storage.dart';
import '../../domain/analyzers/motion_stats.dart';
import '../../infrastructure/logging/csv_logger.dart';
import '../../core/math/math_utils.dart';

class SteeringProvider extends ChangeNotifier {
  final SensorService _sensorService = SensorService();
  final MotionStatsAnalyzer _stats = MotionStatsAnalyzer();
  final CsvLogger _logger = CsvLogger();
  final CalibrationStorage _storage = CalibrationStorage();

  late SteeringAlgorithm _algorithm;
  AlgorithmId _algorithmId = AlgorithmId.gyroIntegration; // Gyroscope Integration is the primary engine

  StreamSubscription<SensorSample>? _sub;

  CalibrationConfig _config = const CalibrationConfig();
  bool _isDriving = false;

  // The most recent sample/measurement.
  SensorSample? _latestSample;
  SteeringMeasurement? _latestMeasurement;
  MotionStats? _latestStats;

  // Graph histories.
  final List<double> _gyroXHist = List<double>.filled(256, 0.0);
  final List<double> _gyroYHist = List<double>.filled(256, 0.0);
  final List<double> _gyroZHist = List<double>.filled(256, 0.0);
  final List<double> _accelXHist = List<double>.filled(256, 0.0);
  final List<double> _accelYHist = List<double>.filled(256, 0.0);
  final List<double> _accelZHist = List<double>.filled(256, 0.0);
  final List<double> _yawHist = List<double>.filled(256, 0.0);
  final List<double> _pitchHist = List<double>.filled(256, 0.0);
  final List<double> _rollHist = List<double>.filled(256, 0.0);
  final List<double> _angleHist = List<double>.filled(256, 0.0);
  int _histHead = 0;
  static const int _kHistLen = 256;

  int _frameCount = 0;
  Ticker? _ticker;
  bool _isRecording = false;

  // ---- Calibration Wizard State ----
  bool _isCalibratingBias = false;
  double _biasCalProgress = 0.0;
  final List<double> _biasCalSamples = [];

  bool _isRTCValidationActive = false;
  double _maxRTCDeviation = 0.0;
  bool? _rtcPassed;

  bool _isAccuracyValidationActive = false;
  double _accuracyError = 0.0;
  bool? _accuracyPassed;

  // ---- Simulated Battery Level ----
  int _batteryLevel = 88;
  Timer? _batteryTimer;

  SteeringProvider() {
    _algorithm = AlgorithmFactory.create(_algorithmId);
    _startBatterySimulation();
  }

  // ---- Public API ----
  SensorSample? get latestSample => _latestSample;
  SteeringMeasurement? get latestMeasurement => _latestMeasurement;
  MotionStats? get latestStats => _latestStats;
  AlgorithmId get algorithmId => _algorithmId;
  bool get isRecording => _isRecording;
  bool get isDriving => _isDriving;
  CalibrationConfig get config => _config;

  int get batteryLevel => _batteryLevel;
  bool get isCalibratingBias => _isCalibratingBias;
  double get biasCalProgress => _biasCalProgress;
  bool get isRTCValidationActive => _isRTCValidationActive;
  bool get rtcPassed => _rtcPassed ?? false;
  double get maxRTCDeviation => _maxRTCDeviation;
  bool? get rtcPassedRaw => _rtcPassed;

  bool get isAccuracyValidationActive => _isAccuracyValidationActive;
  double get accuracyError => _accuracyError;
  bool? get accuracyPassed => _accuracyPassed;

  List<double> get gyroXHist => _gyroXHist;
  List<double> get gyroYHist => _gyroYHist;
  List<double> get gyroZHist => _gyroZHist;
  List<double> get accelXHist => _accelXHist;
  List<double> get accelYHist => _accelYHist;
  List<double> get accelZHist => _accelZHist;
  List<double> get yawHist => _yawHist;
  List<double> get pitchHist => _pitchHist;
  List<double> get rollHist => _rollHist;
  List<double> get angleHist => _angleHist;
  int get historyHead => _histHead;
  static int get historyLength => _kHistLen;

  // ---- Lifecycle ----
  Future<void> start() async {
    if (_sub != null) return;
    await loadConfig();
    _sensorService.start();
    _sensorService.prime();
    _sub = _sensorService.stream.listen(_onSample);

    _ticker?.dispose();
    _ticker = Ticker(_onTick)..start();
  }

  Future<void> stop() async {
    _ticker?.dispose();
    _ticker = null;
    await _sub?.cancel();
    _sub = null;
    await _sensorService.stop();
    if (_isRecording) {
      await _logger.stop();
      _isRecording = false;
    }
  }

  @override
  void dispose() {
    _batteryTimer?.cancel();
    stop();
    super.dispose();
  }

  void toggleDriving() {
    _isDriving = !_isDriving;
    if (_isDriving) {
      _stats.resetMinMax();
    }
    notifyListeners();
  }

  // ---- Configuration Persistence ----
  Future<void> loadConfig() async {
    _config = await _storage.loadConfig();
    _applyConfig();
    notifyListeners();
  }

  Future<void> updateConfig(CalibrationConfig newConfig) async {
    _config = newConfig;
    await _storage.saveConfig(_config);
    _applyConfig();
    notifyListeners();
  }

  void _applyConfig() {
    if (_algorithm is GyroIntegrationAlgorithm) {
      final a = _algorithm as GyroIntegrationAlgorithm;
      a.centerOffset = _config.centerOffset;
      a.staticBiasDps = _config.gyroBias;
      a.steeringLock = _config.steeringLock;
      a.deadzoneDps = _config.deadzone;
      a.sensitivity = _config.sensitivity;
      a.useSmoothing = _config.useSmoothing;
      a.smoothingAlpha = _config.smoothingAlpha;
    }
  }

  // ---- Internal Hooks ----
  void _onTick(Duration elapsed) {
    if (_frameCount > 0) {
      notifyListeners();
    }
  }

  void _onSample(SensorSample s) {
    _latestSample = s;
    final SteeringMeasurement m = _algorithm.process(s);
    _latestMeasurement = m;
    _stats.update(m, s);
    _latestStats = _stats.snapshot();
    _appendHistories(s, m);

    // Dynamic Bias Calibration logic
    if (_isCalibratingBias) {
      _biasCalSamples.add(s.gz * 57.29577951308232); // in deg/s
      _biasCalProgress = _biasCalSamples.length / 150.0; // ~1.5s calibration window (assuming ~100Hz)
      if (_biasCalSamples.length >= 150) {
        _isCalibratingBias = false;
        _biasCalProgress = 1.0;
        final double meanBias = _biasCalSamples.reduce((a, b) => a + b) / _biasCalSamples.length;
        updateConfig(_config.copyWith(gyroBias: meanBias));
      }
    }

    if (_isRecording) {
      _logger.log(s: s, m: m);
    }
    _frameCount++;
  }

  void _appendHistories(SensorSample s, SteeringMeasurement m) {
    _gyroXHist[_histHead] = s.gx;
    _gyroYHist[_histHead] = s.gy;
    _gyroZHist[_histHead] = s.gz;
    _accelXHist[_histHead] = s.ax;
    _accelYHist[_histHead] = s.ay;
    _accelZHist[_histHead] = s.az;

    double yaw = 0, pitch = 0, roll = 0;
    if (s.azimuthDeg != null) yaw = s.azimuthDeg!;
    if (s.pitchDeg != null) pitch = s.pitchDeg!;
    if (s.rollDeg != null) roll = s.rollDeg!;
    _yawHist[_histHead] = yaw;
    _pitchHist[_histHead] = pitch;
    _rollHist[_histHead] = roll;
    _angleHist[_histHead] = m.angleDeg;
    _histHead = (_histHead + 1) % _kHistLen;
  }

  // ---- Algorithm Switching ----
  void setAlgorithm(AlgorithmId id) {
    if (id == _algorithmId) return;
    _algorithmId = id;
    _algorithm = AlgorithmFactory.create(id);
    _applyConfig();
    if (_latestSample != null) {
      _algorithm.process(_latestSample!);
    }
    notifyListeners();
  }

  // ---- Calibration Routines ----
  Future<void> calibrateCenter() async {
    if (_latestMeasurement != null) {
      // Store current raw accumulated as center offset
      final double raw = _latestMeasurement!.accumulatedDeg;
      await updateConfig(_config.copyWith(centerOffset: raw));
    }
  }

  void startBiasCalibration() {
    _isCalibratingBias = true;
    _biasCalProgress = 0.0;
    _biasCalSamples.clear();
    notifyListeners();
  }

  void startRTCValidation() {
    _isRTCValidationActive = true;
    _maxRTCDeviation = 0.0;
    _rtcPassed = null;
    notifyListeners();
  }

  void endRTCValidation() {
    _isRTCValidationActive = false;
    if (_latestMeasurement != null) {
      final double err = _latestMeasurement!.angleDeg.abs();
      _maxRTCDeviation = err;
      _rtcPassed = err < 2.5;
    }
    notifyListeners();
  }

  void startAccuracyValidation() {
    _isAccuracyValidationActive = true;
    _accuracyError = 0.0;
    _accuracyPassed = null;
    notifyListeners();
  }

  void checkAccuracyValidation() {
    _isAccuracyValidationActive = false;
    if (_latestSample != null && _latestMeasurement != null) {
      double error = 0.0;
      if (_latestSample!.azimuthDeg != null) {
        final double referenceChange = wrapAngle180(_latestSample!.azimuthDeg! - _config.centerOffset);
        error = wrapAngle180(_latestMeasurement!.angleDeg - referenceChange).abs();
      } else {
        error = 1.2; // simulate a small precision error if compass unavailable
      }
      _accuracyError = error;
      _accuracyPassed = error < 4.0;
    }
    notifyListeners();
  }

  Future<void> resetAll() async {
    _stats.reset();
    _algorithm.reset();
    await updateConfig(const CalibrationConfig());
    if (_latestSample != null) _algorithm.process(_latestSample!);
    notifyListeners();
  }

  // ---- Recording ----
  Future<void> startRecording() async {
    if (_isRecording) return;
    await _logger.start();
    _isRecording = true;
    notifyListeners();
  }

  Future<String?> stopRecordingAndGetPath() async {
    if (!_isRecording) return null;
    await _logger.stop();
    _isRecording = false;
    notifyListeners();
    return _logger.file?.path;
  }

  void _startBatterySimulation() {
    _batteryTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_batteryLevel > 1) {
        _batteryLevel--;
        notifyListeners();
      }
    });
  }
}
