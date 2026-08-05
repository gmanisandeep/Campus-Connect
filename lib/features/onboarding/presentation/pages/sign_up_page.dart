import 'dart:async';

import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_button.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_data_display.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_feedback.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_scaffold.dart';
import 'package:campus_connect/features/identity/presentation/controllers/identity_action_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(signUpControllerProvider);
    final result = action.valueOrNull;
    final confirmationRequired = result?.confirmationRequired ?? false;
    final errorMessage = action.whenOrNull(
      error: (error, _) => error is AppFailure
          ? error.message
          : 'Unable to create your account right now.',
    );

    return CcAuthScaffold(
      heroTitle: 'Start with one secure account.',
      heroDescription:
          'Create your login first. Campus access appears only after an '
          'authorized administrator assigns your institution and role.',
      panelTitle: confirmationRequired ? 'Check your email' : 'Create account',
      panelDescription: confirmationRequired
          ? 'Use the confirmation link on this phone to finish creating your '
                'account.'
          : 'Use an email address you can access on this phone.',
      leading: BackButton(onPressed: () => context.go('/sign-in')),
      child: confirmationRequired
          ? _ConfirmationState(onBack: () => context.go('/sign-in'))
          : AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CcInlineMessage(
                      message:
                          'Creating an account does not assign campus access. '
                          'An administrator must add your membership and role.',
                      tone: CcMessageTone.info,
                    ),
                    const SizedBox(height: CcSpacing.md),
                    TextFormField(
                      controller: _emailController,
                      autofillHints: const [AutofillHints.newUsername],
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        hintText: 'name@campus.edu',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: CcSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      autofillHints: const [AutofillHints.newPassword],
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        helperText: 'Use at least 8 characters.',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show passwords'
                              : 'Hide passwords',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: CcSpacing.md),
                    TextFormField(
                      controller: _confirmPasswordController,
                      autofillHints: const [AutofillHints.newPassword],
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!action.isLoading) _submit();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: Icon(Icons.lock_reset_rounded),
                      ),
                      validator: (value) => value != _passwordController.text
                          ? 'Passwords do not match.'
                          : null,
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: CcSpacing.sm),
                      CcInlineMessage(
                        message: errorMessage,
                        tone: CcMessageTone.danger,
                        liveRegion: true,
                      ),
                    ],
                    const SizedBox(height: CcSpacing.lg),
                    CcPrimaryButton(
                      label: 'Create account',
                      isLoading: action.isLoading,
                      onPressed: action.isLoading ? null : _submit,
                    ),
                    const SizedBox(height: CcSpacing.xs),
                    TextButton(
                      onPressed: action.isLoading
                          ? null
                          : () => context.go('/sign-in'),
                      child: const Text('Already have an account? Sign in'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    if (!email.contains('@') || email.startsWith('@') || email.endsWith('@')) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Create a password.';
    if (password.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    TextInput.finishAutofillContext();
    unawaited(
      ref
          .read(signUpControllerProvider.notifier)
          .signUp(
            email: _emailController.text,
            password: _passwordController.text,
          ),
    );
  }
}

class _ConfirmationState extends StatelessWidget {
  const _ConfirmationState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Align(
        alignment: Alignment.centerLeft,
        child: CcIconTile(
          icon: Icons.mark_email_read_outlined,
          semanticLabel: 'Confirmation email sent',
        ),
      ),
      const SizedBox(height: CcSpacing.lg),
      const CcInlineMessage(
        message:
            'If an account can be created for that address, a confirmation '
            'email has been sent. Open its link on this phone.',
        tone: CcMessageTone.success,
        liveRegion: true,
      ),
      const SizedBox(height: CcSpacing.lg),
      CcPrimaryButton(label: 'Back to sign in', onPressed: onBack),
    ],
  );
}
