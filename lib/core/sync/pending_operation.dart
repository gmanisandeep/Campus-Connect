enum PendingOperationState { pending, syncing, confirmed, failed, needsReview }

class PendingOperation {
  const PendingOperation({
    required this.idempotencyKey,
    required this.operationType,
    required this.createdAt,
    required this.payload,
    this.attemptCount = 0,
    this.state = PendingOperationState.pending,
  });

  final String idempotencyKey;
  final String operationType;
  final DateTime createdAt;
  final Map<String, Object?> payload;
  final int attemptCount;
  final PendingOperationState state;
}
