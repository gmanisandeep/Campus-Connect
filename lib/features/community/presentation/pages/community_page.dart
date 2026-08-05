import 'dart:async';

import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_ambient_background.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_button.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_data_display.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_feedback.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_navigation.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_surface.dart';
import 'package:campus_connect/features/affiliation/presentation/widgets/student_affiliation_panel.dart';
import 'package:campus_connect/features/community/domain/community.dart';
import 'package:campus_connect/features/community/presentation/controllers/community_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({this.standalone = false, super.key});

  final bool standalone;

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  final _composer = TextEditingController();
  int _section = 0;
  CommunityContact? _activeContact;
  AsyncValue<CommunityConversation>? _conversation;
  bool _sending = false;
  String? _sendError;

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(communityOverviewControllerProvider);
    final content = switch (_section) {
      0 => _CommunityOverviewBody(
        overview: overview,
        section: 0,
        standalone: widget.standalone,
        onSectionChanged: _selectSection,
        onRefresh: _refresh,
        onContactSelected: _openContact,
      ),
      1 =>
        _activeContact == null
            ? _CommunityOverviewBody(
                overview: overview,
                section: 1,
                standalone: widget.standalone,
                onSectionChanged: _selectSection,
                onRefresh: _refresh,
                onContactSelected: _openContact,
              )
            : _conversationBody(overview.valueOrNull),
      _ => const _VerificationBody(),
    };

    if (!widget.standalone) return content;

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: CcNavigationBar(
        items: const [
          CcNavigationItem(
            label: 'Feed',
            icon: Icons.dynamic_feed_outlined,
            selectedIcon: Icons.dynamic_feed_rounded,
          ),
          CcNavigationItem(
            label: 'Messages',
            icon: Icons.forum_outlined,
            selectedIcon: Icons.forum_rounded,
          ),
          CcNavigationItem(
            label: 'Access',
            icon: Icons.verified_user_outlined,
            selectedIcon: Icons.verified_user_rounded,
          ),
        ],
        selectedIndex: _section,
        onSelected: _selectSection,
      ),
      body: CcAmbientBackground(
        tone: CcAmbientTone.quiet,
        child: SafeArea(bottom: false, child: content),
      ),
    );
  }

  Widget _conversationBody(CommunityOverview? overview) {
    final contact = _activeContact!;
    final conversation = _conversation ?? const AsyncLoading();
    return Column(
      children: [
        _CommunityHeader(
          title: contact.participantName,
          supportingText: contact.participantRole,
          leading: IconButton(
            tooltip: 'Back to conversations',
            onPressed: () => setState(() {
              _activeContact = null;
              _conversation = null;
              _sendError = null;
            }),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        Expanded(
          child: conversation.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _CommunityError(
              message: _messageFor(error),
              onRetry: () => _openContact(contact),
            ),
            data: (data) => _MessageList(
              messages: data.messages,
              currentUserId: ref.read(sessionControllerProvider).userId,
            ),
          ),
        ),
        if (_sendError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CcSpacing.md,
              0,
              CcSpacing.md,
              CcSpacing.xs,
            ),
            child: CcInlineMessage(
              message: _sendError!,
              tone: CcMessageTone.danger,
              liveRegion: true,
            ),
          ),
        _MessageComposer(
          controller: _composer,
          sending: _sending,
          enabled: overview != null,
          onSend: overview == null ? null : () => _send(overview),
        ),
      ],
    );
  }

  void _selectSection(int section) {
    setState(() {
      _section = section;
      if (section != 1) {
        _activeContact = null;
        _conversation = null;
      }
    });
  }

  Future<void> _refresh() =>
      ref.read(communityOverviewControllerProvider.notifier).refresh();

  Future<void> _openContact(CommunityContact contact) async {
    setState(() {
      _section = 1;
      _activeContact = contact;
      _sendError = null;
      _conversation = contact.threadId == null
          ? const AsyncData(CommunityConversation(threadId: null, messages: []))
          : const AsyncLoading();
    });
    final threadId = contact.threadId;
    if (threadId == null) return;
    try {
      final loaded = await ref
          .read(communityRepositoryProvider)
          .loadConversation(threadId);
      if (!mounted ||
          _activeContact?.participantUserId != contact.participantUserId) {
        return;
      }
      setState(() => _conversation = AsyncData(loaded));
    } on Object catch (error, stackTrace) {
      if (!mounted ||
          _activeContact?.participantUserId != contact.participantUserId) {
        return;
      }
      setState(() => _conversation = AsyncError(error, stackTrace));
    }
  }

  Future<void> _send(CommunityOverview overview) async {
    final contact = _activeContact;
    final body = _composer.text.trim();
    if (contact == null || body.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final updated = await ref
          .read(communityRepositoryProvider)
          .sendMessage(
            institutionId: overview.institutionId,
            threadId: contact.threadId,
            facultyUserId: overview.viewerKind == CommunityViewerKind.faculty
                ? null
                : contact.participantUserId,
            clientMessageId: const Uuid().v4(),
            body: body,
          );
      if (!mounted ||
          _activeContact?.participantUserId != contact.participantUserId) {
        return;
      }
      _composer.clear();
      setState(() {
        final lastMessage = updated.messages.isEmpty
            ? null
            : updated.messages.last;
        _activeContact = CommunityContact(
          participantUserId: contact.participantUserId,
          participantName: contact.participantName,
          participantRole: contact.participantRole,
          threadId: updated.threadId,
          lastMessage: lastMessage?.body,
          lastMessageAt: lastMessage?.sentAt,
        );
        _conversation = AsyncData(updated);
      });
      unawaited(_refresh());
    } on Object catch (error) {
      if (mounted) setState(() => _sendError = _messageFor(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _CommunityOverviewBody extends StatelessWidget {
  const _CommunityOverviewBody({
    required this.overview,
    required this.section,
    required this.standalone,
    required this.onSectionChanged,
    required this.onRefresh,
    required this.onContactSelected,
  });

  final AsyncValue<CommunityOverview> overview;
  final int section;
  final bool standalone;
  final ValueChanged<int> onSectionChanged;
  final Future<void> Function() onRefresh;
  final ValueChanged<CommunityContact> onContactSelected;

  @override
  Widget build(BuildContext context) => overview.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, _) =>
        _CommunityError(message: _messageFor(error), onRetry: onRefresh),
    data: (data) => RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _CommunityHeader(
              title: section == 0 ? 'Campus Feed' : 'Faculty messages',
              supportingText: data.institutionName,
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
                if (data.isProvisional) ...[
                  const CcInlineMessage(
                    message:
                        'Community access is active while college verification '
                        'is pending. Attendance, Calendar, Courses, and academic '
                        'records remain locked.',
                    tone: CcMessageTone.info,
                  ),
                  const SizedBox(height: CcSpacing.md),
                ],
                if (!standalone)
                  Padding(
                    padding: const EdgeInsets.only(bottom: CcSpacing.md),
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          icon: Icon(Icons.dynamic_feed_outlined),
                          label: Text('Feed'),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon: Icon(Icons.forum_outlined),
                          label: Text('Messages'),
                        ),
                      ],
                      selected: {section},
                      onSelectionChanged: (value) =>
                          onSectionChanged(value.single),
                    ),
                  ),
                if (section == 0)
                  if (data.feed.isEmpty)
                    const _EmptyCommunityState(
                      icon: Icons.campaign_outlined,
                      title: 'No official updates yet',
                      message:
                          'College announcements will appear here when an '
                          'authorized publisher posts them.',
                    )
                  else
                    for (final post in data.feed) ...[
                      _FeedPostCard(post: post),
                      const SizedBox(height: CcSpacing.sm),
                    ]
                else if (data.contacts.isEmpty)
                  _EmptyCommunityState(
                    icon: Icons.forum_outlined,
                    title: data.viewerKind == CommunityViewerKind.faculty
                        ? 'No student conversations'
                        : 'No Faculty contacts available',
                    message: data.viewerKind == CommunityViewerKind.faculty
                        ? 'Student messages for this college will appear here.'
                        : 'Verified Faculty members will appear here after the '
                              'college assigns their accounts.',
                  )
                else
                  for (final contact in data.contacts) ...[
                    _ContactRow(contact: contact, onTap: onContactSelected),
                    const SizedBox(height: CcSpacing.sm),
                  ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CommunityHeader extends StatelessWidget {
  const _CommunityHeader({
    required this.title,
    required this.supportingText,
    this.leading,
  });

  final String title;
  final String supportingText;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      CcSpacing.md,
      CcSpacing.lg,
      CcSpacing.md,
      CcSpacing.md,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: CcSpacing.xs)],
        Expanded(
          child: CcSectionHeader(title: title, supportingText: supportingText),
        ),
      ],
    ),
  );
}

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({required this.post});

  final CommunityFeedPost post;

  @override
  Widget build(BuildContext context) => CcSurface(
    key: ValueKey(post.id),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(post.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: CcSpacing.xs),
        Text(post.body, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: CcSpacing.md),
        Text(
          '${post.publisherName} · ${_friendlyDate(context, post.publishedAt)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: context.ccTheme.textSecondary),
        ),
      ],
    ),
  );
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.contact, required this.onTap});

  final CommunityContact contact;
  final ValueChanged<CommunityContact> onTap;

  @override
  Widget build(BuildContext context) => CcSurface(
    key: ValueKey(contact.participantUserId),
    padding: EdgeInsets.zero,
    child: ListTile(
      minTileHeight: 72,
      leading: CircleAvatar(
        child: Text(contact.participantName.characters.first.toUpperCase()),
      ),
      title: Text(contact.participantName),
      subtitle: Text(contact.lastMessage ?? contact.participantRole),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => onTap(contact),
    ),
  );
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages, required this.currentUserId});

  final List<CommunityMessage> messages;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const _EmptyCommunityState(
        icon: Icons.waving_hand_outlined,
        title: 'Start the conversation',
        message:
            'Send a plain-text message. Attachments and academic records are '
            'not shared in Community messages.',
      );
    }
    return ListView.separated(
      reverse: false,
      padding: const EdgeInsets.fromLTRB(
        CcSpacing.md,
        CcSpacing.xs,
        CcSpacing.md,
        CcSpacing.md,
      ),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: CcSpacing.xs),
      itemBuilder: (context, index) {
        final message = messages[index];
        final mine = message.senderUserId == currentUserId;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Semantics(
            label: mine ? 'You said ${message.body}' : message.body,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.symmetric(
                horizontal: CcSpacing.md,
                vertical: CcSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: mine
                    ? Theme.of(context).colorScheme.primaryContainer
                    : context.ccTheme.raisedSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(message.body),
            ),
          ),
        );
      },
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.sending,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final bool enabled;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.ccTheme.surface,
        border: Border(top: BorderSide(color: context.ccTheme.borderSubtle)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CcSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const Key('community-message-composer'),
                controller: controller,
                enabled: enabled && !sending,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Write to Faculty',
                  counterText: '',
                ),
                textInputAction: TextInputAction.newline,
              ),
            ),
            const SizedBox(width: CcSpacing.sm),
            IconButton.filled(
              key: const Key('send-community-message'),
              tooltip: sending ? 'Sending message' : 'Send message',
              onPressed: enabled && !sending ? onSend : null,
              icon: sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyCommunityState extends StatelessWidget {
  const _EmptyCommunityState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(CcSpacing.md),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
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

class _CommunityError extends StatelessWidget {
  const _CommunityError({required this.message, required this.onRetry});

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

class _VerificationBody extends ConsumerWidget {
  const _VerificationBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) => CustomScrollView(
    slivers: [
      const SliverToBoxAdapter(
        child: _CommunityHeader(
          title: 'College verification',
          supportingText:
              'Community remains available while approval is pending.',
        ),
      ),
      const SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: CcSpacing.md),
        sliver: SliverToBoxAdapter(child: StudentAffiliationPanel()),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          CcSpacing.md,
          CcSpacing.sm,
          CcSpacing.md,
          CcSpacing.xl,
        ),
        sliver: SliverToBoxAdapter(
          child: TextButton.icon(
            onPressed: () => unawaited(
              ref.read(sessionControllerProvider.notifier).signOut(),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ),
      ),
    ],
  );
}

String _messageFor(Object error) => error is AppFailure
    ? error.message
    : 'Community is temporarily unavailable. Try again.';

String _friendlyDate(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final time = MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay.fromDateTime(date));
  if (now.year == date.year && now.month == date.month && now.day == date.day) {
    return 'Today, $time';
  }
  return '${date.day}/${date.month}/${date.year}, $time';
}
