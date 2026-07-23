import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/theme/app_tokens.dart';
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
    final academicsAvailable =
        config.hasBackendConfiguration &&
        !config.enableDemoSession &&
        canViewAcademics(session.activeGrant);
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(title: Text('${role?.label ?? 'Campus'} home')),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList.list(
            children: [
              const StatusBadge(
                label: 'Identity connected',
                status: AppStatus.success,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Your verified campus access is ready.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                academicsAvailable
                    ? isStudent
                          ? "Today's timetable and your attendance summary are "
                                'ready.'
                          : 'Your assigned classes and attendance roster are '
                                'ready.'
                    : 'Available campus modules are based on your active role.',
              ),
              const SizedBox(height: AppSpacing.lg),
              if (academicsAvailable) ...[
                _HomeActionCard(
                  icon: Icons.calendar_today_outlined,
                  title: isStudent ? "Today's timetable" : "Today's classes",
                  description: isStudent
                      ? 'Open your live schedule for today.'
                      : 'Open assigned classes and their rosters.',
                  onTap: () => context.go('/academics'),
                ),
                _HomeActionCard(
                  icon: Icons.fact_check_outlined,
                  title: isStudent ? 'Attendance summary' : 'Fast attendance',
                  description: isStudent
                      ? 'Review attendance across your subjects.'
                      : session.can(AppPermission.attendanceRecord)
                      ? 'Record attendance for an assigned class.'
                      : 'Review class rosters in read-only mode.',
                  onTap: () => context.go('/academics'),
                ),
              ] else
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.lock_outline),
                    title: Text('No additional modules enabled'),
                    subtitle: Text(
                      'Your institution can enable modules for this role.',
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

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
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
  Widget build(BuildContext context) => Card(
    child: ListTile(
      minVerticalPadding: AppSpacing.md,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
