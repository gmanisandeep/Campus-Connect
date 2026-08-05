import 'dart:async';

import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_button.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_feedback.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_scaffold.dart';
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

    return CcAuthScaffold(
      heroTitle: 'Your campus, in one place.',
      heroDescription:
          'Move from classes to attendance with access shaped by your '
          'verified campus role.',
      panelTitle: 'Welcome back',
      panelDescription: 'Sign in to your campus',
      panelKey: const Key('sign-in-panel'),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                autofillHints: const [AutofillHints.username],
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
                autofillHints: const [AutofillHints.password],
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(action.isLoading),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
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
                CcInlineMessage(
                  key: const Key('sign-in-error'),
                  message: errorMessage,
                  tone: CcMessageTone.danger,
                  liveRegion: true,
                ),
                const SizedBox(height: CcSpacing.sm),
              ],
              CcPrimaryButton(
                label: 'Sign in',
                isLoading: action.isLoading,
                onPressed: action.isLoading ? null : () => _submit(false),
              ),
              const SizedBox(height: CcSpacing.xs),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'New to CampusConnect?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: action.isLoading
                        ? null
                        : () => context.go('/sign-up'),
                    child: const Text('Create account'),
                  ),
                ],
              ),
              const SizedBox(height: CcSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: context.ccTheme.textSecondary,
                  ),
                  const SizedBox(width: CcSpacing.xs),
                  Flexible(
                    child: Text(
                      'Access follows your verified institution and role.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              if (config.enableDesignSystemGallery) ...[
                const SizedBox(height: CcSpacing.lg),
                const Divider(),
                const SizedBox(height: CcSpacing.sm),
                Text(
                  'Developer preview',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: CcSpacing.xs),
                Text(
                  'Visual tools are enabled only for this development build.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: CcSpacing.sm),
                FilledButton.tonalIcon(
                  onPressed: () => context.go('/design-system'),
                  icon: const Icon(Icons.palette_outlined),
                  label: const Text('Open developer gallery'),
                ),
                const SizedBox(height: CcSpacing.xs),
                OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(sessionControllerProvider.notifier)
                        .enterGalleryDemo();
                    context.go('/home');
                  },
                  icon: const Icon(Icons.dashboard_outlined),
                  label: const Text('Preview role-aware shell'),
                ),
              ],
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
