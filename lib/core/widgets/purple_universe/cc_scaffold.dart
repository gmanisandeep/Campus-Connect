import 'dart:math' as math;

import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_ambient_background.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_data_display.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_surface.dart';
import 'package:flutter/material.dart';

class CcScaffold extends StatelessWidget {
  const CcScaffold({
    required this.body,
    this.ambientTone = CcAmbientTone.calm,
    this.appBar,
    this.bottomNavigationBar,
    this.useSafeArea = true,
    this.extendBody = false,
    this.resizeToAvoidBottomInset = true,
    super.key,
  });

  final Widget body;
  final CcAmbientTone ambientTone;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool useSafeArea;
  final bool extendBody;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    extendBody: extendBody,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    appBar: appBar,
    bottomNavigationBar: bottomNavigationBar,
    body: CcAmbientBackground(
      tone: ambientTone,
      child: useSafeArea ? SafeArea(child: body) : body,
    ),
  );
}

class CcAuthScaffold extends StatelessWidget {
  const CcAuthScaffold({
    required this.heroTitle,
    required this.heroDescription,
    required this.child,
    this.panelTitle,
    this.panelDescription,
    this.leading,
    this.ambientTone = CcAmbientTone.immersive,
    this.panelKey,
    super.key,
  });

  final String heroTitle;
  final String heroDescription;
  final String? panelTitle;
  final String? panelDescription;
  final Widget child;
  final Widget? leading;
  final CcAmbientTone ambientTone;
  final Key? panelKey;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final textScale = mediaQuery.textScaler.scale(1);

    return CcScaffold(
      ambientTone: mediaQuery.size.width < 600
          ? CcAmbientTone.quiet
          : ambientTone,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= 900 &&
              constraints.maxHeight >= 620 &&
              !keyboardOpen;
          final compactHero =
              constraints.maxWidth < 600 ||
              keyboardOpen ||
              constraints.maxHeight < 620 ||
              textScale > 1.35;
          final gutter = constraints.maxWidth >= 600
              ? CcSpacing.xl
              : CcSpacing.md;
          final contentPadding = EdgeInsets.fromLTRB(
            gutter,
            compactHero ? CcSpacing.sm : CcSpacing.lg,
            gutter,
            CcSpacing.lg,
          );
          final availableHeight = math.max(
            0.0,
            constraints.maxHeight - contentPadding.vertical,
          );

          final hero = _CcAuthHero(
            title: heroTitle,
            description: heroDescription,
            compact: compactHero,
            leading: leading,
          );
          final panel = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CcSurface(
              key: panelKey,
              variant: CcSurfaceVariant.base,
              padding: EdgeInsets.all(
                constraints.maxWidth < 360 ? CcSpacing.md : CcSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (panelTitle != null) ...[
                    Text(
                      panelTitle!,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (panelDescription != null) ...[
                      const SizedBox(height: CcSpacing.xs),
                      Text(
                        panelDescription!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.ccTheme.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: CcSpacing.lg),
                  ],
                  child,
                ],
              ),
            ),
          );

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: contentPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: availableHeight),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: hero),
                        const SizedBox(width: CcSpacing.xxxl),
                        Flexible(child: panel),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        hero,
                        SizedBox(
                          height: compactHero ? CcSpacing.md : CcSpacing.xl,
                        ),
                        Align(alignment: Alignment.topCenter, child: panel),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _CcAuthHero extends StatelessWidget {
  const _CcAuthHero({
    required this.title,
    required this.description,
    required this.compact,
    required this.leading,
  });

  final String title;
  final String description;
  final bool compact;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (leading != null) ...[
        SizedBox(width: 48, height: 48, child: leading),
        const SizedBox(height: CcSpacing.sm),
      ],
      CcBrandLockup(compact: compact),
      if (!compact) ...[
        const SizedBox(height: CcSpacing.xl),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(title, style: Theme.of(context).textTheme.displayMedium),
        ),
        const SizedBox(height: CcSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.ccTheme.textSecondary,
            ),
          ),
        ),
      ],
    ],
  );
}
