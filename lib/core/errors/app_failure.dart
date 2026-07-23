enum FailureKind {
  validation,
  authentication,
  authorization,
  notFound,
  conflict,
  connectivity,
  timeout,
  server,
  unexpected,
}

class AppFailure implements Exception {
  const AppFailure({
    required this.kind,
    required this.message,
    this.correlationId,
    this.cause,
  });

  final FailureKind kind;
  final String message;
  final String? correlationId;
  final Object? cause;

  @override
  String toString() => 'AppFailure($kind, $message, $correlationId)';
}
