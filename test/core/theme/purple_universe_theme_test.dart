import 'dart:math' as math;

import 'package:campus_connect/core/theme/app_theme.dart';
import 'package:campus_connect/core/theme/app_tokens.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_colors.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_gradients.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_motion.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_radius.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:campus_connect/core/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Purple Universe foundations', () {
    test('exposes the approved core palette and gradient stops', () {
      expect(CcColors.voidDark, const Color(0xFF05030B));
      expect(CcColors.electricPurple, const Color(0xFF8B5CF6));
      expect(CcColors.neonCyan, const Color(0xFF36E4FF));
      expect(CcColors.pearlCanvas, const Color(0xFFF7F5FC));
      expect(CcGradients.purpleCore.colors, const [
        Color(0xFF5B21B6),
        Color(0xFF7C3AED),
        Color(0xFFA855F7),
      ]);
    });

    test('keeps compatibility tokens mapped to the semantic scale', () {
      expect(AppSpacing.md, CcSpacing.md);
      expect(AppSpacing.xxl, CcSpacing.xxxl);
      expect(AppRadius.control, CcRadius.control);
      expect(AppRadius.card, CcRadius.card);
      expect(AppColors.darkSeed, CcColors.electricPurple);
      expect(AppColors.lightSeed, CcColors.lightPrimary);
    });

    test('centralizes motion durations, curves, and stable springs', () {
      expect(CcMotionDurations.instant, const Duration(milliseconds: 80));
      expect(CcMotionDurations.standard, const Duration(milliseconds: 220));
      expect(CcMotionDurations.expressive, const Duration(milliseconds: 450));
      expect(CcMotionDurations.shortLoop, const Duration(milliseconds: 1600));
      expect(CcMotionDurations.ambient, const Duration(seconds: 12));
      expect(CcMotionCurves.standard, const Cubic(0.20, 0.00, 0.00, 1.00));
      expect(CcMotionCurves.ambient, Curves.easeInOutSine);
      expect(CcMotionSprings.spring.mass, 1);
      expect(CcMotionSprings.spring.stiffness, 520);
      expect(_dampingRatio(CcMotionSprings.spring), closeTo(0.82, 0.001));
      expect(CcMotionSprings.softSpring.stiffness, 300);
      expect(_dampingRatio(CcMotionSprings.softSpring), closeTo(0.95, 0.001));
    });
  });

  group('AppTheme', () {
    test('installs intentional dark and light Purple Universe themes', () {
      final dark = AppTheme.dark();
      final light = AppTheme.light();
      final darkExtension = dark.extension<CcThemeExtension>();
      final lightExtension = light.extension<CcThemeExtension>();

      expect(dark.brightness, Brightness.dark);
      expect(dark.scaffoldBackgroundColor, CcColors.spaceBlack);
      expect(dark.colorScheme.primary, CcColors.electricPurple);
      expect(dark.colorScheme.secondary, CcColors.neonCyan);
      expect(dark.colorScheme.onSurface, CcColors.starWhite);
      expect(dark.colorScheme.surfaceDim, CcColors.voidDark);
      expect(dark.textTheme.displayMedium?.fontSize, 34);
      expect(dark.textTheme.displayMedium?.fontWeight, FontWeight.w700);
      expect(dark.textTheme.headlineSmall?.fontSize, 22);
      expect(dark.textTheme.headlineSmall?.fontWeight, FontWeight.w600);
      expect(dark.textTheme.bodyMedium?.fontSize, 14);
      expect(dark.textTheme.bodyMedium?.fontWeight, FontWeight.w400);
      expect(darkExtension, isNotNull);
      expect(darkExtension!.surface, CcColors.nebulaSurface);
      expect(darkExtension.backgroundGradient, CcGradients.deepSpace);

      expect(light.brightness, Brightness.light);
      expect(light.scaffoldBackgroundColor, CcColors.pearlCanvas);
      expect(light.colorScheme.primary, CcColors.lightPrimary);
      expect(light.colorScheme.onSurface, CcColors.inkIndigo);
      expect(light.colorScheme.surfaceBright, CcColors.raisedPearl);
      expect(lightExtension, isNotNull);
      expect(lightExtension!.surface, CcColors.cloudSurface);
      expect(lightExtension.backgroundGradient, CcGradients.pearlHorizon);
    });

    test('provides readable critical foreground and background pairs', () {
      final dark = AppTheme.dark().colorScheme;
      final light = AppTheme.light().colorScheme;

      expect(
        _contrast(dark.onSurface, dark.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(dark.onPrimary, dark.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(dark.onSecondary, dark.secondary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(dark.error, dark.errorContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(CcColors.secondaryText, CcColors.spaceBlack),
        greaterThanOrEqualTo(4.5),
      );

      expect(
        _contrast(light.onSurface, light.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(light.onPrimary, light.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(light.onSecondary, light.secondary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(CcColors.secondaryInk, CcColors.pearlCanvas),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('provides accessible semantic, control, and active roles', () {
      for (final theme in [AppTheme.dark(), AppTheme.light()]) {
        final scheme = theme.colorScheme;
        final extension = theme.extension<CcThemeExtension>()!;

        expect(
          _contrast(extension.controlBorder, extension.raisedSurface),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contrast(scheme.onPrimaryContainer, extension.surface),
          greaterThanOrEqualTo(4.5),
        );
        for (final pair in [
          (extension.success, extension.successContainer),
          (extension.warning, extension.warningContainer),
          (extension.danger, extension.dangerContainer),
          (extension.info, extension.infoContainer),
        ]) {
          expect(_contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
        }
      }
    });

    testWidgets('exposes the typed theme extension through BuildContext', (
      tester,
    ) async {
      late CcThemeExtension extension;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              extension = context.ccTheme;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(extension.canvas, CcColors.pearlCanvas);
      expect(extension.heroGradient, CcGradients.cyanViolet);
    });

    testWidgets('status badges consume typed semantic color pairs', (
      tester,
    ) async {
      for (final theme in [AppTheme.dark(), AppTheme.light()]) {
        final extension = theme.extension<CcThemeExtension>()!;
        final cases = [
          (
            status: AppStatus.success,
            background: extension.successContainer,
            foreground: extension.success,
          ),
          (
            status: AppStatus.warning,
            background: extension.warningContainer,
            foreground: extension.warning,
          ),
          (
            status: AppStatus.danger,
            background: extension.dangerContainer,
            foreground: extension.danger,
          ),
        ];

        for (final badgeCase in cases) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              themeAnimationDuration: Duration.zero,
              home: Scaffold(
                body: StatusBadge(label: 'State', status: badgeCase.status),
              ),
            ),
          );

          final chip = tester.widget<Chip>(find.byType(Chip));
          final icon = chip.avatar! as Icon;
          expect(chip.backgroundColor, badgeCase.background);
          expect(chip.labelStyle?.color, badgeCase.foreground);
          expect(icon.color, badgeCase.foreground);
        }
      }
    });
  });
}

double _dampingRatio(SpringDescription spring) =>
    spring.damping / (2 * math.sqrt(spring.mass * spring.stiffness));

double _contrast(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
