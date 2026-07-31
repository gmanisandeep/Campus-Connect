import 'dart:async';

import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/core/theme/app_tokens.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_button.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_feedback.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_scaffold.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_surface.dart';
import 'package:campus_connect/features/identity/presentation/controllers/identity_action_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final identity = session.identity;
    if (identity == null) return const SizedBox.shrink();

    final child = session.status == SessionStatus.selectionRequired
        ? _AccessSelection(grants: identity.activeGrants)
        : identity.activeGrants.isNotEmpty && !identity.profileCompleted
        ? _ProfileCompletion(initialDisplayName: identity.displayName)
        : identity.acceptableInvitations.isNotEmpty
        ? _InvitationCompletion(
            invitations: identity.acceptableInvitations,
            initialDisplayName: identity.displayName,
            requirePassword: identity.activeGrants.isEmpty,
            allowCancel: identity.activeGrants.isNotEmpty,
          )
        : const _OnboardingUnavailable();

    return CcAuthScaffold(
      heroTitle: 'Your campus identity, confirmed.',
      heroDescription:
          'Finish the details required by your institution, then choose the '
          'verified access you want to use.',
      child: child,
    );
  }
}

class _AccessSelection extends ConsumerWidget {
  const _AccessSelection({required this.grants});

  final List<AccessGrant> grants;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Choose your campus access',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: AppSpacing.sm),
      const Text(
        'Your choices come from active memberships assigned by your '
        'institution.',
      ),
      const SizedBox(height: AppSpacing.lg),
      for (final grant in grants)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: CcSurface(
            variant: CcSurfaceVariant.outlined,
            padding: EdgeInsets.zero,
            child: ListTile(
              key: Key('access-${grant.selectionKey}'),
              leading: const Icon(Icons.badge_outlined),
              title: Text(grant.institutionName),
              subtitle: Text(grant.role.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => unawaited(
                ref
                    .read(sessionControllerProvider.notifier)
                    .selectAccess(grant.institutionId, grant.role),
              ),
            ),
          ),
        ),
    ],
  );
}

class _ProfileCompletion extends ConsumerStatefulWidget {
  const _ProfileCompletion({this.initialDisplayName});

  final String? initialDisplayName;

  @override
  ConsumerState<_ProfileCompletion> createState() => _ProfileCompletionState();
}

class _ProfileCompletionState extends ConsumerState<_ProfileCompletion> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialDisplayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(identityActionControllerProvider);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Complete your profile',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text('Confirm the name your campus should display.'),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              labelText: 'Display name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: _validateName,
          ),
          _ActionError(action: action),
          const SizedBox(height: AppSpacing.lg),
          CcPrimaryButton(
            label: 'Continue',
            isLoading: action.isLoading,
            onPressed: action.isLoading ? null : _submit,
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    unawaited(
      ref
          .read(identityActionControllerProvider.notifier)
          .completeProfile(_nameController.text),
    );
  }
}

class _InvitationCompletion extends ConsumerStatefulWidget {
  const _InvitationCompletion({
    required this.invitations,
    required this.requirePassword,
    required this.allowCancel,
    this.initialDisplayName,
  });

  final List<MembershipSummary> invitations;
  final bool requirePassword;
  final bool allowCancel;
  final String? initialDisplayName;

  @override
  ConsumerState<_InvitationCompletion> createState() =>
      _InvitationCompletionState();
}

class _InvitationCompletionState extends ConsumerState<_InvitationCompletion> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  late String _membershipId;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialDisplayName);
    _membershipId = widget.invitations.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(identityActionControllerProvider);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Accept your invitation',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.requirePassword
                ? 'Set your profile and password to activate the institution '
                      'membership already assigned to you.'
                : 'Confirm your profile to add the institution membership '
                      'already assigned to you.',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (widget.invitations.length > 1) ...[
            DropdownButtonFormField<String>(
              initialValue: _membershipId,
              decoration: const InputDecoration(labelText: 'Institution'),
              items: [
                for (final invitation in widget.invitations)
                  DropdownMenuItem(
                    value: invitation.id,
                    child: Text(invitation.institutionName),
                  ),
              ],
              onChanged: action.isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _membershipId = value);
                      }
                    },
            ),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.apartment_outlined),
              title: Text(widget.invitations.single.institutionName),
              subtitle: Text(
                widget.invitations.single.grants
                    .map((grant) => grant.role.label)
                    .join(', '),
              ),
            ),
          ],
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              labelText: 'Display name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: _validateName,
          ),
          if (widget.requirePassword) ...[
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Create password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => (value?.length ?? 0) < 8
                  ? 'Use at least 8 characters.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _confirmationController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              validator: (value) => value != _passwordController.text
                  ? 'Passwords do not match.'
                  : null,
            ),
          ],
          _ActionError(action: action),
          const SizedBox(height: AppSpacing.lg),
          CcPrimaryButton(
            label: 'Accept invitation',
            isLoading: action.isLoading,
            onPressed: action.isLoading ? null : _submit,
          ),
          if (widget.allowCancel) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: action.isLoading
                  ? null
                  : () => unawaited(
                      ref
                          .read(sessionControllerProvider.notifier)
                          .cancelInvitationAcceptance(),
                    ),
              child: const Text('Not now'),
            ),
          ],
        ],
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    TextInput.finishAutofillContext();
    unawaited(
      ref
          .read(identityActionControllerProvider.notifier)
          .acceptInvitation(
            membershipId: _membershipId,
            displayName: _nameController.text,
            password: widget.requirePassword ? _passwordController.text : null,
          ),
    );
  }
}

class _ActionError extends StatelessWidget {
  const _ActionError({required this.action});

  final AsyncValue<void> action;

  @override
  Widget build(BuildContext context) {
    final message = action.whenOrNull(
      error: (error, _) => error is AppFailure
          ? error.message
          : 'Unable to finish setup right now.',
    );
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: CcInlineMessage(
        message: message,
        tone: CcMessageTone.danger,
        liveRegion: true,
      ),
    );
  }
}

class _OnboardingUnavailable extends StatelessWidget {
  const _OnboardingUnavailable();

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.info_outline, size: 48),
      SizedBox(height: AppSpacing.md),
      Text(
        'No invitation or active access is available. Try restoring your '
        'session or contact an authorized campus administrator.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}

String? _validateName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Enter your display name.';
  if (name.length > 120) return 'Use 120 characters or fewer.';
  return null;
}
