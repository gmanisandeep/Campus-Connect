import 'package:campus_connect/core/theme/purple_universe/cc_colors.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_radius.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';

abstract final class AppSpacing {
  static const xxs = CcSpacing.xxs;
  static const xs = CcSpacing.xs;
  static const sm = CcSpacing.sm;
  static const md = CcSpacing.md;
  static const lg = CcSpacing.lg;
  static const xl = CcSpacing.xl;
  static const xxl = CcSpacing.xxxl;
}

abstract final class AppRadius {
  static const control = CcRadius.control;
  static const card = CcRadius.card;
  static const prominent = CcRadius.prominent;
}

abstract final class AppBreakpoints {
  static const navigationRail = 720.0;
  static const maxContentWidth = 1200.0;
}

abstract final class AppColors {
  static const lightSeed = CcColors.lightPrimary;
  static const darkSeed = CcColors.electricPurple;
}
