import 'package:campus_connect/app.dart';
import 'package:campus_connect/core/configuration/app_config.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/logging/app_logger.dart';
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
    expect(find.byType(MaterialApp), findsOneWidget);
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
}
