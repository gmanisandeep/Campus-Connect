import 'dart:async';

import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/theme/app_tokens.dart';
import 'package:campus_connect/features/identity/presentation/controllers/identity_action_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccessUnavailablePage extends ConsumerWidget {
  const AccessUnavailablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final action = ref.watch(identityActionControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.admin_panel_settings_outlined, size: 52),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Campus access unavailable',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _message(session.blockReason),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: action.isLoading
                            ? null
                            : () => unawaited(
                                ref
                                    .read(sessionControllerProvider.notifier)
                                    .restore(),
                              ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                      TextButton(
                        onPressed: action.isLoading
                            ? null
                            : () => unawaited(
                                ref
                                    .read(
                                      identityActionControllerProvider.notifier,
                                    )
                                    .signOut(),
                              ),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _message(AccessBlockReason? reason) => switch (reason) {
    AccessBlockReason.suspended =>
      'Your institution membership is suspended. Contact an authorized '
          'campus administrator.',
    AccessBlockReason.inactiveInstitution =>
      'This institution is currently inactive.',
    AccessBlockReason.expiredInvitation =>
      'This invitation has expired. Ask an authorized campus '
          'administrator for a new invitation.',
    AccessBlockReason.missingRole =>
      'Your active membership does not have an assigned role.',
    AccessBlockReason.unavailable =>
      'Campus access could not be verified. Check your connection and try '
          'again.',
    AccessBlockReason.noMembership ||
    null => 'No active institution membership is assigned to this account.',
  };
}
