import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/routing/app_router.dart';
import 'package:campus_connect/core/theme/app_theme.dart';
import 'package:campus_connect/core/theme/theme_controller.dart';
import 'package:campus_connect/features/academics/presentation/controllers/attendance_draft_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CampusConnectApp extends ConsumerWidget {
  const CampusConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Keep encrypted attendance lifecycle cleanup active even after leaving the
    // academics tab, including sign-out and password-recovery transitions.
    ref.watch(attendanceDraftControllerProvider);

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: !config.isProduction,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
