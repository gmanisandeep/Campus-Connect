import 'package:campus_connect/core/theme/app_tokens.dart';
import 'package:campus_connect/core/widgets/app_search_field.dart';
import 'package:campus_connect/core/widgets/async_state_views.dart';
import 'package:campus_connect/core/widgets/status_badge.dart';
import 'package:campus_connect/features/foundation/presentation/widgets/feature_blueprint_section.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DesignSystemGalleryPage extends StatelessWidget {
  const DesignSystemGalleryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Design-system gallery'),
      leading: IconButton(
        tooltip: 'Back to sign in',
        onPressed: () => context.go('/sign-in'),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Actions', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton(onPressed: () {}, child: const Text('Primary')),
            FilledButton.tonal(
              onPressed: () {},
              child: const Text('Secondary'),
            ),
            OutlinedButton(onPressed: () {}, child: const Text('Alternative')),
            TextButton(onPressed: () {}, child: const Text('Tertiary')),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSearchField(hint: 'Search campus', onChanged: (_) {}),
        const SizedBox(height: AppSpacing.lg),
        Text('Statuses', style: Theme.of(context).textTheme.headlineSmall),
        const Wrap(
          spacing: AppSpacing.xs,
          children: [
            StatusBadge(label: 'Confirmed', status: AppStatus.success),
            StatusBadge(label: 'At risk', status: AppStatus.warning),
            StatusBadge(label: 'Failed', status: AppStatus.danger),
            StatusBadge(label: 'Pending sync', status: AppStatus.pending),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Loading', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        const AppSkeleton(),
        const SizedBox(height: AppSpacing.lg),
        const AppEmptyState(
          title: 'Nothing scheduled',
          message: 'Upcoming classes and events will appear here.',
        ),
        const AppErrorState(message: 'Check your connection and try again.'),
        const SizedBox(height: AppSpacing.xl),
        const FeatureBlueprintSection(),
      ],
    ),
  );
}
