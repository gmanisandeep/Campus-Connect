import 'dart:async';

import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_button.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_data_display.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_feedback.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_scaffold.dart';
import 'package:campus_connect/features/identity/presentation/controllers/identity_action_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(identityActionControllerProvider);
    final errorMessage = action.whenOrNull(
      error: (error, _) => error is AppFailure
          ? error.message
          : 'Unable to send reset instructions right now.',
    );

    return CcAuthScaffold(
      heroTitle: 'A secure way back in.',
      heroDescription:
          'Recover access without exposing whether an account exists.',
      panelTitle: _submitted ? 'Check your email' : 'Reset your password',
      panelDescription: _submitted
          ? 'If an account exists for that address, reset instructions have '
                'been sent.'
          : 'Enter your campus email address. The response does not reveal '
                'whether an account exists.',
      leading: BackButton(onPressed: () => context.go('/sign-in')),
      child: _submitted
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: CcIconTile(
                    icon: Icons.mark_email_read_outlined,
                    semanticLabel: 'Reset email sent',
                  ),
                ),
                const SizedBox(height: CcSpacing.lg),
                CcPrimaryButton(
                  label: 'Back to sign in',
                  onPressed: () => context.go('/sign-in'),
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    onFieldSubmitted: (_) {
                      if (!action.isLoading) _submit();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      hintText: 'name@campus.edu',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (!email.contains('@') ||
                          email.startsWith('@') ||
                          email.endsWith('@')) {
                        return 'Enter a valid email address.';
                      }
                      return null;
                    },
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
                    label: 'Send reset instructions',
                    isLoading: action.isLoading,
                    onPressed: action.isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    unawaited(_requestReset());
  }

  Future<void> _requestReset() async {
    await ref
        .read(identityActionControllerProvider.notifier)
        .requestPasswordReset(_emailController.text);
    if (!mounted) return;
    final result = ref.read(identityActionControllerProvider);
    if (!result.hasError) setState(() => _submitted = true);
  }
}
