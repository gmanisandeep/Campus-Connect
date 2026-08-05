import 'package:campus_connect/core/theme/purple_universe/cc_colors.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_elevation.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_gradients.dart';
import 'package:flutter/material.dart';

@immutable
class CcThemeExtension extends ThemeExtension<CcThemeExtension> {
  const CcThemeExtension({
    required this.canvas,
    required this.section,
    required this.surface,
    required this.raisedSurface,
    required this.glassSurface,
    required this.borderSubtle,
    required this.controlBorder,
    required this.borderActive,
    required this.glowPrimary,
    required this.glowCyan,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.info,
    required this.infoContainer,
    required this.backgroundGradient,
    required this.heroGradient,
    required this.cardShadow,
  });

  factory CcThemeExtension.dark() => const CcThemeExtension(
    canvas: CcColors.spaceBlack,
    section: CcColors.deepNight,
    surface: CcColors.nebulaSurface,
    raisedSurface: CcColors.raisedSurface,
    glassSurface: Color(0xF218181B),
    borderSubtle: CcElevation.subtleDarkBorder,
    controlBorder: CcColors.darkControlBorder,
    borderActive: CcElevation.activeBorder,
    glowPrimary: CcColors.electricPurple,
    glowCyan: CcColors.neonCyan,
    textSecondary: CcColors.secondaryText,
    textMuted: CcColors.mutedText,
    success: CcColors.success,
    successContainer: CcColors.successContainer,
    warning: CcColors.warning,
    warningContainer: CcColors.warningContainer,
    danger: CcColors.danger,
    dangerContainer: CcColors.dangerContainer,
    info: CcColors.info,
    infoContainer: CcColors.infoContainer,
    backgroundGradient: CcGradients.deepSpace,
    heroGradient: CcGradients.electricHorizon,
    cardShadow: CcElevation.quietDark,
  );

  factory CcThemeExtension.light() => const CcThemeExtension(
    canvas: CcColors.pearlCanvas,
    section: CcColors.lavenderMist,
    surface: CcColors.cloudSurface,
    raisedSurface: CcColors.raisedPearl,
    glassSurface: Color(0xF7FCFCFD),
    borderSubtle: CcElevation.subtleLightBorder,
    controlBorder: CcColors.lightControlBorder,
    borderActive: CcColors.lightPrimary,
    glowPrimary: CcColors.electricPurple,
    glowCyan: CcColors.electricBlue,
    textSecondary: CcColors.secondaryInk,
    textMuted: CcColors.mutedInk,
    success: CcColors.lightSuccess,
    successContainer: CcColors.lightSuccessContainer,
    warning: CcColors.lightWarning,
    warningContainer: CcColors.lightWarningContainer,
    danger: CcColors.lightDanger,
    dangerContainer: CcColors.lightDangerContainer,
    info: CcColors.lightInfo,
    infoContainer: CcColors.lightInfoContainer,
    backgroundGradient: CcGradients.pearlHorizon,
    heroGradient: CcGradients.cyanViolet,
    cardShadow: CcElevation.quietLight,
  );

  final Color canvas;
  final Color section;
  final Color surface;
  final Color raisedSurface;
  final Color glassSurface;
  final Color borderSubtle;
  final Color controlBorder;
  final Color borderActive;
  final Color glowPrimary;
  final Color glowCyan;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color info;
  final Color infoContainer;
  final LinearGradient backgroundGradient;
  final LinearGradient heroGradient;
  final List<BoxShadow> cardShadow;

  @override
  CcThemeExtension copyWith({
    Color? canvas,
    Color? section,
    Color? surface,
    Color? raisedSurface,
    Color? glassSurface,
    Color? borderSubtle,
    Color? controlBorder,
    Color? borderActive,
    Color? glowPrimary,
    Color? glowCyan,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? danger,
    Color? dangerContainer,
    Color? info,
    Color? infoContainer,
    LinearGradient? backgroundGradient,
    LinearGradient? heroGradient,
    List<BoxShadow>? cardShadow,
  }) => CcThemeExtension(
    canvas: canvas ?? this.canvas,
    section: section ?? this.section,
    surface: surface ?? this.surface,
    raisedSurface: raisedSurface ?? this.raisedSurface,
    glassSurface: glassSurface ?? this.glassSurface,
    borderSubtle: borderSubtle ?? this.borderSubtle,
    controlBorder: controlBorder ?? this.controlBorder,
    borderActive: borderActive ?? this.borderActive,
    glowPrimary: glowPrimary ?? this.glowPrimary,
    glowCyan: glowCyan ?? this.glowCyan,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    danger: danger ?? this.danger,
    dangerContainer: dangerContainer ?? this.dangerContainer,
    info: info ?? this.info,
    infoContainer: infoContainer ?? this.infoContainer,
    backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    heroGradient: heroGradient ?? this.heroGradient,
    cardShadow: cardShadow ?? this.cardShadow,
  );

  @override
  CcThemeExtension lerp(covariant CcThemeExtension? other, double t) {
    if (other == null) return this;
    return CcThemeExtension(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      section: Color.lerp(section, other.section, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      raisedSurface: Color.lerp(raisedSurface, other.raisedSurface, t)!,
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      controlBorder: Color.lerp(controlBorder, other.controlBorder, t)!,
      borderActive: Color.lerp(borderActive, other.borderActive, t)!,
      glowPrimary: Color.lerp(glowPrimary, other.glowPrimary, t)!,
      glowCyan: Color.lerp(glowCyan, other.glowCyan, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      backgroundGradient: LinearGradient.lerp(
        backgroundGradient,
        other.backgroundGradient,
        t,
      )!,
      heroGradient: LinearGradient.lerp(heroGradient, other.heroGradient, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
    );
  }
}

extension CcThemeContext on BuildContext {
  CcThemeExtension get ccTheme {
    final extension = Theme.of(this).extension<CcThemeExtension>();
    assert(extension != null, 'CcThemeExtension is missing from ThemeData.');
    return extension!;
  }
}
