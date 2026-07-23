import 'dart:async';

import 'package:campus_connect/app.dart';
import 'package:campus_connect/core/configuration/app_config.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/logging/app_logger.dart';
import 'package:campus_connect/core/storage/secure_store.dart';
import 'package:campus_connect/core/storage/secure_supabase_local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  final config = AppConfig.fromEnvironment();
  final logger = ConsoleAppLogger(isEnabled: !config.isProduction);

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      const authSecureStore = PlatformSecureStore();
      SecureSupabaseLocalStorage? authSessionStorage;
      if (config.hasBackendConfiguration) {
        authSessionStorage = SecureSupabaseLocalStorage(
          authSecureStore,
          namespace: Uri.parse(config.supabaseUrl).host,
        );
        await Supabase.initialize(
          url: config.supabaseUrl,
          publishableKey: config.supabaseAnonKey,
          authOptions: FlutterAuthClientOptions(
            localStorage: authSessionStorage,
          ),
        );
      }
      FlutterError.onError = (details) {
        logger.error(
          'flutter.framework_error',
          error: details.exception,
          stackTrace: details.stack,
        );
        if (!config.isProduction) {
          FlutterError.presentError(details);
        }
      };

      runApp(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            appLoggerProvider.overrideWithValue(logger),
            if (authSessionStorage != null)
              authSessionGateProvider.overrideWithValue(authSessionStorage),
          ],
          child: const CampusConnectApp(),
        ),
      );
    },
    (error, stackTrace) {
      logger.fatal('app.uncaught_error', error: error, stackTrace: stackTrace);
    },
  );
}
