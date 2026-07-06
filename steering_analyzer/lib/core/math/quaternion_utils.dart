// quaternion_utils.dart
//
// Quaternion math used to convert between orientation sensor samples and
// Euler angles, and to perform a tiny complementary filter between the
// gyroscope-integrated rotation and the absolute rotation vector.
//
// Quaternions are stored in `[x, y, z, w]` order (the same as the
// `sensors_plus` `RotationVector.x/y/z/w` accessors).  We don't depend on
// the `vector_math` package here for the hot path because we want to keep
// the implementation small and obvious.

import 'dart:math' as math;
import 'math_utils.dart';

/// Multiplies two quaternions in `[x, y, z, w]` order. The result represents
/// the rotation `a` followed by `b` (in that order).
///
/// Hamilton product:
///
///   (a*b).x = a.w*b.x + a.x*b.w + a.y*b.z - a.z*b.y
///   (a*b).y = a.w*b.y - a.x*b.z + a.y*b.w + a.z*b.x
///   (a*b).z = a.w*b.z + a.x*b.y - a.y*b.x + a.z*b.w
///   (a*b).w = a.w*b.w - a.x*b.x - a.y*b.y - a.z*b.z
List<double> quatMultiply(List<double> a, List<double> b) {
  return <double>[
    a[3] * b[0] + a[0] * b[3] + a[1] * b[2] - a[2] * b[1],
    a[3] * b[1] - a[0] * b[2] + a[1] * b[3] + a[2] * b[0],
    a[3] * b[2] + a[0] * b[1] - a[1] * b[0] + a[2] * b[3],
    a[3] * b[3] - a[0] * b[0] - a[1] * b[1] - a[2] * b[2],
  ];
}

/// Computes the conjugate of a unit quaternion, which is its inverse.
///
/// For a unit quaternion `q = [x, y, z, w]`, `q^-1 = [-x, -y, -z, w]`.
List<double> quatConjugate(List<double> q) => <double>[-q[0], -q[1], -q[2], q[3]];

/// Normalises a quaternion in place. Returns the original list to keep the
/// call sites tidy.
List<double> quatNormalize(List<double> q) {
  final double n2 = q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3];
  if (n2 <= 0.0) return <double>[0, 0, 0, 1];
  final double inv = 1.0 / math.sqrt(n2);
  q[0] *= inv; q[1] *= inv; q[2] *= inv; q[3] *= inv;
  return q;
}

/// Converts a unit quaternion `[x, y, z, w]` to Euler angles (in degrees)
/// using the Tait-Bryan ZYX convention:
///
///   yaw   = atan2( 2(wz + xy),  1 - 2(y^2 + z^2) )   // rotation about z
///   pitch = asin (  2(wy - xz)                     )   // rotation about y
///   roll  = atan2(  2(wx + yz),  1 - 2(x^2 + y^2) )   // rotation about x
///
/// We follow the Android sensor convention where the phone is held in
/// portrait and yaw is the "heading" (compass) angle.
List<double> quatToEulerDeg(List<double> q) {
  final double x = q[0], y = q[1], z = q[2], w = q[3];

  // Roll (rotation about x-axis)
  final double sinr_cosp = 2.0 * (w * x + y * z);
  final double cosr_cosp = 1.0 - 2.0 * (x * x + y * y);
  final double roll = math.atan2(sinr_cosp, cosr_cosp);

  // Pitch (rotation about y-axis)
  final double sinp = 2.0 * (w * y - z * x);
  final double pitch = math.asin(clamp(sinp, -1.0, 1.0));

  // Yaw (rotation about z-axis)
  final double siny_cosp = 2.0 * (w * z + x * y);
  final double cosy_cosp = 1.0 - 2.0 * (y * y + z * z);
  final double yaw = math.atan2(siny_cosp, cosy_cosp);

  return <double>[radToDeg(roll), radToDeg(pitch), radToDeg(yaw)];
}

/// Builds a quaternion from an axis (unit length) and an angle in radians.
List<double> quatFromAxisAngle(List<double> axis, double angleRad) {
  final double half = angleRad * 0.5;
  final double s = math.sin(half);
  return <double>[axis[0] * s, axis[1] * s, axis[2] * s, math.cos(half)];
}

/// Spherical linear interpolation between two unit quaternions.
///
/// Used by some fusion filters to smoothly re-anchor a drifted gyro-only
/// orientation back to the absolute reference.
List<double> quatSlerp(List<double> a, List<double> b, double t) {
  double cosTheta = a[0] * b[0] + a[1] * b[1] + a[2] * b[2] + a[3] * b[3];

  // If the dot product is negative, take the shorter path by flipping b.
  List<double> bAdj = b;
  if (cosTheta < 0.0) {
    bAdj = <double>[-b[0], -b[1], -b[2], -b[3]];
    cosTheta = -cosTheta;
  }

  // Quaternions are nearly identical; fall back to linear interpolation
  // to avoid division by sin(theta) ~ 0.
  if (cosTheta > 0.9995) {
    return quatNormalize(<double>[
      a[0] + t * (bAdj[0] - a[0]),
      a[1] + t * (bAdj[1] - a[1]),
      a[2] + t * (bAdj[2] - a[2]),
      a[3] + t * (bAdj[3] - a[3]),
    ]);
  }

  final double theta = math.acos(cosTheta);
  final double sinTheta = math.sin(theta);
  final double wa = math.sin((1.0 - t) * theta) / sinTheta;
  final double wb = math.sin(t * theta) / sinTheta;
  return <double>[
    wa * a[0] + wb * bAdj[0],
    wa * a[1] + wb * bAdj[1],
    wa * a[2] + wb * bAdj[2],
    wa * a[3] + wb * bAdj[3],
  ];
}
