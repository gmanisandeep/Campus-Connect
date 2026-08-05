import 'package:campus_connect/features/social/data/supabase_social_repository.dart';
import 'package:campus_connect/features/social/domain/social.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final socialFeedModeProvider = StateProvider<SocialFeedMode>(
  (ref) => SocialFeedMode.forYou,
);

final socialFeedControllerProvider =
    AsyncNotifierProvider<SocialFeedController, List<SocialPost>>(
      SocialFeedController.new,
    );

class SocialFeedController extends AsyncNotifier<List<SocialPost>> {
  @override
  Future<List<SocialPost>> build() => ref
      .watch(socialRepositoryProvider)
      .loadFeed(ref.watch(socialFeedModeProvider));

  Future<void> refresh() async {
    state = const AsyncLoading<List<SocialPost>>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref
          .read(socialRepositoryProvider)
          .loadFeed(ref.read(socialFeedModeProvider)),
    );
  }

  Future<void> toggleLike(SocialPost post) async {
    final before = state.valueOrNull;
    if (before == null) return;
    final liked = !post.likedByViewer;
    state = AsyncData([
      for (final item in before)
        if (item.id == post.id)
          item.copyWith(
            likedByViewer: liked,
            likeCount: item.likeCount + (liked ? 1 : -1),
          )
        else
          item,
    ]);
    try {
      await ref.read(socialRepositoryProvider).toggleLike(post.id);
    } on Object catch (error, stackTrace) {
      state = AsyncError<List<SocialPost>>(
        error,
        stackTrace,
      ).copyWithPrevious(AsyncData(before));
    }
  }

  Future<void> toggleSave(SocialPost post) async {
    final before = state.valueOrNull;
    if (before == null) return;
    state = AsyncData([
      for (final item in before)
        if (item.id == post.id)
          item.copyWith(savedByViewer: !item.savedByViewer)
        else
          item,
    ]);
    try {
      await ref.read(socialRepositoryProvider).toggleSave(post.id);
    } on Object catch (error, stackTrace) {
      state = AsyncError<List<SocialPost>>(
        error,
        stackTrace,
      ).copyWithPrevious(AsyncData(before));
    }
  }

  Future<void> toggleRepost(SocialPost post) async {
    final reposted = await ref
        .read(socialRepositoryProvider)
        .toggleRepost(post.id);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([
      for (final item in current)
        if (item.id == post.id)
          item.copyWith(repostCount: item.repostCount + (reposted ? 1 : -1))
        else
          item,
    ]);
  }
}

final socialProfileProvider = FutureProvider<SocialProfile>(
  (ref) => ref.watch(socialRepositoryProvider).ensureProfile(),
);

final socialInboxProvider = FutureProvider<SocialInbox>(
  (ref) => ref.watch(socialRepositoryProvider).loadInbox(),
);
