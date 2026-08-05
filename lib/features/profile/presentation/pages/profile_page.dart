import 'dart:async';

import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:campus_connect/core/theme/theme_controller.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_data_display.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_feedback.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_surface.dart';
import 'package:campus_connect/core/widgets/status_badge.dart';
import 'package:campus_connect/features/identity/presentation/controllers/identity_action_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            CcSpacing.md,
            CcSpacing.xl,
            CcSpacing.md,
            CcSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: CcSectionHeader(
              title: 'Your campus identity',
              supportingText:
                  'Profile details and permissions come from your verified '
                  'institution access.',
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
              _CampusIdCard(
                displayName: session.displayName,
                activeGrant: activeGrant,
                onOpenPublicProfile: () => context.go('/social?section=4'),
              ),
              const SizedBox(height: CcSpacing.xl),
              const CcSectionHeader(title: 'Appearance'),
              const SizedBox(height: CcSpacing.md),
              CcSurface(
                child: DropdownButtonFormField<ThemeMode>(
                  initialValue: mode,
                  decoration: const InputDecoration(
                    labelText: 'Theme',
                    prefixIcon: Icon(Icons.contrast_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeModeProvider.notifier).setMode(value);
                    }
                  },
                ),
              ),
              if (session.availableGrants.length > 1) ...[
                const SizedBox(height: CcSpacing.xl),
                const CcSectionHeader(
                  title: 'Campus access',
                  supportingText:
                      'Switch only among memberships verified for this account.',
                ),
                const SizedBox(height: CcSpacing.md),
                CcSurface(
                  child: DropdownButtonFormField<String>(
                    initialValue: activeGrant?.selectionKey,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Institution and role',
                      prefixIcon: Icon(Icons.apartment_rounded),
                    ),
                    items: [
                      for (final grant in session.availableGrants)
                        DropdownMenuItem(
                          value: grant.selectionKey,
                          child: Text(
                            _grantLabel(grant),
                            overflow: TextOverflow.ellipsis,
                          ),
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
                ),
              ],
              if (invitations.isNotEmpty) ...[
                const SizedBox(height: CcSpacing.xl),
                const CcSectionHeader(title: 'Invitations'),
                const SizedBox(height: CcSpacing.md),
                CcSurface(
                  variant: CcSurfaceVariant.glass,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        invitations.length == 1
                            ? 'Pending campus invitation'
                            : '${invitations.length} pending campus invitations',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: CcSpacing.xs),
                      Text(
                        invitations
                            .map((invitation) => invitation.institutionName)
                            .join(', '),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.ccTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: CcSpacing.md),
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
              ],
              if (actionError != null) ...[
                const SizedBox(height: CcSpacing.md),
                CcInlineMessage(
                  message: actionError,
                  tone: CcMessageTone.danger,
                  liveRegion: true,
                ),
              ],
              const SizedBox(height: CcSpacing.xl),
              const CcSectionHeader(title: 'Account'),
              const SizedBox(height: CcSpacing.md),
              CcSurface(
                variant: CcSurfaceVariant.outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sign out on this device',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: CcSpacing.xs),
                    Text(
                      'You will need to sign in again before opening campus '
                      'information.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.ccTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: CcSpacing.md),
                    OutlinedButton.icon(
                      onPressed: action.isLoading
                          ? null
                          : () => unawaited(
                              ref
                                  .read(
                                    identityActionControllerProvider.notifier,
                                  )
                                  .signOut(),
                            ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign out'),
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

  String _grantLabel(AccessGrant grant) =>
      '${grant.institutionName} - ${grant.role.label}';
}

class _CampusIdCard extends StatelessWidget {
  const _CampusIdCard({
    required this.displayName,
    required this.activeGrant,
    required this.onOpenPublicProfile,
  });

  final String? displayName;
  final AccessGrant? activeGrant;
  final VoidCallback onOpenPublicProfile;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label:
        '${displayName ?? 'Campus member'}, '
        '${activeGrant?.institutionName ?? 'No active campus access'}, '
        '${activeGrant?.role.label ?? 'No active role'}',
    child: ExcludeSemantics(
      child: CcSurface(
        variant: CcSurfaceVariant.raised,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CcIconTile(icon: Icons.badge_outlined),
                const Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: StatusBadge(
                      label: 'Verified access',
                      status: AppStatus.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CcSpacing.xl),
            Text(
              displayName ?? 'Campus member',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: CcSpacing.sm),
            Text(
              activeGrant == null
                  ? 'No active campus access'
                  : '${activeGrant!.institutionName}\n${activeGrant!.role.label}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.ccTheme.textSecondary,
              ),
            ),
            const SizedBox(height: CcSpacing.lg),
            OutlinedButton.icon(
              onPressed: onOpenPublicProfile,
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('View professional profile'),
            ),
          ],
        ),
      ),
    ),
  );
}
