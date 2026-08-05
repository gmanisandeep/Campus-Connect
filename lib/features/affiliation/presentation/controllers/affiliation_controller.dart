import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/features/affiliation/data/supabase_affiliation_repository.dart';
import 'package:campus_connect/features/affiliation/domain/affiliation.dart';
import 'package:campus_connect/features/affiliation/domain/affiliation_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final affiliationRepositoryProvider = Provider<AffiliationRepository>(
  (ref) => SupabaseAffiliationRepository(ref.watch(backendGatewayProvider)),
);

final studentAffiliationControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      StudentAffiliationController,
      StudentAffiliationOverview
    >(StudentAffiliationController.new);

class StudentAffiliationController
    extends AutoDisposeAsyncNotifier<StudentAffiliationOverview> {
  @override
  Future<StudentAffiliationOverview> build() {
    ref.watch(sessionControllerProvider.select((session) => session.userId));
    return ref.read(affiliationRepositoryProvider).loadStudentOverview();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      ref.read(affiliationRepositoryProvider).loadStudentOverview,
    );
    final request = state.valueOrNull?.request;
    if (request?.status == AffiliationRequestStatus.approved) {
      await ref.read(sessionControllerProvider.notifier).restore();
    }
  }

  Future<void> submit(StudentAffiliationSubmission submission) async {
    final previous = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final request = await ref
          .read(affiliationRepositoryProvider)
          .submitStudentRequest(submission);
      return StudentAffiliationOverview(
        institutions: previous?.institutions ?? const [],
        programmes: previous?.programmes ?? const [],
        request: request,
      );
    });
  }

  Future<void> cancel(String requestId) async {
    final previous = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(affiliationRepositoryProvider)
          .cancelStudentRequest(requestId);
      return StudentAffiliationOverview(
        institutions: previous?.institutions ?? const [],
        programmes: previous?.programmes ?? const [],
        request: null,
      );
    });
  }
}

final affiliationReviewControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      AffiliationReviewController,
      List<StudentAffiliationRequest>
    >(AffiliationReviewController.new);

class AffiliationReviewController
    extends AutoDisposeAsyncNotifier<List<StudentAffiliationRequest>> {
  @override
  Future<List<StudentAffiliationRequest>> build() {
    final session = ref.watch(sessionControllerProvider);
    final institutionId = session.institutionId;
    if (institutionId == null ||
        !session.can(AppPermission.institutionManage)) {
      throw const AppFailure(
        kind: FailureKind.authorization,
        message: 'Institution administrator access is required.',
      );
    }
    return ref
        .read(affiliationRepositoryProvider)
        .loadPendingRequests(institutionId);
  }

  Future<void> refresh() async {
    final institutionId = ref.read(sessionControllerProvider).institutionId;
    if (institutionId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(affiliationRepositoryProvider)
          .loadPendingRequests(institutionId),
    );
  }

  Future<void> review({
    required String requestId,
    required bool approve,
    int? verifiedCurrentYear,
    String? decisionNote,
  }) async {
    final institutionId = ref.read(sessionControllerProvider).institutionId;
    if (institutionId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(affiliationRepositoryProvider)
          .reviewRequest(
            requestId: requestId,
            approve: approve,
            verifiedCurrentYear: verifiedCurrentYear,
            decisionNote: decisionNote,
          );
      return ref
          .read(affiliationRepositoryProvider)
          .loadPendingRequests(institutionId);
    });
  }
}
