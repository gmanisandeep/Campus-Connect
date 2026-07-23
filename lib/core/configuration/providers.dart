import 'package:campus_connect/core/analytics/analytics.dart';
import 'package:campus_connect/core/auth/identity_repository.dart';
import 'package:campus_connect/core/backend/backend_gateway.dart';
import 'package:campus_connect/core/configuration/app_config.dart';
import 'package:campus_connect/core/logging/app_logger.dart';
import 'package:campus_connect/core/networking/connectivity_service.dart';
import 'package:campus_connect/core/storage/key_value_store.dart';
import 'package:campus_connect/core/storage/secure_store.dart';
import 'package:campus_connect/core/storage/secure_supabase_local_storage.dart';
import 'package:campus_connect/features/identity/data/supabase_identity_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw StateError('AppConfig must be overridden at startup.'),
);

final appLoggerProvider = Provider<AppLogger>(
  (ref) => const ConsoleAppLogger(isEnabled: false),
);

final analyticsProvider = Provider<Analytics>(
  (ref) => LoggingAnalytics(ref.watch(appLoggerProvider)),
);

final backendGatewayProvider = Provider<BackendGateway>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasBackendConfiguration) {
    return const SupabaseGateway.unconfigured();
  }
  return SupabaseGateway.configured(Supabase.instance.client);
});

final authSessionGateProvider = Provider<AuthSessionGate>(
  (ref) => throw StateError('AuthSessionGate must be overridden at startup.'),
);

final identityRepositoryProvider = Provider<IdentityRepository>(
  (ref) => SupabaseIdentityRepository(
    ref.watch(backendGatewayProvider),
    ref.watch(authSessionGateProvider),
  ),
);

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityPlusService(),
);

final connectivityProvider = StreamProvider<NetworkStatus>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.current();
  yield* service.changes;
});

final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => SharedPreferencesStore(),
);

final sensitiveDataKeyStoreProvider = Provider<SecureStore>(
  (ref) => const PlatformSecureStore.sensitiveDataKeys(),
);
