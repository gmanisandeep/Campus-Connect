import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/networking/connectivity_service.dart';
import 'package:campus_connect/core/theme/app_tokens.dart';
import 'package:campus_connect/features/academics/domain/academic_access.dart';
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
    final destinations = [
      const _Destination('/home', 'Home', Icons.home_outlined),
      if (config.hasBackendConfiguration &&
          !config.enableDemoSession &&
          canViewAcademics(session.activeGrant))
        const _Destination('/academics', 'Academics', Icons.school_outlined),
      const _Destination('/profile', 'Profile', Icons.person_outline),
    ];
    final index = destinations.indexWhere(
      (item) => item.path == location || location.startsWith('${item.path}/'),
    );
    final connectivity = ref.watch(connectivityProvider);
    final isOffline = connectivity.valueOrNull == NetworkStatus.offline;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppBreakpoints.navigationRail;
        final content = Column(
          children: [
            if (isOffline)
              const MaterialBanner(
                content: Text('Offline - some information may be out of date.'),
                actions: [SizedBox.shrink()],
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

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: index < 0 ? 0 : index,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (selected) =>
                      context.go(destinations[selected].path),
                  destinations: [
                    for (final item in destinations)
                      NavigationRailDestination(
                        icon: Icon(item.icon),
                        label: Text(item.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: index < 0 ? 0 : index,
            onDestinationSelected: (selected) =>
                context.go(destinations[selected].path),
            destinations: [
              for (final item in destinations)
                NavigationDestination(icon: Icon(item.icon), label: item.label),
            ],
          ),
        );
      },
    );
  }
}

class _Destination {
  const _Destination(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;
}
