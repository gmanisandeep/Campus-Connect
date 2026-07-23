import 'dart:async';

import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/core/theme/app_tokens.dart';
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

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/sign-in')),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _submitted
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.mark_email_read_outlined,
                              size: 48,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Check your email',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'If an account exists for that address, reset '
                              'instructions have been sent.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            FilledButton(
                              onPressed: () => context.go('/sign-in'),
                              child: const Text('Back to sign in'),
                            ),
                          ],
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Reset your password',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const Text(
                                'Enter your campus email address. The response '
                                'does not reveal whether an account exists.',
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'Email address',
                                  prefixIcon: Icon(Icons.email_outlined),
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
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  errorMessage,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.lg),
                              FilledButton(
                                onPressed: action.isLoading
                                    ? null
                                    : () => _submit(),
                                child: action.isLoading
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Send reset instructions'),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
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
