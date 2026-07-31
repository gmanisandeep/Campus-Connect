import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_data_display.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_feedback.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_surface.dart';
import 'package:campus_connect/core/widgets/status_badge.dart';
import 'package:campus_connect/features/academics/domain/academic_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final config = ref.watch(appConfigProvider);
    final role = session.activeRole;
    final isStudent = role == AppRole.student;
    final isFaculty = role == AppRole.faculty;
    final academicsAvailable =
        config.hasBackendConfiguration &&
        !config.enableDemoSession &&
        canViewAcademics(session.activeGrant);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            CcSpacing.md,
            CcSpacing.xl,
            CcSpacing.md,
            CcSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: _HomeHero(
              displayName: session.displayName,
              role: role,
              academicsAvailable: academicsAvailable,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            CcSpacing.md,
            0,
            CcSpacing.md,
            CcSpacing.xl,
          ),
          sliver: SliverList.list(
            children: [
              CcSectionHeader(
                title: isFaculty ? 'Teaching overview' : 'Your campus day',
                supportingText: academicsAvailable
                    ? isStudent
                          ? 'Open the authoritative timetable and attendance '
                                'information available to your account.'
                          : 'Open assigned classes, rosters, and attendance '
                                'tools for your verified faculty access.'
                    : 'Only modules enabled for your verified role appear here.',
              ),
              const SizedBox(height: CcSpacing.md),
              if (academicsAvailable)
                CcSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _HomeActionRow(
                        icon: Icons.calendar_month_outlined,
                        title: isStudent
                            ? "Today's timetable"
                            : "Today's classes",
                        description: isStudent
                            ? 'View the live schedule returned by your campus.'
                            : 'View assigned classes and their current rosters.',
                        onTap: () => context.go('/academics'),
                      ),
                      const Divider(),
                      _HomeActionRow(
                        icon: Icons.fact_check_outlined,
                        title: isStudent
                            ? 'Attendance summary'
                            : 'Attendance workspace',
                        description: isStudent
                            ? 'Review the attendance totals supplied for your '
                                  'subjects.'
                            : session.can(AppPermission.attendanceRecord)
                            ? 'Record attendance through the verified class '
                                  'workflow.'
                            : 'Review assigned class rosters in read-only mode.',
                        onTap: () => context.go('/academics'),
                      ),
                    ],
                  ),
                )
              else
                const CcInlineMessage(
                  message:
                      'No additional modules are enabled for this access yet. '
                      'Your institution controls which verified tools appear.',
                  tone: CcMessageTone.info,
                ),
              const SizedBox(height: CcSpacing.xl),
              const CcSectionHeader(title: 'Access status'),
              const SizedBox(height: CcSpacing.md),
              CcSurface(
                variant: CcSurfaceVariant.glass,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CcIconTile(
                      icon: Icons.verified_user_outlined,
                      semanticLabel: 'Verified campus identity',
                    ),
                    const SizedBox(width: CcSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.activeGrant?.institutionName ??
                                'Campus access',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: CcSpacing.xxs),
                          Text(
                            isFaculty
                                ? 'Faculty permissions are applied to every '
                                      'available action.'
                                : 'Your active membership determines the data '
                                      'and tools you can open.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: context.ccTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.displayName,
    required this.role,
    required this.academicsAvailable,
  });

  final String? displayName;
  final AppRole? role;
  final bool academicsAvailable;

  @override
  Widget build(BuildContext context) {
    final roleLabel = role?.label ?? 'Campus';
    final name = displayName?.trim();
    final title = name == null || name.isEmpty
        ? '$roleLabel home'
        : 'Hello, $name';

    return Semantics(
      container: true,
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusBadge(
            label: 'Identity connected',
            status: AppStatus.success,
          ),
          const SizedBox(height: CcSpacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              title,
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          const SizedBox(height: CcSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              academicsAvailable
                  ? 'The work available here is scoped to your verified '
                        '$roleLabel access.'
                  : 'CampusConnect will show only complete, institution-enabled '
                        'tools for your verified access.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.ccTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActionRow extends StatelessWidget {
  const _HomeActionRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minVerticalPadding: CcSpacing.md,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: CcSpacing.md,
      vertical: CcSpacing.xs,
    ),
    leading: CcIconTile(icon: icon),
    title: Text(title),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: CcSpacing.xxs),
      child: Text(description),
    ),
    trailing: const Icon(Icons.arrow_forward_rounded),
    onTap: onTap,
  );
}
