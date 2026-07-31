import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:campus_connect/core/widgets/app_search_field.dart';
import 'package:campus_connect/core/widgets/async_state_views.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_ambient_background.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_button.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_data_display.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_feedback.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_scaffold.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_surface.dart';
import 'package:campus_connect/core/widgets/status_badge.dart';
import 'package:campus_connect/features/foundation/presentation/widgets/feature_blueprint_section.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DesignSystemGalleryPage extends StatelessWidget {
  const DesignSystemGalleryPage({super.key});

  @override
  Widget build(BuildContext context) => CcScaffold(
    useSafeArea: false,
    ambientTone: CcAmbientTone.calm,
    appBar: AppBar(
      title: const Text('Purple Universe'),
      leading: IconButton(
        tooltip: 'Back to sign in',
        onPressed: () => context.go('/sign-in'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(
        CcSpacing.md,
        CcSpacing.md,
        CcSpacing.md,
        CcSpacing.xl,
      ),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CcSurface(
                  variant: CcSurfaceVariant.glass,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CcBrandLockup(),
                      const SizedBox(height: CcSpacing.xl),
                      Text(
                        'Aurora campus system',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: CcSpacing.sm),
                      Text(
                        'Code-native light fields, trustworthy task surfaces, '
                        'and adaptive Material behavior for every campus role.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: context.ccTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: CcSpacing.xl),
                _GallerySection(
                  title: 'Surfaces',
                  supportingText:
                      'Opaque by default; translucent only where hierarchy '
                      'benefits from visible atmosphere.',
                  child: Wrap(
                    spacing: CcSpacing.md,
                    runSpacing: CcSpacing.md,
                    children: const [
                      _SurfaceSpecimen(
                        label: 'Base',
                        variant: CcSurfaceVariant.base,
                      ),
                      _SurfaceSpecimen(
                        label: 'Raised',
                        variant: CcSurfaceVariant.raised,
                      ),
                      _SurfaceSpecimen(
                        label: 'Glass',
                        variant: CcSurfaceVariant.glass,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: CcSpacing.xl),
                _GallerySection(
                  title: 'Actions',
                  supportingText:
                      'Material semantics remain intact beneath the visual '
                      'language.',
                  child: Wrap(
                    spacing: CcSpacing.sm,
                    runSpacing: CcSpacing.sm,
                    children: [
                      CcPrimaryButton(
                        label: 'Primary action',
                        expand: false,
                        onPressed: () =>
                            _acknowledge(context, 'Primary action'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _acknowledge(context, 'Tonal action'),
                        child: const Text('Tonal action'),
                      ),
                      OutlinedButton(
                        onPressed: () => _acknowledge(context, 'Alternative'),
                        child: const Text('Alternative'),
                      ),
                      TextButton(
                        onPressed: () => _acknowledge(context, 'Text action'),
                        child: const Text('Text action'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: CcSpacing.xl),
                _GallerySection(
                  title: 'Input',
                  child: AppSearchField(
                    hint: 'Search campus',
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(height: CcSpacing.xl),
                const _GallerySection(
                  title: 'Status and feedback',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: CcSpacing.xs,
                        runSpacing: CcSpacing.xs,
                        children: [
                          StatusBadge(
                            label: 'Confirmed',
                            status: AppStatus.success,
                          ),
                          StatusBadge(
                            label: 'At risk',
                            status: AppStatus.warning,
                          ),
                          StatusBadge(
                            label: 'Failed',
                            status: AppStatus.danger,
                          ),
                          StatusBadge(
                            label: 'Pending sync',
                            status: AppStatus.pending,
                          ),
                        ],
                      ),
                      SizedBox(height: CcSpacing.md),
                      CcInlineMessage(
                        message:
                            'Saved locally. This has not been submitted to the '
                            'server.',
                        tone: CcMessageTone.warning,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: CcSpacing.xl),
                const _GallerySection(
                  title: 'Loading and recovery',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSkeleton(),
                      SizedBox(height: CcSpacing.lg),
                      AppEmptyState(
                        title: 'Nothing scheduled',
                        message:
                            'Upcoming classes and events will appear here.',
                      ),
                      AppErrorState(
                        message: 'Check your connection and try again.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: CcSpacing.xl),
                const FeatureBlueprintSection(),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  static void _acknowledge(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label previewed.')));
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection({
    required this.title,
    required this.child,
    this.supportingText,
  });

  final String title;
  final String? supportingText;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CcSectionHeader(title: title, supportingText: supportingText),
      const SizedBox(height: CcSpacing.md),
      child,
    ],
  );
}

class _SurfaceSpecimen extends StatelessWidget {
  const _SurfaceSpecimen({required this.label, required this.variant});

  final String label;
  final CcSurfaceVariant variant;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: CcSurface(
      variant: variant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CcIconTile(icon: Icons.layers_outlined),
          const SizedBox(height: CcSpacing.md),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: CcSpacing.xxs),
          Text(
            'Readable content with token-driven contrast.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}
