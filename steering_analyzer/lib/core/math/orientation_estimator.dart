import 'dart:math' as math;

import '../filters/low_pass_filter.dart';

class OrientationEstimator {
  // Three independent LPFs for gravity estimation (one per axis).
  // Alpha=0.01 gives ~500ms time constant at 200 Hz — fast enough to
  // follow slow device tilts but aggressive enough to reject steering
  // jitter.
  final LowPassFilter _gx = LowPassFilter(alpha: 0.01);
  final LowPassFilter _gy = LowPassFilter(alpha: 0.01);
  final LowPassFilter _gz = LowPassFilter(alpha: 0.01);

  // Gravity vector state, updated from accel on every sample.
  final List<double> _gravity = List<double>.filled(3, 0.0);

  void updateGravity(double ax, double ay, double az) {
    _gravity[0] = _gx.process(ax);
    _gravity[1] = _gy.process(ay);
    _gravity[2] = _gz.process(az);
  }

  void updateGravityAndRotation({
    required double ax, required double ay, required double az,
    required double mx, required double my, required double mz,
    required List<double> outGravity,
    required List<double> outQuat,
  }) {
    updateGravity(ax, ay, az);
    outGravity[0] = _gravity[0];
    outGravity[1] = _gravity[1];
    outGravity[2] = _gravity[2];

    estimateRotation(mx, my, mz, outQuat);
  }

  void estimateRotation(double mx, double my, double mz, List<double> out) {
    final double gx = _gravity[0], gy = _gravity[1], gz = _gravity[2];
    final double gLen = math.sqrt(gx * gx + gy * gy + gz * gz);
    if (gLen < 0.01) { out[0] = 0; out[1] = 0; out[2] = 0; out[3] = 1; return; }
    final double gnx = gx / gLen, gny = gy / gLen, gnz = gz / gLen;

    final double mLen = math.sqrt(mx * mx + my * my + mz * mz);
    if (mLen < 0.01) { out[0] = 0; out[1] = 0; out[2] = 0; out[3] = 1; return; }
    final double mnx = mx / mLen, mny = my / mLen, mnz = mz / mLen;

    // Earth's magnetic field projected onto horizontal plane:
    // H = grav x mag  (east-pointing vector in device coords)
    double hx = gny * mnz - gnz * mny;
    double hy = gnz * mnx - gnx * mnz;
    double hz = gnx * mny - gny * mnx;
    final double hLen = math.sqrt(hx * hx + hy * hy + hz * hz);
    if (hLen < 0.01) { out[0] = 0; out[1] = 0; out[2] = 0; out[3] = 1; return; }
    hx /= hLen; hy /= hLen; hz /= hLen;

    // North vector: M = grav x H  (orthogonal to both grav and east)
    final double mn = gny * hz - gnz * hy;
    final double m2y = gnz * hx - gnx * hz;
    final double m2z = gnx * hy - gny * hx;

    // Rotation matrix R_device-to-world:
    //   Row 0 = H  (East)
    //   Row 1 = M  (North)
    //   Row 2 = g  (Up)
    // This follows the Android SensorManager.getRotationMatrix convention.
    _matrixToQuat(
      hx, hy, hz,
      mn, m2y, m2z,
      gnx, gny, gnz,
      out,
    );
  }

  void reset() {
    _gx.reset(); _gy.reset(); _gz.reset();
    _gravity[0] = 0; _gravity[1] = 0; _gravity[2] = 9.81;
  }

  static void _matrixToQuat(
    double r00, double r01, double r02,
    double r10, double r11, double r12,
    double r20, double r21, double r22,
    List<double> out,
  ) {
    final double trace = r00 + r11 + r22;
    if (trace > 0.0) {
      final double s = 0.5 / math.sqrt(trace + 1.0);
      out[3] = 0.25 / s;
      out[0] = (r21 - r12) * s;
      out[1] = (r02 - r20) * s;
      out[2] = (r10 - r01) * s;
    } else if (r00 > r11 && r00 > r22) {
      final double s = 2.0 * math.sqrt(1.0 + r00 - r11 - r22);
      out[3] = (r21 - r12) / s;
      out[0] = 0.25 * s;
      out[1] = (r01 + r10) / s;
      out[2] = (r02 + r20) / s;
    } else if (r11 > r22) {
      final double s = 2.0 * math.sqrt(1.0 + r11 - r00 - r22);
      out[3] = (r02 - r20) / s;
      out[0] = (r01 + r10) / s;
      out[1] = 0.25 * s;
      out[2] = (r12 + r21) / s;
    } else {
      final double s = 2.0 * math.sqrt(1.0 + r22 - r00 - r11);
      out[3] = (r10 - r01) / s;
      out[0] = (r02 + r20) / s;
      out[1] = (r12 + r21) / s;
      out[2] = 0.25 * s;
    }
  }
}
