import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_colors.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_gradients.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_radius.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_data_display.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_feedback.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_surface.dart';
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
    final isAlumni = role == AppRole.alumni;
    final academicsAvailable =
        config.hasBackendConfiguration &&
        !config.enableDemoSession &&
        canViewAcademics(session.activeGrant);
    final socialAvailable =
        config.hasBackendConfiguration && !config.enableDemoSession;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            CcSpacing.md,
            CcSpacing.lg,
            CcSpacing.md,
            CcSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: _HomeHeader(
              displayName: session.displayName,
              role: role,
              institutionName: session.activeGrant?.institutionName,
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
                title: isFaculty
                    ? 'Jump back into teaching'
                    : isAlumni
                    ? 'Your alumni access'
                    : 'Jump back in',
                supportingText: isAlumni
                    ? 'Your completed programme is verified. Alumni services appear when your college enables them.'
                    : null,
              ),
              const SizedBox(height: CcSpacing.md),
              if (academicsAvailable || socialAvailable)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stack =
                        constraints.maxWidth < 520 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.3;
                    final width = stack
                        ? constraints.maxWidth
                        : (constraints.maxWidth - CcSpacing.sm) / 2;
                    return Wrap(
                      spacing: CcSpacing.sm,
                      runSpacing: CcSpacing.sm,
                      children: [
                        if (academicsAvailable)
                          SizedBox(
                            width: width,
                            child: _HomeShortcut(
                              icon: Icons.calendar_month_rounded,
                              title: isStudent
                                  ? "Today's timetable"
                                  : "Today's classes",
                              description: isStudent
                                  ? 'Schedule and attendance'
                                  : 'Classes and rosters',
                              accent: CcColors.softLilac,
                              iconColor: CcColors.royalBlue,
                              onTap: () => context.go('/academics'),
                            ),
                          ),
                        if (socialAvailable)
                          SizedBox(
                            width: width,
                            child: _HomeShortcut(
                              icon: Icons.forum_rounded,
                              title: 'Campus feed',
                              description: 'Posts and conversations',
                              accent: CcColors.softCoral,
                              iconColor: CcColors.nebulaPink,
                              onTap: () => context.go('/social'),
                            ),
                          ),
                      ],
                    );
                  },
                )
              else
                const CcInlineMessage(
                  message:
                      'No additional modules are enabled for this access yet. Your institution controls which verified tools appear.',
                  tone: CcMessageTone.info,
                ),
              const SizedBox(height: CcSpacing.xl),
              const CcSectionHeader(title: 'Campus access'),
              const SizedBox(height: CcSpacing.md),
              CcSurface(
                padding: EdgeInsets.zero,
                child: ListTile(
                  minTileHeight: 76,
                  leading: const CcIconTile(
                    icon: Icons.verified_user_outlined,
                    semanticLabel: 'Verified campus identity',
                  ),
                  title: Text(
                    session.activeGrant?.institutionName ?? 'Campus access',
                  ),
                  subtitle: Text(
                    isFaculty
                        ? 'Faculty permissions apply to every available action.'
                        : isAlumni
                        ? 'Verified graduate · Alumni access'
                        : 'Your membership controls the tools and data you can open.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.displayName,
    required this.role,
    required this.institutionName,
  });

  final String? displayName;
  final AppRole? role;
  final String? institutionName;

  @override
  Widget build(BuildContext context) {
    final roleLabel = role?.label ?? 'Member';
    final name = displayName?.trim();
    final firstName = name == null || name.isEmpty
        ? null
        : name.split(RegExp(r'\s+')).first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final title = firstName == null ? greeting : '$greeting, $firstName';

    return Semantics(
      container: true,
      header: true,
      label: '$title. $roleLabel at ${institutionName ?? 'CampusConnect'}.',
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: CcGradients.orbitBlue,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Text(
              firstName?.characters.first.toUpperCase() ?? 'C',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: CcSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: CcSpacing.xxs),
                Text(
                  '$roleLabel workspace',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.ccTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Open profile',
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _HomeShortcut extends StatelessWidget {
  const _HomeShortcut({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CcSurface(
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CcRadius.card),
      child: Padding(
        padding: const EdgeInsets.all(CcSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CcIconTile(
              icon: icon,
              semanticLabel: title,
              backgroundColor: accent,
              foregroundColor: iconColor,
            ),
            const SizedBox(height: CcSpacing.lg),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: CcSpacing.xxs),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.ccTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
