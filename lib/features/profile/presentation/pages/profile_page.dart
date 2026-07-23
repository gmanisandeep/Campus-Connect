import 'dart:async';

import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/core/theme/app_tokens.dart';
import 'package:campus_connect/core/theme/theme_controller.dart';
import 'package:campus_connect/features/identity/presentation/controllers/identity_action_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final mode = ref.watch(themeModeProvider);
    final action = ref.watch(identityActionControllerProvider);
    final activeGrant = session.activeGrant;
    final invitations =
        session.identity?.acceptableInvitations ?? const <MembershipSummary>[];
    final actionError = action.whenOrNull(
      error: (error, _) => error is AppFailure
          ? error.message
          : 'Unable to complete that action.',
    );

    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('Profile')),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList.list(
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(session.displayName ?? 'Campus member'),
                subtitle: Text(
                  activeGrant == null
                      ? 'No active campus access'
                      : '${activeGrant.institutionName} - '
                            '${activeGrant.role.label}',
                ),
              ),
              const Divider(),
              DropdownButtonFormField<ThemeMode>(
                initialValue: mode,
                decoration: const InputDecoration(labelText: 'Theme'),
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(themeModeProvider.notifier).setMode(value);
                  }
                },
              ),
              if (session.availableGrants.length > 1) ...[
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: activeGrant?.selectionKey,
                  decoration: const InputDecoration(
                    labelText: 'Institution and role',
                  ),
                  items: [
                    for (final grant in session.availableGrants)
                      DropdownMenuItem(
                        value: grant.selectionKey,
                        child: Text(_grantLabel(grant)),
                      ),
                  ],
                  onChanged: (selectionKey) {
                    if (selectionKey == null) return;
                    final grant = session.availableGrants.firstWhere(
                      (candidate) => candidate.selectionKey == selectionKey,
                    );
                    unawaited(
                      ref
                          .read(sessionControllerProvider.notifier)
                          .selectAccess(grant.institutionId, grant.role),
                    );
                  },
                ),
              ],
              if (invitations.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Card.outlined(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          invitations.length == 1
                              ? 'Pending campus invitation'
                              : '${invitations.length} pending campus invitations',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          invitations
                              .map((invitation) => invitation.institutionName)
                              .join(', '),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.tonalIcon(
                          onPressed: () => ref
                              .read(sessionControllerProvider.notifier)
                              .startInvitationAcceptance(),
                          icon: const Icon(Icons.mark_email_read_outlined),
                          label: const Text('Review invitations'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (actionError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  actionError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: action.isLoading
                    ? null
                    : () => unawaited(
                        ref
                            .read(identityActionControllerProvider.notifier)
                            .signOut(),
                      ),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _grantLabel(AccessGrant grant) =>
      '${grant.institutionName} - ${grant.role.label}';
}
