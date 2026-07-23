import 'dart:developer' as developer;

abstract interface class AppLogger {
  void debug(String event, {Map<String, Object?> fields = const {}});
  void info(String event, {Map<String, Object?> fields = const {}});
  void warning(String event, {Map<String, Object?> fields = const {}});
  void error(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const {},
  });
  void fatal(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const {},
  });
}

class ConsoleAppLogger implements AppLogger {
  const ConsoleAppLogger({required this.isEnabled});

  final bool isEnabled;

  @override
  void debug(String event, {Map<String, Object?> fields = const {}}) =>
      _write('debug', event, fields: fields);

  @override
  void info(String event, {Map<String, Object?> fields = const {}}) =>
      _write('info', event, fields: fields);

  @override
  void warning(String event, {Map<String, Object?> fields = const {}}) =>
      _write('warning', event, fields: fields);

  @override
  void error(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const {},
  }) => _write(
    'error',
    event,
    error: error,
    stackTrace: stackTrace,
    fields: fields,
  );

  @override
  void fatal(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const {},
  }) => _write(
    'fatal',
    event,
    error: error,
    stackTrace: stackTrace,
    fields: fields,
  );

  void _write(
    String level,
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const {},
  }) {
    if (!isEnabled) return;
    final safeFields = _sanitizeMap(fields);
    developer.log(
      '$level $event $safeFields',
      name: 'campus_connect',
      error: error?.runtimeType.toString(),
      stackTrace: stackTrace,
    );
  }

  static Map<String, Object?> _sanitizeMap(Map<String, Object?> values) => {
    for (final entry in values.entries)
      entry.key: _isSensitiveKey(entry.key)
          ? '[redacted]'
          : _sanitizeValue(entry.value),
  };

  static Object? _sanitizeValue(Object? value) => switch (value) {
    Map<String, Object?>() => _sanitizeMap(value),
    Iterable<Object?>() => value.map(_sanitizeValue).toList(),
    _ => value,
  };

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase();
    return _sensitiveKeyFragments.any(normalized.contains);
  }

  static const _sensitiveKeyFragments = {
    'password',
    'token',
    'authorization',
    'email',
    'private_notes',
    'secret',
    'credential',
    'session',
  };
}
