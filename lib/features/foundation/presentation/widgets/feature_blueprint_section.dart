import 'package:campus_connect/core/product/campus_feature_catalog.dart';
import 'package:campus_connect/core/theme/app_tokens.dart';
import 'package:campus_connect/core/widgets/status_badge.dart';
import 'package:flutter/material.dart';

class FeatureBlueprintSection extends StatelessWidget {
  const FeatureBlueprintSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Role feature blueprint', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'This development view records the approved product hierarchy. '
          'Planned capabilities stay out of production navigation until their '
          'data, permissions, and complete experience are ready.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final isTwoColumn =
                constraints.maxWidth >= AppBreakpoints.navigationRail;
            final cardWidth = isTwoColumn
                ? (constraints.maxWidth - AppSpacing.md) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: const _FeatureBlueprintCard(
                    blueprint: CampusFeatureCatalog.student,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: const _FeatureBlueprintCard(
                    blueprint: CampusFeatureCatalog.faculty,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FeatureBlueprintCard extends StatelessWidget {
  const _FeatureBlueprintCard({required this.blueprint});

  final RoleFeatureBlueprint blueprint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dashboard = blueprint.dashboard;

    return Semantics(
      container: true,
      label: '${dashboard.label} feature blueprint',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dashboard.label, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(dashboard.summary, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              _DeliveryBadge(delivery: dashboard.delivery),
              const Divider(height: AppSpacing.xl),
              for (final child in dashboard.children)
                _FeatureNodeView(node: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureNodeView extends StatelessWidget {
  const _FeatureNodeView({required this.node, this.depth = 0});

  final CampusFeatureNode node;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: depth * AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  depth == 0
                      ? Icons.account_tree_outlined
                      : Icons.subdirectory_arrow_right,
                  size: 18,
                  semanticLabel: depth == 0 ? 'Feature' : 'Sub-feature',
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(node.label, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxs),
                Text(node.summary, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                _DeliveryBadge(delivery: node.delivery),
              ],
            ),
          ),
          if (node.children.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final child in node.children)
              _FeatureNodeView(node: child, depth: depth + 1),
          ],
        ],
      ),
    );
  }
}

class _DeliveryBadge extends StatelessWidget {
  const _DeliveryBadge({required this.delivery});

  final CampusFeatureDelivery delivery;

  @override
  Widget build(BuildContext context) => StatusBadge(
    label: delivery.label,
    status: switch (delivery) {
      CampusFeatureDelivery.available => AppStatus.success,
      CampusFeatureDelivery.foundation => AppStatus.pending,
      CampusFeatureDelivery.planned => AppStatus.neutral,
    },
  );
}
