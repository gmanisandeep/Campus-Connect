import 'package:campus_connect/core/theme/purple_universe/cc_colors.dart';
import 'package:flutter/material.dart';

abstract final class CcGradients {
  static const purpleCore = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2876B8), CcColors.skyBlue, Color(0xFF73CEF4)],
  );

  static const electricHorizon = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF165D9B), Color(0xFF3E9BD6), Color(0xFF7DDBF4)],
  );

  static const cyanViolet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFBDEBFF), Color(0xFF69C5F2), CcColors.skyBlue],
  );

  static const deepSpace = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF153B55), CcColors.spaceBlack, CcColors.spaceBlack],
    stops: [0, 0.34, 1],
  );

  static const nebula = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A263A),
      Color(0xFF174B6B),
      Color(0xFF2F88BD),
      Color(0xFF76D0F2),
    ],
  );

  static const pearlHorizon = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFBFEAFF), CcColors.pearlCanvas, Color(0xFFF8FCFF)],
    stops: [0, 0.46, 1],
  );

  static const orbitBlue = RadialGradient(
    center: Alignment(-0.35, -0.45),
    radius: 0.95,
    colors: [Color(0xFFD8F6FF), Color(0xFF53B9EE), Color(0xFF0B5E9D)],
    stops: [0, 0.48, 1],
  );
}
