import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/networking/connectivity_service.dart';
import 'package:campus_connect/core/theme/app_tokens.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_radius.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_ambient_background.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_data_display.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_feedback.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_navigation.dart';
import 'package:campus_connect/features/academics/domain/academic_access.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RoleAwareShell extends ConsumerWidget {
  const RoleAwareShell({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final session = ref.watch(sessionControllerProvider);
    final isFaculty = session.activeRole == AppRole.faculty;
    final destinations = [
      const _Destination(
        '/home',
        'Home',
        Icons.home_outlined,
        Icons.home_rounded,
      ),
      if (config.hasBackendConfiguration &&
          !config.enableDemoSession &&
          canViewAcademics(session.activeGrant))
        _Destination(
          '/academics',
          isFaculty ? 'Teaching' : 'Academics',
          Icons.school_outlined,
          Icons.school_rounded,
        ),
      if (config.hasBackendConfiguration && !config.enableDemoSession)
        const _Destination(
          '/social',
          'Social',
          Icons.forum_outlined,
          Icons.forum_rounded,
        ),
      if (kIsWeb && session.can(AppPermission.institutionManage))
        const _Destination(
          '/college-admin',
          'College Console',
          Icons.how_to_reg_outlined,
          Icons.how_to_reg_rounded,
        ),
      const _Destination(
        '/profile',
        'Profile',
        Icons.person_outline_rounded,
        Icons.person_rounded,
      ),
    ];
    final index = destinations.indexWhere(
      (item) => item.path == location || location.startsWith('${item.path}/'),
    );
    final selectedIndex = index < 0 ? 0 : index;
    final connectivity = ref.watch(connectivityProvider);
    final isOffline = connectivity.valueOrNull == NetworkStatus.offline;
    final items = [
      for (final destination in destinations)
        CcNavigationItem(
          label: destination.label,
          icon: destination.icon,
          selectedIcon: destination.selectedIcon,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppBreakpoints.navigationRail;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final extendedRail = constraints.maxWidth >= 960 && textScale < 1.4;
        final content = Column(
          children: [
            if (!wide)
              _CampusContextBar(
                institutionName: session.activeGrant?.institutionName,
                roleLabel: session.activeRole?.label,
              ),
            if (isOffline)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  CcSpacing.md,
                  CcSpacing.xs,
                  CcSpacing.md,
                  0,
                ),
                child: CcInlineMessage(
                  message: 'Offline - some information may be out of date.',
                  tone: CcMessageTone.warning,
                  liveRegion: true,
                ),
              ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.maxContentWidth,
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        );

        return Scaffold(
          backgroundColor: Colors.transparent,
          bottomNavigationBar: wide
              ? null
              : CcNavigationBar(
                  items: items,
                  selectedIndex: selectedIndex,
                  onSelected: (selected) =>
                      context.go(destinations[selected].path),
                ),
          body: CcAmbientBackground(
            tone: CcAmbientTone.quiet,
            child: SafeArea(
              bottom: false,
              child: wide
                  ? Row(
                      children: [
                        CcNavigationRail(
                          items: items,
                          selectedIndex: selectedIndex,
                          extended: extendedRail,
                          onSelected: (selected) =>
                              context.go(destinations[selected].path),
                          leading: _RailIdentity(
                            institutionName:
                                session.activeGrant?.institutionName,
                            roleLabel: session.activeRole?.label,
                            extended: extendedRail,
                          ),
                        ),
                        Expanded(child: content),
                      ],
                    )
                  : content,
            ),
          ),
        );
      },
    );
  }
}

class _CampusContextBar extends StatelessWidget {
  const _CampusContextBar({
    required this.institutionName,
    required this.roleLabel,
  });

  final String? institutionName;
  final String? roleLabel;

  @override
  Widget build(BuildContext context) {
    final institution = institutionName ?? 'Campus access';
    final role = roleLabel ?? 'Member';

    return Semantics(
      container: true,
      label: 'Active campus $institution, role $role',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              CcSpacing.md,
              CcSpacing.sm,
              CcSpacing.md,
              CcSpacing.xs,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: CcSpacing.md,
                vertical: CcSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: context.ccTheme.raisedSurface,
                borderRadius: BorderRadius.circular(CcRadius.capsule),
                boxShadow: context.ccTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.apartment_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: CcSpacing.xs),
                  Expanded(
                    child: Text(
                      institution,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: CcSpacing.sm),
                  Text(
                    role,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
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
}

class _RailIdentity extends StatelessWidget {
  const _RailIdentity({
    required this.institutionName,
    required this.roleLabel,
    required this.extended,
  });

  final String? institutionName;
  final String? roleLabel;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    if (!extended) {
      return Tooltip(
        message:
            '${institutionName ?? 'Campus access'} - ${roleLabel ?? 'Member'}',
        child: const Icon(Icons.hub_rounded, size: 28),
      );
    }

    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CcBrandLockup(compact: true),
          const SizedBox(height: CcSpacing.md),
          Text(
            institutionName ?? 'Campus access',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: CcSpacing.xxs),
          Text(
            roleLabel ?? 'Member',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
