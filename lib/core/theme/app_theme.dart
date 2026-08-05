import 'package:campus_connect/core/theme/app_tokens.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_colors.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_elevation.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_radius.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_typography.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = isDark ? _darkScheme() : _lightScheme();
    final ccTheme = isDark ? CcThemeExtension.dark() : CcThemeExtension.light();
    final textTheme = CcTypography.textTheme(
      primary: scheme.onSurface,
      secondary: ccTheme.textSecondary,
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(CcRadius.capsule),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: ccTheme.canvas,
      canvasColor: ccTheme.canvas,
      textTheme: textTheme,
      extensions: [ccTheme],
      focusColor: scheme.primary.withValues(alpha: 0.22),
      hoverColor: scheme.primary.withValues(alpha: 0.10),
      splashColor: scheme.primary.withValues(alpha: 0.12),
      cardTheme: CardThemeData(
        elevation: 0,
        color: ccTheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CcRadius.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ccTheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CcSpacing.md,
          vertical: CcSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CcRadius.card),
          borderSide: BorderSide(color: ccTheme.controlBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CcRadius.card),
          borderSide: BorderSide(color: ccTheme.controlBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CcRadius.card),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CcRadius.card),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CcRadius.card),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? CcColors.starWhite : CcColors.inkBlack,
          foregroundColor: isDark ? CcColors.inkBlack : Colors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: CcSpacing.lg,
            vertical: CcSpacing.sm,
          ),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: CcSpacing.lg,
            vertical: CcSpacing.sm,
          ),
          side: BorderSide(color: ccTheme.controlBorder),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size.square(44)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ccTheme.raisedSurface,
        selectedColor: isDark ? CcColors.starWhite : CcColors.inkBlack,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: isDark ? CcColors.inkBlack : Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: CcSpacing.xs),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(72, 42)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: CcSpacing.md),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? (isDark ? CcColors.starWhite : CcColors.inkBlack)
                : ccTheme.raisedSurface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? (isDark ? CcColors.inkBlack : Colors.white)
                : scheme.onSurface,
          ),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        elevation: 0,
        backgroundColor: ccTheme.surface,
        indicatorColor: Colors.transparent,
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : ccTheme.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : ccTheme.textSecondary,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: ccTheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: ccTheme.textSecondary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: ccTheme.raisedSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CcRadius.prominent),
          side: BorderSide(color: ccTheme.borderSubtle),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: ccTheme.raisedSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(CcRadius.prominent),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: ccTheme.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: scheme.secondaryContainer,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSecondaryContainer,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: CcSpacing.md,
          vertical: CcSpacing.sm,
        ),
      ),
      visualDensity: VisualDensity.standard,
    );
  }

  static ColorScheme _darkScheme() =>
      ColorScheme.fromSeed(
        seedColor: AppColors.darkSeed,
        brightness: Brightness.dark,
      ).copyWith(
        primary: CcColors.skyBright,
        onPrimary: CcColors.voidDark,
        primaryContainer: const Color(0xFF2B1857),
        onPrimaryContainer: CcColors.softLavender,
        primaryFixed: CcColors.paleViolet,
        primaryFixedDim: CcColors.softLavender,
        onPrimaryFixed: CcColors.voidDark,
        onPrimaryFixedVariant: CcColors.midnightPurple,
        secondary: CcColors.skyBlue,
        onSecondary: CcColors.voidDark,
        secondaryContainer: CcColors.infoContainer,
        onSecondaryContainer: CcColors.info,
        secondaryFixed: CcColors.paleBlue,
        secondaryFixedDim: CcColors.info,
        onSecondaryFixed: CcColors.voidDark,
        onSecondaryFixedVariant: CcColors.deepNight,
        tertiary: CcColors.nebulaPink,
        onTertiary: CcColors.voidDark,
        tertiaryContainer: CcColors.magentaContainer,
        onTertiaryContainer: CcColors.onMagentaContainer,
        tertiaryFixed: const Color(0xFFF6D9FF),
        tertiaryFixedDim: CcColors.onMagentaContainer,
        onTertiaryFixed: CcColors.voidDark,
        onTertiaryFixedVariant: CcColors.magentaContainer,
        error: CcColors.danger,
        onError: CcColors.voidDark,
        errorContainer: CcColors.dangerContainer,
        onErrorContainer: CcColors.danger,
        surface: CcColors.spaceBlack,
        onSurface: CcColors.starWhite,
        surfaceDim: CcColors.voidDark,
        surfaceBright: CcColors.raisedSurface,
        surfaceContainerLowest: CcColors.voidDark,
        surfaceContainerLow: CcColors.deepNight,
        surfaceContainer: CcColors.midnightPurple,
        surfaceContainerHigh: CcColors.nebulaSurface,
        surfaceContainerHighest: CcColors.raisedSurface,
        onSurfaceVariant: CcColors.secondaryText,
        outline: CcColors.mutedText,
        outlineVariant: CcElevation.subtleDarkBorder,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: CcColors.starWhite,
        onInverseSurface: CcColors.deepNight,
        inversePrimary: CcColors.lightPrimary,
        surfaceTint: CcColors.skyBright,
      );

  static ColorScheme _lightScheme() =>
      ColorScheme.fromSeed(
        seedColor: AppColors.lightSeed,
        brightness: Brightness.light,
      ).copyWith(
        primary: CcColors.skyBlue,
        onPrimary: CcColors.inkBlack,
        primaryContainer: CcColors.paleViolet,
        onPrimaryContainer: CcColors.inkIndigo,
        primaryFixed: CcColors.paleViolet,
        primaryFixedDim: CcColors.softLavender,
        onPrimaryFixed: CcColors.voidDark,
        onPrimaryFixedVariant: CcColors.midnightPurple,
        secondary: CcColors.lightLink,
        onSecondary: Colors.white,
        secondaryContainer: CcColors.paleBlue,
        onSecondaryContainer: CcColors.inkIndigo,
        secondaryFixed: CcColors.paleBlue,
        secondaryFixedDim: CcColors.info,
        onSecondaryFixed: CcColors.voidDark,
        onSecondaryFixedVariant: CcColors.deepNight,
        tertiary: const Color(0xFF8B2DA0),
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFF6D9FF),
        onTertiaryContainer: CcColors.inkIndigo,
        tertiaryFixed: const Color(0xFFF6D9FF),
        tertiaryFixedDim: CcColors.onMagentaContainer,
        onTertiaryFixed: CcColors.voidDark,
        onTertiaryFixedVariant: CcColors.magentaContainer,
        error: CcColors.lightDanger,
        onError: Colors.white,
        errorContainer: CcColors.lightDangerContainer,
        onErrorContainer: const Color(0xFF410002),
        surface: CcColors.pearlCanvas,
        onSurface: CcColors.inkIndigo,
        surfaceDim: CcColors.lavenderMist,
        surfaceBright: CcColors.raisedPearl,
        surfaceContainerLowest: CcColors.raisedPearl,
        surfaceContainerLow: CcColors.cloudSurface,
        surfaceContainer: CcColors.lavenderMist,
        surfaceContainerHigh: const Color(0xFFEAE5F3),
        surfaceContainerHighest: const Color(0xFFE3DEEC),
        onSurfaceVariant: CcColors.secondaryInk,
        outline: CcColors.mutedInk,
        outlineVariant: CcElevation.subtleLightBorder,
        shadow: const Color(0xFF285F80),
        scrim: const Color(0xFF06131C),
        inverseSurface: CcColors.inkIndigo,
        onInverseSurface: CcColors.cloudSurface,
        inversePrimary: CcColors.softLavender,
        surfaceTint: CcColors.skyBlue,
      );
}
