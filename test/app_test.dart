import 'package:campus_connect/app.dart';
import 'package:campus_connect/core/auth/identity_repository.dart';
import 'package:campus_connect/core/configuration/app_config.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/logging/app_logger.dart';
import 'package:campus_connect/features/identity/presentation/controllers/identity_action_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('signed-out app presents the real sign-in form', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: AppEnvironment.test,
              supabaseUrl: '',
              supabaseAnonKey: '',
              enableDesignSystemGallery: false,
              enableDemoSession: false,
            ),
          ),
          appLoggerProvider.overrideWithValue(
            const ConsoleAppLogger(isEnabled: false),
          ),
        ],
        child: const CampusConnectApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CampusConnect'), findsOneWidget);
    expect(find.text('Sign in to your campus'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('new users can open and validate the sign-up form', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: AppEnvironment.test,
              supabaseUrl: '',
              supabaseAnonKey: '',
              enableDesignSystemGallery: false,
              enableDemoSession: false,
            ),
          ),
        ],
        child: const CampusConnectApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsNWidgets(2));
    expect(find.text('Confirm password'), findsOneWidget);
    expect(
      find.textContaining('Creating an account does not assign campus access'),
      findsOneWidget,
    );

    final createButton = find.widgetWithText(FilledButton, 'Create account');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pump();

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Create a password.'), findsOneWidget);
  });

  testWidgets('sign-in validates required credentials before a request', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: AppEnvironment.test,
              supabaseUrl: '',
              supabaseAnonKey: '',
              enableDesignSystemGallery: false,
              enableDemoSession: false,
            ),
          ),
        ],
        child: const CampusConnectApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('confirmed sign-up state gives a safe email next step', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: AppEnvironment.test,
              supabaseUrl: '',
              supabaseAnonKey: '',
              enableDesignSystemGallery: false,
              enableDemoSession: false,
            ),
          ),
          signUpControllerProvider.overrideWith(
            _ConfirmationRequiredSignUpController.new,
          ),
        ],
        child: const CampusConnectApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Check your email'), findsOneWidget);
    expect(
      find.textContaining('If an account can be created for that address'),
      findsOneWidget,
    );
    expect(find.text('Back to sign in'), findsOneWidget);
  });
}

class _ConfirmationRequiredSignUpController extends SignUpController {
  @override
  AccountCreationResult? build() =>
      const AccountCreationResult(confirmationRequired: true);
}
