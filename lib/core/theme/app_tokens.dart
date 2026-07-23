import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadius {
  static const control = 8.0;
  static const card = 12.0;
  static const prominent = 20.0;
}

abstract final class AppBreakpoints {
  static const navigationRail = 720.0;
  static const maxContentWidth = 1200.0;
}

abstract final class AppColors {
  static const lightSeed = Color(0xFF4F46E5);
  static const darkSeed = Color(0xFF8B8CF8);
}
