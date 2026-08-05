import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_ambient_background.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_data_display.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_scaffold.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => CcScaffold(
    ambientTone: CcAmbientTone.immersive,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(CcSpacing.xl),
        child: Semantics(
          label: 'Restoring your session',
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CcBrandLockup(),
                const SizedBox(height: CcSpacing.xl),
                SizedBox(
                  width: 180,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: context.ccTheme.borderSubtle,
                  ),
                ),
                const SizedBox(height: CcSpacing.md),
                Text(
                  'Restoring your session',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.ccTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
