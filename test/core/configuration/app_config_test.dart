import 'dart:convert';

import 'package:campus_connect/core/configuration/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('accepts a real HTTPS Supabase URL shape', () {
      expect(
        AppConfig.isValidSupabaseUrl('https://example.supabase.co'),
        isTrue,
      );
    });

    test('rejects HTTP and case-insensitive placeholders', () {
      expect(AppConfig.isValidSupabaseUrl('http://example.test'), isFalse);
      expect(
        AppConfig.isValidSupabaseUrl('https://YOUR_PROJECT.supabase.co'),
        isFalse,
      );
      expect(
        AppConfig.isValidSupabaseUrl('https://Your_Project.supabase.co'),
        isFalse,
      );
    });

    test('allows HTTP only for approved local development hosts', () {
      expect(
        AppConfig.isValidSupabaseUrl(
          'http://127.0.0.1:54321',
          environment: AppEnvironment.development,
        ),
        isTrue,
      );
      expect(
        AppConfig.isValidSupabaseUrl(
          'http://10.0.2.2:54321',
          environment: AppEnvironment.test,
        ),
        isTrue,
      );
      expect(
        AppConfig.isValidSupabaseUrl(
          'http://127.0.0.1:54321',
          environment: AppEnvironment.staging,
        ),
        isFalse,
      );
      expect(
        AppConfig.isValidSupabaseUrl(
          'http://example.test:54321',
          environment: AppEnvironment.development,
        ),
        isFalse,
      );
    });

    test('accepts public keys and rejects privileged client credentials', () {
      expect(
        AppConfig.isValidPublicClientKey('sb_publishable_example'),
        isTrue,
      );
      expect(AppConfig.isValidPublicClientKey('YOUR_PUBLIC_ANON_KEY'), isFalse);
      expect(AppConfig.isValidPublicClientKey('sb_secret_example'), isFalse);
      expect(AppConfig.isValidPublicClientKey('public-test-key'), isFalse);
      expect(AppConfig.isValidPublicClientKey('sb_publishable_'), isFalse);

      final anonPayload = base64Url.encode(utf8.encode('{"role":"anon"}'));
      final servicePayload = base64Url.encode(
        utf8.encode('{"role":"service_role"}'),
      );
      expect(
        AppConfig.isValidPublicClientKey('header.$anonPayload.signature'),
        isTrue,
      );
      expect(
        AppConfig.isValidPublicClientKey('header.$servicePayload.signature'),
        isFalse,
      );
    });
  });
}
