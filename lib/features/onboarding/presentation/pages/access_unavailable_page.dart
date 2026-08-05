import 'dart:async';

import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_button.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_data_display.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_scaffold.dart';
import 'package:campus_connect/features/affiliation/domain/affiliation.dart';
import 'package:campus_connect/features/affiliation/presentation/controllers/affiliation_controller.dart';
import 'package:campus_connect/features/affiliation/presentation/widgets/student_affiliation_panel.dart';
import 'package:campus_connect/features/identity/presentation/controllers/identity_action_controller.dart';
import 'package:campus_connect/features/social/presentation/pages/social_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccessUnavailablePage extends ConsumerWidget {
  const AccessUnavailablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final action = ref.watch(identityActionControllerProvider);
    final canRequestAffiliation =
        session.blockReason == AccessBlockReason.noMembership &&
        session.identity != null;
    final affiliation = canRequestAffiliation
        ? ref.watch(studentAffiliationControllerProvider)
        : null;
    final request = affiliation?.valueOrNull?.request;

    if (request?.status == AffiliationRequestStatus.pending) {
      return const SocialHubPage(provisional: true);
    }

    return CcAuthScaffold(
      heroTitle: canRequestAffiliation
          ? 'Connect your college.'
          : 'Access should always be clear.',
      heroDescription: canRequestAffiliation
          ? 'Choose the institution that holds your student record, then '
                'send the details it needs to verify you.'
          : 'CampusConnect verifies institution membership before opening '
                'role-aware tools.',
      panelTitle: canRequestAffiliation
          ? 'Verify student affiliation'
          : 'Campus access unavailable',
      panelDescription: canRequestAffiliation
          ? 'Submit your details to open provisional Community access. '
                'Academic tools remain locked until college approval.'
          : _message(session.blockReason),
      child: canRequestAffiliation
          ? const StudentAffiliationPanel()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: CcIconTile(
                    icon: Icons.admin_panel_settings_outlined,
                    semanticLabel: 'Campus access status',
                  ),
                ),
                const SizedBox(height: CcSpacing.lg),
                CcPrimaryButton(
                  label: 'Try again',
                  icon: Icons.refresh_rounded,
                  isLoading: action.isLoading,
                  onPressed: action.isLoading
                      ? null
                      : () => unawaited(
                          ref
                              .read(sessionControllerProvider.notifier)
                              .restore(),
                        ),
                ),
                const SizedBox(height: CcSpacing.xs),
                TextButton(
                  onPressed: action.isLoading
                      ? null
                      : () => unawaited(
                          ref
                              .read(identityActionControllerProvider.notifier)
                              .signOut(),
                        ),
                  child: const Text('Sign out'),
                ),
              ],
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
