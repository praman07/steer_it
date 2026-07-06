import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/math/orientation_estimator.dart';
import '../models/sensor_sample.dart';

class SensorService {
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<UserAccelerometerEvent>? _userAccelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<CompassEvent>? _compassSub;

  final SensorFrame _frame = SensorFrame();
  final StreamController<SensorSample> _controller =
      StreamController<SensorSample>.broadcast();
  final OrientationEstimator _orientation = OrientationEstimator();

  final Stopwatch _watch = Stopwatch()..start();
  DateTime _start = DateTime.now();
  final Duration _samplingPeriod;

  // Scratch buffer for the estimator output.
  final List<double> _gvScratch = List<double>.filled(3, 0.0);
  final List<double> _rotScratch = List<double>.filled(4, 0.0);

  bool _started = false;

  SensorService({Duration samplingPeriod = const Duration(microseconds: 5 * 1000)})
      : _samplingPeriod = samplingPeriod;

  Stream<SensorSample> get stream => _controller.stream;
  bool get isRunning => _started;

  void start() {
    if (_started) return;
    _started = true;
    _watch.start();
    _start = DateTime.now();

    _gyroSub = gyroscopeEventStream(samplingPeriod: _samplingPeriod).listen((e) {
      _frame.gx = e.x; _frame.gy = e.y; _frame.gz = e.z;
      _emit();
    }, onError: (Object _) {});

    _accelSub = accelerometerEventStream(samplingPeriod: _samplingPeriod).listen((e) {
      _frame.ax = e.x; _frame.ay = e.y; _frame.az = e.z;
      _orientation.updateGravity(e.x, e.y, e.z);
    }, onError: (Object _) {});

    _userAccelSub = userAccelerometerEventStream(samplingPeriod: _samplingPeriod).listen((e) {
      _frame.uax = e.x; _frame.uay = e.y; _frame.uaz = e.z;
    }, onError: (Object _) {});

    _magSub = magnetometerEventStream(samplingPeriod: _samplingPeriod).listen((e) {
      _frame.mx = e.x; _frame.my = e.y; _frame.mz = e.z;
    }, onError: (Object _) {});

    final compassStream = FlutterCompass.events;
    if (compassStream != null) {
      _compassSub = compassStream.listen((e) {
        if (e.heading != null) {
          _frame.setHeading(e.heading!);
        }
      }, onError: (Object _) {});
    }
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    await _gyroSub?.cancel();
    await _accelSub?.cancel();
    await _userAccelSub?.cancel();
    await _magSub?.cancel();
    await _compassSub?.cancel();
    _gyroSub = null; _accelSub = null; _userAccelSub = null;
    _magSub = null; _compassSub = null;
    _watch.stop();
  }

  void _emit() {
    _frame.timestampUs = _watch.elapsedMicroseconds.toDouble();
    _frame.wallClockMs = DateTime.now().difference(_start).inMilliseconds;

    // Synthesize gravity vector and rotation quaternion from accel + mag.
    _orientation.updateGravityAndRotation(
      ax: _frame.ax, ay: _frame.ay, az: _frame.az,
      mx: _frame.mx, my: _frame.my, mz: _frame.mz,
      outGravity: _gvScratch,
      outQuat: _rotScratch,
    );
    _frame.gvx = _gvScratch[0];
    _frame.gvy = _gvScratch[1];
    _frame.gvz = _gvScratch[2];
    _frame.setRotation(_rotScratch, 0.8);
    // Derive absolute orientation from the rotation quaternion.
    final double roll = _estimateRoll(_rotScratch);
    final double pitch = _estimatePitch(_rotScratch);
    final double yaw = _estimateYaw(_rotScratch);
    _frame.setAbsoluteOrientation(yaw, pitch, roll);

    _controller.add(_frame.snapshot());
  }

  void prime() {
    if (_started) _emit();
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  // Quick Euler-angle extraction from a quaternion [x,y,z,w] using the
  // same convention as quatToEulerDeg in quaternion_utils.dart.
  static double _estimateRoll(List<double> q) {
    final double x = q[0], y = q[1], z = q[2], w = q[3];
    final double sinrCosp = 2.0 * (w * x + y * z);
    final double cosrCosp = 1.0 - 2.0 * (x * x + y * y);
    return _radToDeg(math.atan2(sinrCosp, cosrCosp));
  }

  static double _estimatePitch(List<double> q) {
    final double x = q[0], y = q[1], z = q[2], w = q[3];
    final double sinp = 2.0 * (w * y - z * x);
    return _radToDeg(math.asin(sinp.clamp(-1.0, 1.0)));
  }

  static double _estimateYaw(List<double> q) {
    final double x = q[0], y = q[1], z = q[2], w = q[3];
    final double sinyCosp = 2.0 * (w * z + x * y);
    final double cosyCosp = 1.0 - 2.0 * (y * y + z * z);
    return _radToDeg(math.atan2(sinyCosp, cosyCosp));
  }

  static double _radToDeg(double rad) => rad * 57.29577951308232;
}
