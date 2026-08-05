import 'package:campus_connect/core/theme/purple_universe/cc_colors.dart';
import 'package:flutter/material.dart';

abstract final class CcElevation {
  static const quietDark = [
    BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const quietLight = [
    BoxShadow(color: Color(0x1F286589), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const focal = [
    BoxShadow(
      color: Color(0x3D7C3AED),
      blurRadius: 24,
      spreadRadius: -4,
      offset: Offset(0, 10),
    ),
  ];

  static const activeGlow = BoxShadow(
    color: Color(0x4D8B5CF6),
    blurRadius: 18,
    spreadRadius: -2,
  );

  static const cyanGlow = BoxShadow(
    color: Color(0x3836E4FF),
    blurRadius: 16,
    spreadRadius: -3,
  );

  static const subtleDarkBorder = Color(0xFF2E2E32);
  static const subtleLightBorder = Color(0xFFD6EAF5);
  static const activeBorder = CcColors.electricPurple;

  static const orbit = [
    BoxShadow(
      color: Color(0x4D1E78B4),
      blurRadius: 18,
      spreadRadius: -2,
      offset: Offset(0, 7),
    ),
  ];
}
