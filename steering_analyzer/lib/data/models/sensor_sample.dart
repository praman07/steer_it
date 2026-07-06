// sensor_sample.dart
//
// Immutable snapshot of every sensor reading at one point in time, plus
// a mutable per-frame container used inside the sensor service.  The
// pipeline emits one immutable `SensorSample` per gyroscope event (the
// highest-rate sensor) and tags the other values with the most-recently
// observed reading.  This keeps everything synchronous with a single
// clock and avoids rate-mismatch bugs.

import 'dart:typed_data';

class SensorSample {
  /// Monotonic time in microseconds since an unspecified epoch.  We use
  /// the `Stopwatch` so values are monotonic during a session and
  /// suitable for dt calculations, but not for wall-clock time.  Use
  /// `wallClockMs` for the latter.
  final double timestampUs;
  final int wallClockMs;

  // Raw gyroscope in rad/s.
  final double gx, gy, gz;

  // Raw accelerometer in m/s^2.
  final double ax, ay, az;

  // Gravity-removed user acceleration in m/s^2.
  final double uax, uay, uaz;

  // Magnetometer in microtesla.
  final double mx, my, mz;

  // Rotation vector as a quaternion in [x, y, z, w] order, with an
  // accuracy estimate (0 = untrusted, 1 = fully trusted).  Null if
  // not available.
  final List<double>? rotation;
  final double rotationAccuracy;

  // Gravity vector in m/s^2.
  final double gvx, gvy, gvz;

  // Absolute orientation in degrees from the device's orientation
  // sensor (azimuth is the compass heading, pitch and roll are as
  // defined in the Android docs).  Null entries if not available.
  final double? azimuthDeg;
  final double? pitchDeg;
  final double? rollDeg;

  // Heading (compass) in degrees.  Null if not available.
  final double? headingDeg;

  const SensorSample({
    required this.timestampUs,
    required this.wallClockMs,
    required this.gx, required this.gy, required this.gz,
    required this.ax, required this.ay, required this.az,
    required this.uax, required this.uay, required this.uaz,
    required this.mx, required this.my, required this.mz,
    required this.rotation,
    required this.rotationAccuracy,
    required this.gvx, required this.gvy, required this.gvz,
    required this.azimuthDeg,
    required this.pitchDeg,
    required this.rollDeg,
    required this.headingDeg,
  });

  /// Empty sample used to seed the first frame before any sensor has
  /// reported.  All values are zero and `rotation = [0, 0, 0, 1]`
  /// (the identity quaternion).  The accelerometer is initialised
  /// with a +9.81 m/s^2 z-axis reading so that the orientation
  /// filters start in a sensible state if the phone happens to be
  /// lying flat.
  static SensorSample zero(double tUs, int wallMs) {
    return SensorSample(
      timestampUs: tUs,
      wallClockMs: wallMs,
      gx: 0, gy: 0, gz: 0,
      ax: 0, ay: 0, az: 9.81,
      uax: 0, uay: 0, uaz: 0,
      mx: 0, my: 0, mz: 0,
      rotation: const <double>[0, 0, 0, 1],
      rotationAccuracy: 0,
      gvx: 0, gvy: 0, gvz: 9.81,
      azimuthDeg: 0, pitchDeg: 0, rollDeg: 0,
      headingDeg: 0,
    );
  }
}

/// Mutable per-frame sample.  We use a mutable variant inside the
/// sensor service so that we can write the latest reading of every
/// sensor into a single allocation-free container.  At the end of the
/// frame we copy out an immutable `SensorSample` for the algorithm
/// to consume.
class SensorFrame {
  double timestampUs = 0.0;
  int wallClockMs = 0;

  double gx = 0, gy = 0, gz = 0;
  double ax = 0, ay = 0, az = 0;
  double uax = 0, uay = 0, uaz = 0;
  double mx = 0, my = 0, mz = 0;

  final Float64List _rotation = Float64List(4);
  double rotationAccuracy = 0.0;

  double gvx = 0, gvy = 0, gvz = 9.81;

  double azimuthDeg = 0;
  double pitchDeg = 0;
  double rollDeg = 0;
  double headingDeg = 0;

  bool hasRotation = false;
  bool hasAbsoluteOrientation = false;
  bool hasHeading = false;

  SensorFrame() {
    _rotation[3] = 1.0; // identity quaternion
  }

  void reset() {
    gx = gy = gz = 0;
    ax = ay = az = 0;
    uax = uay = uaz = 0;
    mx = my = mz = 0;
    _rotation[0] = 0; _rotation[1] = 0; _rotation[2] = 0; _rotation[3] = 1;
    rotationAccuracy = 0;
    gvx = 0; gvy = 0; gvz = 9.81;
    azimuthDeg = 0; pitchDeg = 0; rollDeg = 0; headingDeg = 0;
    hasRotation = false;
    hasAbsoluteOrientation = false;
    hasHeading = false;
  }

  /// Copy values from the live sensor streams into this frame.
  void updateFrom({
    required double gx, required double gy, required double gz,
    required double ax, required double ay, required double az,
    required double uax, required double uay, required double uaz,
    required double mx, required double my, required double mz,
    required double gvx, required double gvy, required double gvz,
  }) {
    this.gx = gx; this.gy = gy; this.gz = gz;
    this.ax = ax; this.ay = ay; this.az = az;
    this.uax = uax; this.uay = uay; this.uaz = uaz;
    this.mx = mx; this.my = my; this.mz = mz;
    this.gvx = gvx; this.gvy = gvy; this.gvz = gvz;
  }

  void setRotation(List<double> q, double accuracy) {
    _rotation[0] = q[0]; _rotation[1] = q[1];
    _rotation[2] = q[2]; _rotation[3] = q[3];
    rotationAccuracy = accuracy;
    hasRotation = true;
  }

  void setAbsoluteOrientation(double azimuth, double pitch, double roll) {
    azimuthDeg = azimuth; pitchDeg = pitch; rollDeg = roll;
    hasAbsoluteOrientation = true;
  }

  void setHeading(double h) {
    headingDeg = h;
    hasHeading = true;
  }

  /// Build an immutable snapshot for downstream algorithms.
  SensorSample snapshot() {
    return SensorSample(
      timestampUs: timestampUs,
      wallClockMs: wallClockMs,
      gx: gx, gy: gy, gz: gz,
      ax: ax, ay: ay, az: az,
      uax: uax, uay: uay, uaz: uaz,
      mx: mx, my: my, mz: mz,
      rotation: hasRotation
          ? <double>[_rotation[0], _rotation[1], _rotation[2], _rotation[3]]
          : null,
      rotationAccuracy: rotationAccuracy,
      gvx: gvx, gvy: gvy, gvz: gvz,
      azimuthDeg: hasAbsoluteOrientation ? azimuthDeg : null,
      pitchDeg: hasAbsoluteOrientation ? pitchDeg : null,
      rollDeg: hasAbsoluteOrientation ? rollDeg : null,
      headingDeg: hasHeading ? headingDeg : null,
    );
  }
}
