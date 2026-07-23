import 'package:flutter/animation.dart';

abstract final class CcMotionDurations {
  static const instant = Duration(milliseconds: 80);
  static const quick = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 220);
  static const comfortable = Duration(milliseconds: 320);
  static const expressive = Duration(milliseconds: 450);
  static const shortLoop = Duration(milliseconds: 1600);
  static const ambient = Duration(seconds: 12);
  static const ambientLong = Duration(seconds: 20);
}

abstract final class CcMotionCurves {
  static const standard = Cubic(0.20, 0.00, 0.00, 1.00);
  static const decelerate = Cubic(0.00, 0.00, 0.00, 1.00);
  static const accelerate = Cubic(0.30, 0.00, 1.00, 1.00);
  static const soft = Cubic(0.22, 0.61, 0.36, 1.00);
  static const ambient = Curves.easeInOutSine;
}

abstract final class CcMotionSprings {
  static final spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 520,
    ratio: 0.82,
  );
  static final softSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 300,
    ratio: 0.95,
  );
}
