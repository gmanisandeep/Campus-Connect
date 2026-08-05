import 'package:campus_connect/core/theme/purple_universe/cc_colors.dart';
import 'package:flutter/material.dart';

abstract final class CcGradients {
  static const purpleCore = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B21B6), CcColors.ultraViolet, Color(0xFFA855F7)],
  );

  static const electricHorizon = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF243CFF), Color(0xFF6D28D9), CcColors.nebulaPink],
  );

  static const cyanViolet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22D3EE), Color(0xFF3B82F6), CcColors.electricPurple],
  );

  static const deepSpace = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF171020), CcColors.spaceBlack, CcColors.spaceBlack],
    stops: [0, 0.34, 1],
  );

  static const nebula = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF090512),
      Color(0xFF22104F),
      Color(0xFF4C1D95),
      Color(0xFF1310A1),
    ],
  );

  static const pearlHorizon = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF3EFFA), CcColors.pearlCanvas, CcColors.pearlCanvas],
    stops: [0, 0.34, 1],
  );
}
