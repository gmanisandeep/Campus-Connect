import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/features/community/data/supabase_community_repository.dart';
import 'package:campus_connect/features/community/domain/community.dart';
import 'package:campus_connect/features/community/domain/community_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => SupabaseCommunityRepository(ref.watch(backendGatewayProvider)),
);

final communityOverviewControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      CommunityOverviewController,
      CommunityOverview
    >(CommunityOverviewController.new);

class CommunityOverviewController
    extends AutoDisposeAsyncNotifier<CommunityOverview> {
  @override
  Future<CommunityOverview> build() {
    final session = ref.watch(sessionControllerProvider);
    return ref
        .read(communityRepositoryProvider)
        .loadOverview(session.institutionId);
  }

  Future<void> refresh() async {
    final institutionId = ref.read(sessionControllerProvider).institutionId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(communityRepositoryProvider).loadOverview(institutionId),
    );
  }
}
