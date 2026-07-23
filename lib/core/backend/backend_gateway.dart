import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class BackendGateway {
  bool get isConfigured;
  SupabaseClient get client;
}

class SupabaseGateway implements BackendGateway {
  const SupabaseGateway.configured(SupabaseClient client) : _client = client;
  const SupabaseGateway.unconfigured() : _client = null;

  final SupabaseClient? _client;

  @override
  bool get isConfigured => _client != null;

  @override
  SupabaseClient get client {
    if (!isConfigured) {
      throw StateError(
        'Supabase is not configured. Provide public environment values.',
      );
    }
    return _client!;
  }
}
