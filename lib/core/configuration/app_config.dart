import 'dart:convert';

enum AppEnvironment { development, staging, production, test }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.enableDesignSystemGallery,
    required this.enableDemoSession,
    this.sentryDsn,
  });

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool enableDesignSystemGallery;
  final bool enableDemoSession;
  final String? sentryDsn;

  factory AppConfig.fromEnvironment() {
    const environmentValue = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    final environment = AppEnvironment.values.firstWhere(
      (candidate) => candidate.name == environmentValue,
      orElse: () => throw const FormatException(
        'APP_ENV must be development, staging, production, or test.',
      ),
    );

    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const gallery = bool.fromEnvironment(
      'ENABLE_DESIGN_SYSTEM_GALLERY',
      defaultValue: false,
    );
    const demo = bool.fromEnvironment(
      'ENABLE_DEMO_SESSION',
      defaultValue: false,
    );
    const sentry = String.fromEnvironment('SENTRY_DSN');

    if (environment == AppEnvironment.production && demo) {
      throw const FormatException('Demo sessions are forbidden in production.');
    }
    if (url.isNotEmpty && !isValidSupabaseUrl(url, environment: environment)) {
      throw const FormatException(
        'SUPABASE_URL must use HTTPS, except for approved local hosts in '
        'development or test.',
      );
    }
    if (anonKey.isNotEmpty && !isValidPublicClientKey(anonKey)) {
      throw const FormatException(
        'SUPABASE_ANON_KEY must be a public publishable or legacy anon key.',
      );
    }

    return AppConfig(
      environment: environment,
      supabaseUrl: url,
      supabaseAnonKey: anonKey,
      enableDesignSystemGallery:
          gallery && environment != AppEnvironment.production,
      enableDemoSession: demo && environment != AppEnvironment.production,
      sentryDsn: sentry.isEmpty ? null : sentry,
    );
  }

  static bool isValidSupabaseUrl(
    String value, {
    AppEnvironment environment = AppEnvironment.production,
  }) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.host.toLowerCase().contains('your_project')) {
      return false;
    }
    if (uri.scheme == 'https') return true;

    final allowsLocalHttp =
        environment == AppEnvironment.development ||
        environment == AppEnvironment.test;
    const localHosts = {'localhost', '127.0.0.1', '10.0.2.2'};
    return allowsLocalHttp &&
        uri.scheme == 'http' &&
        localHosts.contains(uri.host.toLowerCase());
  }

  static bool isValidPublicClientKey(String value) {
    final key = value.trim();
    final lowerKey = key.toLowerCase();
    if (key.isEmpty ||
        lowerKey.contains('your_public') ||
        lowerKey.contains('service_role') ||
        lowerKey.startsWith('sb_secret_')) {
      return false;
    }
    const publishablePrefix = 'sb_publishable_';
    if (lowerKey.startsWith(publishablePrefix)) {
      return key.length > publishablePrefix.length;
    }

    final jwtParts = key.split('.');
    if (jwtParts.length != 3) return false;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(jwtParts[1]))),
      );
      return payload is Map<String, Object?> && payload['role'] == 'anon';
    } on FormatException {
      return false;
    }
  }

  String get appName => 'CampusConnect';
  bool get isProduction => environment == AppEnvironment.production;
  bool get hasBackendConfiguration =>
      isValidSupabaseUrl(supabaseUrl, environment: environment) &&
      isValidPublicClientKey(supabaseAnonKey);
}
