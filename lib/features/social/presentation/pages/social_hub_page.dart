import 'dart:async';

import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_ambient_background.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_button.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_data_display.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_feedback.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_navigation.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_pulse.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_surface.dart';
import 'package:campus_connect/features/affiliation/presentation/widgets/student_affiliation_panel.dart';
import 'package:campus_connect/features/social/data/supabase_social_repository.dart';
import 'package:campus_connect/features/social/domain/social.dart';
import 'package:campus_connect/features/social/presentation/controllers/social_controllers.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class SocialHubPage extends ConsumerStatefulWidget {
  const SocialHubPage({
    this.initialSection = 0,
    this.provisional = false,
    super.key,
  });

  final int initialSection;
  final bool provisional;

  @override
  ConsumerState<SocialHubPage> createState() => _SocialHubPageState();
}

class _SocialHubPageState extends ConsumerState<SocialHubPage> {
  late int _section = widget.initialSection;

  static const _items = [
    CcNavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    CcNavigationItem(
      label: 'Explore',
      icon: Icons.travel_explore_outlined,
      selectedIcon: Icons.travel_explore_rounded,
    ),
    CcNavigationItem(
      label: 'Create',
      icon: Icons.add_box_outlined,
      selectedIcon: Icons.add_box_rounded,
    ),
    CcNavigationItem(
      label: 'Messages',
      icon: Icons.forum_outlined,
      selectedIcon: Icons.forum_rounded,
    ),
    CcNavigationItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final body = switch (_section) {
      0 => _SocialFeedView(
        provisional: widget.provisional,
        onCreate: () => setState(() => _section = 2),
      ),
      1 => const _ExploreView(),
      2 => _CreatePostView(
        onPublished: () {
          ref.invalidate(socialFeedControllerProvider);
          setState(() => _section = 0);
        },
      ),
      3 => const _InboxView(),
      _ => _SocialProfileView(provisional: widget.provisional),
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CcAmbientBackground(
        tone: CcAmbientTone.quiet,
        child: SafeArea(bottom: false, child: body),
      ),
      bottomNavigationBar: CcNavigationBar(
        items: _items,
        selectedIndex: _section,
        onSelected: (value) => setState(() => _section = value),
      ),
    );
  }
}

class _SocialFeedView extends ConsumerWidget {
  const _SocialFeedView({required this.provisional, required this.onCreate});

  final bool provisional;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(socialFeedModeProvider);
    final feed = ref.watch(socialFeedControllerProvider);
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(socialFeedControllerProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _SocialPulseHeader(onCreate: onCreate)),
          if (provisional)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                CcSpacing.md,
                0,
                CcSpacing.md,
                CcSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: CcInlineMessage(
                  message:
                      'Social access is active while college verification is pending. Attendance, Calendar, Courses, and academic records remain locked.',
                  tone: CcMessageTone.info,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                CcSpacing.md,
                0,
                CcSpacing.md,
                CcSpacing.md,
              ),
              child: CcSurface(
                variant: CcSurfaceVariant.glass,
                padding: const EdgeInsets.all(CcSpacing.xxs),
                borderRadius: BorderRadius.circular(999),
                child: SegmentedButton<SocialFeedMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: SocialFeedMode.forYou,
                      label: Text('For you'),
                    ),
                    ButtonSegment(
                      value: SocialFeedMode.following,
                      label: Text('Following'),
                    ),
                    ButtonSegment(
                      value: SocialFeedMode.college,
                      label: Text('My college'),
                    ),
                    ButtonSegment(
                      value: SocialFeedMode.saved,
                      label: Text('Saved'),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (value) =>
                      ref.read(socialFeedModeProvider.notifier).state =
                          value.single,
                ),
              ),
            ),
          ),
          ..._feedSlivers(context, ref, feed),
        ],
      ),
    );
  }
}

List<Widget> _feedSlivers(
  BuildContext context,
  WidgetRef ref,
  AsyncValue<List<SocialPost>> feed,
) => feed.when(
  loading: () => const [
    SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  ],
  error: (error, _) => [
    SliverFillRemaining(
      hasScrollBody: false,
      child: _SocialError(
        message: _message(error),
        onRetry: () =>
            ref.read(socialFeedControllerProvider.notifier).refresh(),
      ),
    ),
  ],
  data: (posts) => posts.isEmpty
      ? const [
          SliverPadding(
            padding: EdgeInsets.only(bottom: CcSpacing.xl),
            sliver: SliverToBoxAdapter(
              child: _SocialEmpty(
                icon: Icons.auto_awesome_outlined,
                title: 'Your campus world starts here',
                message:
                    'Follow people, publish the first post, or explore colleges. Nothing is hidden behind verification.',
              ),
            ),
          ),
        ]
      : [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              CcSpacing.md,
              0,
              CcSpacing.md,
              CcSpacing.xl,
            ),
            sliver: SliverList.separated(
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: CcSpacing.sm),
              itemBuilder: (context, index) =>
                  _SocialPostCard(post: posts[index]),
            ),
          ),
        ],
);

class _SocialPostCard extends ConsumerWidget {
  const _SocialPostCard({required this.post});

  final SocialPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return CcSpotlightSurface(
      key: ValueKey(post.id),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            minTileHeight: 68,
            leading: CircleAvatar(
              backgroundImage: post.avatarPath == null
                  ? null
                  : NetworkImage(post.avatarPath!),
              child: post.avatarPath == null
                  ? Text(post.authorName.characters.first.toUpperCase())
                  : null,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    post.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (post.isOfficial) ...[
                  const SizedBox(width: CcSpacing.xxs),
                  Icon(
                    Icons.verified_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                    semanticLabel: 'Official college account',
                  ),
                ],
              ],
            ),
            subtitle: Text(
              [
                if (post.username != null) '@${post.username}',
                if (post.institutionName != null) post.institutionName,
                _relativeTime(post.publishedAt),
              ].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              tooltip: 'Post options',
              onPressed: () => _showPostOptions(context, ref, post),
              icon: const Icon(Icons.more_horiz_rounded),
            ),
            onTap: () => _showPersonActions(context, ref, post),
          ),
          if (post.body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CcSpacing.md,
                0,
                CcSpacing.md,
                CcSpacing.md,
              ),
              child: Text(post.body, style: theme.textTheme.bodyLarge),
            ),
          for (final media in post.media) _PostMediaView(media: media),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CcSpacing.xs,
              vertical: CcSpacing.xxs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CountAction(
                  tooltip: post.likedByViewer ? 'Unlike' : 'Like',
                  icon: post.likedByViewer
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  count: post.likeCount,
                  selected: post.likedByViewer,
                  onPressed: () => unawaited(
                    ref
                        .read(socialFeedControllerProvider.notifier)
                        .toggleLike(post),
                  ),
                ),
                _CountAction(
                  tooltip: 'Comments',
                  icon: Icons.chat_bubble_outline_rounded,
                  count: post.commentCount,
                  onPressed: () => _showComments(context, ref, post),
                ),
                _CountAction(
                  tooltip: 'Repost',
                  icon: Icons.repeat_rounded,
                  count: post.repostCount,
                  onPressed: () => unawaited(
                    ref
                        .read(socialFeedControllerProvider.notifier)
                        .toggleRepost(post),
                  ),
                ),
                IconButton(
                  tooltip: post.savedByViewer
                      ? 'Remove from saved'
                      : 'Save post',
                  onPressed: () => unawaited(
                    ref
                        .read(socialFeedControllerProvider.notifier)
                        .toggleSave(post),
                  ),
                  icon: Icon(
                    post.savedByViewer
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                  ),
                ),
                IconButton(
                  tooltip: 'Share post',
                  onPressed: () => Share.share(
                    '${post.authorName} on CampusConnect\n\n${post.body}',
                  ),
                  icon: const Icon(Icons.ios_share_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountAction extends StatelessWidget {
  const _CountAction({
    required this.tooltip,
    required this.icon,
    required this.count,
    required this.onPressed,
    this.selected = false,
  });

  final String tooltip;
  final IconData icon;
  final int count;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      label: '$tooltip, $count',
      button: true,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: selected ? Theme.of(context).colorScheme.primary : null,
        ),
        label: Text('$count'),
      ),
    ),
  );
}

class _PostMediaView extends StatelessWidget {
  const _PostMediaView({required this.media});

  final SocialMedia media;

  @override
  Widget build(BuildContext context) => switch (media.kind) {
    SocialMediaKind.image => Semantics(
      image: true,
      label: media.altText.isEmpty ? 'Post image' : media.altText,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560),
        child: Image.network(
          media.path,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const AspectRatio(
                  aspectRatio: 1,
                  child: Center(child: CircularProgressIndicator()),
                ),
          errorBuilder: (_, __, ___) =>
              const _MediaUnavailable(label: 'Image unavailable'),
        ),
      ),
    ),
    SocialMediaKind.video => _InlineVideo(url: media.path),
    SocialMediaKind.document => ListTile(
      leading: const Icon(Icons.description_outlined),
      title: const Text('Shared document'),
      subtitle: Text(media.mimeType),
    ),
  };
}

class _InlineVideo extends StatefulWidget {
  const _InlineVideo({required this.url});
  final String url;

  @override
  State<_InlineVideo> createState() => _InlineVideoState();
}

class _InlineVideoState extends State<_InlineVideo> {
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(Uri.parse(widget.url));
  late final Future<void> _initialized = _controller.initialize();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _initialized,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return const _MediaUnavailable(label: 'Video unavailable');
      }
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio == 0
                ? 16 / 9
                : _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          IconButton.filledTonal(
            tooltip: _controller.value.isPlaying ? 'Pause video' : 'Play video',
            onPressed: () => setState(
              () => _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play(),
            ),
            icon: Icon(
              _controller.value.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
            ),
          ),
        ],
      );
    },
  );
}

class _MediaUnavailable extends StatelessWidget {
  const _MediaUnavailable({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 9,
    child: ColoredBox(
      color: context.ccTheme.raisedSurface,
      child: Center(child: Text(label)),
    ),
  );
}

class _ExploreView extends ConsumerStatefulWidget {
  const _ExploreView();

  @override
  ConsumerState<_ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends ConsumerState<_ExploreView> {
  final _search = TextEditingController();
  AsyncValue<List<InstitutionDirectoryEntry>> _results = const AsyncData([]);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    setState(() => _results = const AsyncLoading());
    final result = await AsyncValue.guard(
      () => ref.read(socialRepositoryProvider).searchInstitutions(_search.text),
    );
    if (mounted) setState(() => _results = result);
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      const SliverToBoxAdapter(
        child: _PageHeader(
          title: 'Explore',
          supportingText:
              'Discover colleges and the wider CampusConnect community.',
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          CcSpacing.md,
          0,
          CcSpacing.md,
          CcSpacing.md,
        ),
        sliver: SliverList.list(
          children: [
            SearchBar(
              controller: _search,
              hintText: 'Search colleges',
              leading: const Icon(Icons.search_rounded),
              trailing: [
                IconButton(
                  tooltip: 'Search',
                  onPressed: _runSearch,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ],
              onSubmitted: (_) => _runSearch(),
            ),
            const SizedBox(height: CcSpacing.md),
            const CcInlineMessage(
              message:
                  'Every listed college can be discovered before it registers. Verified colleges receive an official badge and administration tools.',
              tone: CcMessageTone.info,
            ),
            const SizedBox(height: CcSpacing.md),
            _results.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(CcSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) =>
                  _SocialError(message: _message(error), onRetry: _runSearch),
              data: (items) => items.isEmpty
                  ? const _SocialEmpty(
                      icon: Icons.search_rounded,
                      title: 'Search the college directory',
                      message:
                          'Find a college by its official name. Missing records can be reviewed before they are published.',
                    )
                  : Column(
                      children: [
                        for (final item in items) _InstitutionRow(entry: item),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _InstitutionRow extends StatelessWidget {
  const _InstitutionRow({required this.entry});
  final InstitutionDirectoryEntry entry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: CcSpacing.sm),
    child: CcSurface(
      padding: EdgeInsets.zero,
      child: ListTile(
        minTileHeight: 76,
        leading: const CircleAvatar(child: Icon(Icons.account_balance_rounded)),
        title: Text(entry.name),
        subtitle: Text(
          [
            entry.city,
            entry.district,
            entry.aisheCode,
          ].whereType<String>().join(' · '),
        ),
        trailing: Tooltip(
          message: entry.isVerified
              ? 'Verified on CampusConnect'
              : 'Not yet registered',
          child: Icon(
            entry.isVerified
                ? Icons.verified_rounded
                : Icons.hourglass_empty_rounded,
            color: entry.isVerified
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        ),
      ),
    ),
  );
}

class _CreatePostView extends ConsumerStatefulWidget {
  const _CreatePostView({required this.onPublished});
  final VoidCallback onPublished;

  @override
  ConsumerState<_CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends ConsumerState<_CreatePostView> {
  final _body = TextEditingController();
  final List<SocialUpload> _uploads = [];
  String _visibility = 'public';
  bool _official = false;
  bool _publishing = false;
  String? _error;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    const acceptedTypes = XTypeGroup(
      label: 'Images, video, and documents',
      extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'mp4', 'webm', 'pdf'],
    );
    final result = await openFiles(acceptedTypeGroups: const [acceptedTypes]);
    if (result.isEmpty) return;
    final accepted = <SocialUpload>[];
    for (final file in result.take(10 - _uploads.length)) {
      final bytes = await file.readAsBytes();
      if (bytes.length > 50 * 1024 * 1024) continue;
      accepted.add(_socialUpload(file.name, bytes));
    }
    setState(() {
      _uploads.addAll(accepted);
      if (accepted.length != result.length) {
        _error =
            'Some files were skipped. Use supported files smaller than 50 MB.';
      }
    });
  }

  Future<void> _publish() async {
    if (_body.text.trim().isEmpty && _uploads.isEmpty) {
      setState(
        () => _error = 'Write something or add media before publishing.',
      );
      return;
    }
    setState(() {
      _publishing = true;
      _error = null;
    });
    try {
      final session = ref.read(sessionControllerProvider);
      await ref
          .read(socialRepositoryProvider)
          .createPost(
            body: _body.text,
            visibility: _visibility,
            uploads: _uploads,
            institutionId: session.institutionId,
            official: _official,
          );
      if (mounted) widget.onPublished();
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final canPublishOfficial =
        session.can(AppPermission.announcementsPublish) ||
        session.can(AppPermission.institutionManage);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        CcSpacing.md,
        CcSpacing.lg,
        CcSpacing.md,
        CcSpacing.xl,
      ),
      children: [
        const CcSectionHeader(
          title: 'Create a post',
          supportingText:
              'Share text, images, video, or a document with the campus community.',
        ),
        const SizedBox(height: CcSpacing.lg),
        CcSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('social-post-body'),
                controller: _body,
                minLines: 6,
                maxLines: 14,
                maxLength: 5000,
                decoration: const InputDecoration(
                  labelText: 'What do you want to share?',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: CcSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _visibility,
                decoration: const InputDecoration(labelText: 'Audience'),
                items: const [
                  DropdownMenuItem(
                    value: 'public',
                    child: Text('Everyone on CampusConnect'),
                  ),
                  DropdownMenuItem(
                    value: 'followers',
                    child: Text('Followers'),
                  ),
                  DropdownMenuItem(value: 'college', child: Text('My college')),
                ],
                onChanged: _publishing
                    ? null
                    : (value) =>
                          setState(() => _visibility = value ?? 'public'),
              ),
              if (canPublishOfficial) ...[
                const SizedBox(height: CcSpacing.sm),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Official college announcement'),
                  subtitle: Text(
                    'Publish with the verified ${session.institutionName ?? 'college'} identity.',
                  ),
                  value: _official,
                  onChanged: _publishing
                      ? null
                      : (value) => setState(() => _official = value),
                ),
              ],
              if (_uploads.isNotEmpty) ...[
                const SizedBox(height: CcSpacing.md),
                Wrap(
                  spacing: CcSpacing.xs,
                  runSpacing: CcSpacing.xs,
                  children: [
                    for (var index = 0; index < _uploads.length; index++)
                      InputChip(
                        avatar: Icon(
                          _mediaIcon(_uploads[index].kind),
                          size: 18,
                        ),
                        label: Text(
                          _uploads[index].name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onDeleted: _publishing
                            ? null
                            : () => setState(() => _uploads.removeAt(index)),
                      ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: CcSpacing.md),
                CcInlineMessage(
                  message: _error!,
                  tone: CcMessageTone.danger,
                  liveRegion: true,
                ),
              ],
              const SizedBox(height: CcSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: CcSecondaryButton(
                      label: 'Add media',
                      icon: Icons.add_photo_alternate_outlined,
                      onPressed: _publishing ? null : _pickMedia,
                    ),
                  ),
                  const SizedBox(width: CcSpacing.sm),
                  Expanded(
                    child: CcPrimaryButton(
                      label: 'Publish',
                      icon: Icons.send_rounded,
                      isLoading: _publishing,
                      onPressed: _publishing ? null : _publish,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: CcSpacing.md),
        const CcInlineMessage(
          message:
              'Posts can be reported, and prohibited content may be hidden or removed. Only verified college authorities can publish official announcements.',
          tone: CcMessageTone.info,
        ),
      ],
    );
  }
}

class _InboxView extends ConsumerWidget {
  const _InboxView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(socialInboxProvider);
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: _PageHeader(
            title: 'Messages',
            supportingText: 'Requests stay separate until you accept them.',
          ),
        ),
        inbox.when(
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: _SocialError(
              message: _message(error),
              onRetry: () async => ref.invalidate(socialInboxProvider),
            ),
          ),
          data: (data) => SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              CcSpacing.md,
              0,
              CcSpacing.md,
              CcSpacing.xl,
            ),
            sliver: SliverList.list(
              children: [
                if (data.requests.isNotEmpty) ...[
                  CcSectionHeader(
                    title: 'Message requests',
                    supportingText:
                        '${data.requests.length} waiting for your decision',
                  ),
                  const SizedBox(height: CcSpacing.sm),
                  for (final request in data.requests)
                    _MessageRequestRow(request: request),
                  const SizedBox(height: CcSpacing.lg),
                ],
                const CcSectionHeader(
                  title: 'Conversations',
                  supportingText: 'Only accepted conversations appear here.',
                ),
                const SizedBox(height: CcSpacing.sm),
                if (data.threads.isEmpty)
                  const _SocialEmpty(
                    icon: Icons.mark_chat_unread_outlined,
                    title: 'No conversations yet',
                    message:
                        'Open a person from a post to follow them or send a respectful message request.',
                  )
                else
                  for (final thread in data.threads) _ThreadRow(thread: thread),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageRequestRow extends ConsumerWidget {
  const _MessageRequestRow({required this.request});
  final MessageRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: CcSpacing.sm),
    child: CcSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.senderName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: CcSpacing.xs),
          Text(request.openingMessage),
          const SizedBox(height: CcSpacing.md),
          Row(
            children: [
              Expanded(
                child: CcSecondaryButton(
                  label: 'Decline',
                  onPressed: () => _respond(ref, false),
                ),
              ),
              const SizedBox(width: CcSpacing.sm),
              Expanded(
                child: CcPrimaryButton(
                  label: 'Accept',
                  onPressed: () => _respond(ref, true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _respond(WidgetRef ref, bool accept) async {
    await ref
        .read(socialRepositoryProvider)
        .respondMessageRequest(request.id, accept);
    ref.invalidate(socialInboxProvider);
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.thread});
  final SocialThreadSummary thread;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: CcSpacing.sm),
    child: CcSurface(
      padding: EdgeInsets.zero,
      child: ListTile(
        minTileHeight: 72,
        leading: CircleAvatar(
          child: Text(thread.participantName.characters.first.toUpperCase()),
        ),
        title: Text(thread.participantName),
        subtitle: Text(
          thread.lastMessage ?? 'Conversation accepted',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _ConversationPage(thread: thread),
          ),
        ),
      ),
    ),
  );
}

class _ConversationPage extends ConsumerStatefulWidget {
  const _ConversationPage({required this.thread});
  final SocialThreadSummary thread;

  @override
  ConsumerState<_ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<_ConversationPage> {
  final _composer = TextEditingController();
  late Future<List<SocialMessage>> _messages = _load();
  bool _sending = false;

  Future<List<SocialMessage>> _load() =>
      ref.read(socialRepositoryProvider).loadThread(widget.thread.id);

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _composer.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(socialRepositoryProvider)
          .sendMessage(widget.thread.id, body);
      _composer.clear();
      setState(() => _messages = _load());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.thread.participantName)),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<SocialMessage>>(
              future: _messages,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final currentUserId = ref
                    .read(sessionControllerProvider)
                    .userId;
                return ListView.builder(
                  padding: const EdgeInsets.all(CcSpacing.md),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data![index];
                    final mine = message.senderUserId == currentUserId;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: CcSpacing.xs),
                        child: CcSurface(
                          variant: mine
                              ? CcSurfaceVariant.raised
                              : CcSurfaceVariant.base,
                          child: Text(message.body),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(CcSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _composer,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Message'),
                  ),
                ),
                const SizedBox(width: CcSpacing.sm),
                IconButton.filled(
                  tooltip: 'Send message',
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SocialProfileView extends ConsumerWidget {
  const _SocialProfileView({required this.provisional});
  final bool provisional;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(socialProfileProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        CcSpacing.md,
        CcSpacing.lg,
        CcSpacing.md,
        CcSpacing.xl,
      ),
      children: [
        profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _SocialError(
            message: _message(error),
            onRetry: () async => ref.invalidate(socialProfileProvider),
          ),
          data: (data) => CcSurface(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  child: Text(data.username.characters.first.toUpperCase()),
                ),
                const SizedBox(width: CcSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${data.username}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: CcSpacing.xxs),
                      Text(
                        data.bio.isEmpty
                            ? 'Your CampusConnect profile'
                            : data.bio,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: CcSpacing.md),
        CcInlineMessage(
          message: provisional
              ? 'Social access is active. College verification is still pending, so Attendance, Calendar, Courses, and academic records remain locked.'
              : 'Your verified campus role controls academic tools. Social posting and messaging remain separate from academic authority.',
          tone: CcMessageTone.info,
        ),
        const SizedBox(height: CcSpacing.md),
        if (provisional)
          const StudentAffiliationPanel()
        else ...[
          CcSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('Campus and academic access'),
                  subtitle: const Text('Open your role-aware campus workspace'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/home'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bookmarks_outlined),
                  title: const Text('Saved posts'),
                  onTap: () {
                    ref.read(socialFeedModeProvider.notifier).state =
                        SocialFeedMode.saved;
                  },
                ),
              ],
            ),
          ),
        ],
        if (kIsWeb) ...[
          const SizedBox(height: CcSpacing.md),
          CcSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.apartment_rounded),
                  title: const Text('Register a college'),
                  subtitle: const Text('Desktop College Console'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/college-registration'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Register as Faculty'),
                  subtitle: const Text('Requires a verified college'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/faculty-registration'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: CcSpacing.md),
        CcSecondaryButton(
          label: 'Sign out',
          icon: Icons.logout_rounded,
          onPressed: () =>
              ref.read(sessionControllerProvider.notifier).signOut(),
        ),
      ],
    );
  }
}

class _SocialPulseHeader extends StatelessWidget {
  const _SocialPulseHeader({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      CcSpacing.md,
      CcSpacing.lg,
      CcSpacing.md,
      CcSpacing.md,
    ),
    child: CcReveal(
      child: CcSpotlightSurface(
        prominent: true,
        semanticLabel: 'Campus Pulse social feed',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 540;
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      color: context.ccTheme.glowCyan,
                      size: 18,
                    ),
                    const SizedBox(width: CcSpacing.xxs),
                    Text(
                      'CAMPUS PULSE',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CcSpacing.sm),
                Text(
                  'What campus is talking about.',
                  style: compact
                      ? Theme.of(context).textTheme.headlineMedium
                      : Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: CcSpacing.xs),
                Text(
                  'People, colleges, and ideas—one living feed.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.ccTheme.textSecondary,
                  ),
                ),
              ],
            );
            final action = CcPrimaryButton(
              label: 'Post',
              icon: Icons.add_rounded,
              expand: compact,
              onPressed: onCreate,
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  copy,
                  const SizedBox(height: CcSpacing.lg),
                  action,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: copy),
                const SizedBox(width: CcSpacing.xl),
                action,
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.supportingText});
  final String title;
  final String supportingText;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      CcSpacing.md,
      CcSpacing.lg,
      CcSpacing.md,
      CcSpacing.md,
    ),
    child: CcSectionHeader(title: title, supportingText: supportingText),
  );
}

class _SocialEmpty extends StatelessWidget {
  const _SocialEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(CcSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CcIconTile(icon: icon, semanticLabel: title),
            const SizedBox(height: CcSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: CcSpacing.xs),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}

class _SocialError extends StatelessWidget {
  const _SocialError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(CcSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CcInlineMessage(
              message: message,
              tone: CcMessageTone.danger,
              liveRegion: true,
            ),
            const SizedBox(height: CcSpacing.md),
            CcPrimaryButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              onPressed: () => unawaited(onRetry()),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showComments(
  BuildContext context,
  WidgetRef ref,
  SocialPost post,
) async {
  final composer = TextEditingController();
  var comments = await ref.read(socialRepositoryProvider).loadComments(post.id);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .78,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(CcSpacing.md),
                  child: CcSectionHeader(
                    title: 'Comments',
                    supportingText: 'Join the conversation respectfully.',
                  ),
                ),
                Expanded(
                  child: comments.isEmpty
                      ? const _SocialEmpty(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'No comments yet',
                          message: 'Be the first person to respond.',
                        )
                      : ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (context, index) => ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                comments[index].authorName.characters.first
                                    .toUpperCase(),
                              ),
                            ),
                            title: Text(comments[index].authorName),
                            subtitle: Text(comments[index].body),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(CcSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: composer,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Add a comment',
                          ),
                        ),
                      ),
                      const SizedBox(width: CcSpacing.sm),
                      IconButton.filled(
                        tooltip: 'Post comment',
                        onPressed: () async {
                          if (composer.text.trim().isEmpty) {
                            return;
                          }
                          await ref
                              .read(socialRepositoryProvider)
                              .addComment(post.id, composer.text);
                          composer.clear();
                          comments = await ref
                              .read(socialRepositoryProvider)
                              .loadComments(post.id);
                          setModalState(() {});
                          ref.invalidate(socialFeedControllerProvider);
                        },
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  composer.dispose();
}

Future<void> _showPersonActions(
  BuildContext context,
  WidgetRef ref,
  SocialPost post,
) async {
  final currentUserId = ref.read(sessionControllerProvider).userId;
  if (currentUserId == post.authorUserId) return;
  await showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CcSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CcSectionHeader(
              title: post.authorName,
              supportingText: post.username == null
                  ? 'CampusConnect member'
                  : '@${post.username}',
            ),
            const SizedBox(height: CcSpacing.md),
            CcPrimaryButton(
              label: 'Follow',
              icon: Icons.person_add_alt_1_rounded,
              onPressed: () async {
                await ref
                    .read(socialRepositoryProvider)
                    .toggleFollow(post.authorUserId);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: CcSpacing.sm),
            CcSecondaryButton(
              label: 'Send message request',
              icon: Icons.mark_chat_unread_outlined,
              onPressed: () async {
                Navigator.pop(context);
                await _composeMessageRequest(context, ref, post);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _composeMessageRequest(
  BuildContext context,
  WidgetRef ref,
  SocialPost post,
) async {
  final controller = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Message ${post.authorName}'),
      content: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 6,
        maxLength: 2000,
        decoration: const InputDecoration(labelText: 'Introduce yourself'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (controller.text.trim().isEmpty) return;
            await ref
                .read(socialRepositoryProvider)
                .sendMessageRequest(post.authorUserId, controller.text);
            ref.invalidate(socialInboxProvider);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Send request'),
        ),
      ],
    ),
  );
  controller.dispose();
}

Future<void> _showPostOptions(
  BuildContext context,
  WidgetRef ref,
  SocialPost post,
) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Report post'),
            onTap: () async {
              Navigator.pop(context);
              await ref
                  .read(socialRepositoryProvider)
                  .reportPost(post.id, 'other');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report submitted for moderator review.'),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_off_outlined),
            title: const Text('Block account'),
            onTap: () async {
              Navigator.pop(context);
              await ref
                  .read(socialRepositoryProvider)
                  .blockUser(post.authorUserId);
              ref.invalidate(socialFeedControllerProvider);
            },
          ),
        ],
      ),
    ),
  );
}

SocialUpload _socialUpload(String name, Uint8List bytes) {
  final extension = name.split('.').last.toLowerCase();
  final kind = switch (extension) {
    'mp4' || 'webm' => SocialMediaKind.video,
    'pdf' => SocialMediaKind.document,
    _ => SocialMediaKind.image,
  };
  final mime = switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'mp4' => 'video/mp4',
    'webm' => 'video/webm',
    'pdf' => 'application/pdf',
    _ => 'application/octet-stream',
  };
  return SocialUpload(name: name, bytes: bytes, kind: kind, mimeType: mime);
}

IconData _mediaIcon(SocialMediaKind kind) => switch (kind) {
  SocialMediaKind.image => Icons.image_outlined,
  SocialMediaKind.video => Icons.movie_outlined,
  SocialMediaKind.document => Icons.description_outlined,
};

String _message(Object error) =>
    error is AppFailure ? error.message : 'Something went wrong. Try again.';

String _relativeTime(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return 'now';
  if (difference.inHours < 1) return '${difference.inMinutes}m';
  if (difference.inDays < 1) return '${difference.inHours}h';
  if (difference.inDays < 7) return '${difference.inDays}d';
  return '${date.day}/${date.month}/${date.year}';
}
