import 'package:flutter/material.dart';

abstract final class CcTypography {
  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
  }) => TextTheme(
    displayLarge: TextStyle(
      color: primary,
      fontSize: 44,
      height: 1.08,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.1,
    ),
    displayMedium: TextStyle(
      color: primary,
      fontSize: 34,
      height: 1.12,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.7,
    ),
    displaySmall: TextStyle(
      color: primary,
      fontSize: 30,
      height: 1.15,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineLarge: TextStyle(
      color: primary,
      fontSize: 28,
      height: 1.18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.35,
    ),
    headlineMedium: TextStyle(
      color: primary,
      fontSize: 24,
      height: 1.20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    headlineSmall: TextStyle(
      color: primary,
      fontSize: 22,
      height: 1.22,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      color: primary,
      fontSize: 20,
      height: 1.25,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      color: primary,
      fontSize: 17,
      height: 1.28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.05,
    ),
    titleSmall: TextStyle(
      color: primary,
      fontSize: 15,
      height: 1.35,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      color: primary,
      fontSize: 16,
      height: 1.50,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      color: primary,
      fontSize: 14,
      height: 1.48,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      color: secondary,
      fontSize: 13,
      height: 1.40,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: TextStyle(
      color: primary,
      fontSize: 14,
      height: 1.30,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    labelMedium: TextStyle(
      color: secondary,
      fontSize: 12,
      height: 1.35,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
    labelSmall: TextStyle(
      color: secondary,
      fontSize: 11,
      height: 1.35,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.25,
    ),
  );
}
