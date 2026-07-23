import 'dart:async';

import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/core/theme/app_tokens.dart';
import 'package:campus_connect/features/identity/presentation/controllers/identity_action_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final action = ref.watch(identityActionControllerProvider);
    final errorMessage = action.whenOrNull(
      error: (error, _) =>
          error is AppFailure ? error.message : 'Unable to sign in right now.',
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 56,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'CampusConnect',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const Text(
                            'Sign in to your campus',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _emailController,
                            autofillHints: const [AutofillHints.username],
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _passwordController,
                            autofillHints: const [AutofillHints.password],
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(action.isLoading),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
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
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter your password.'
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: action.isLoading
                                  ? null
                                  : () => context.go('/forgot-password'),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          if (errorMessage != null) ...[
                            Text(
                              errorMessage,
                              key: const Key('sign-in-error'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          FilledButton(
                            onPressed: action.isLoading
                                ? null
                                : () => _submit(false),
                            child: action.isLoading
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Sign in'),
                          ),
                          if (config.enableDesignSystemGallery) ...[
                            const SizedBox(height: AppSpacing.lg),
                            const Divider(),
                            FilledButton.tonalIcon(
                              onPressed: () => context.go('/design-system'),
                              icon: const Icon(Icons.palette_outlined),
                              label: const Text('Open developer gallery'),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                ref
                                    .read(sessionControllerProvider.notifier)
                                    .enterGalleryDemo();
                                context.go('/home');
                              },
                              child: const Text('Preview role-aware shell'),
                            ),
                          ],
                        ],
                      ),
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

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    if (!email.contains('@') || email.startsWith('@') || email.endsWith('@')) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  void _submit(bool isLoading) {
    if (isLoading || !(_formKey.currentState?.validate() ?? false)) return;
    TextInput.finishAutofillContext();
    unawaited(
      ref
          .read(identityActionControllerProvider.notifier)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          ),
    );
  }
}
