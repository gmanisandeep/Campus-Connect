import 'dart:async';

import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/core/networking/connectivity_service.dart';
import 'package:campus_connect/core/theme/app_tokens.dart';
import 'package:campus_connect/core/widgets/async_state_views.dart';
import 'package:campus_connect/core/widgets/status_badge.dart';
import 'package:campus_connect/features/academics/domain/academic_access.dart';
import 'package:campus_connect/features/academics/domain/academic_dashboard.dart';
import 'package:campus_connect/features/academics/domain/attendance_draft.dart';
import 'package:campus_connect/features/academics/presentation/controllers/academic_dashboard_controller.dart';
import 'package:campus_connect/features/academics/presentation/controllers/attendance_draft_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AcademicsPage extends ConsumerWidget {
  const AcademicsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final dashboard = ref.watch(academicDashboardControllerProvider);
    final targetDate = ref.watch(academicTargetDateProvider);
    final submission = ref.watch(attendanceSubmissionControllerProvider);
    final drafts = ref.watch(attendanceDraftControllerProvider);
    final connectivity = ref.watch(connectivityProvider);
    final networkStatus = connectivity.isLoading || connectivity.hasError
        ? null
        : connectivity.valueOrNull;
    final isFaculty = session.activeRole == AppRole.faculty;
    final grant = session.activeGrant;
    final loadedDraftBook = drafts.isLoading || drafts.hasError
        ? null
        : drafts.valueOrNull;
    final scopedDraftBook =
        session.isAuthenticated &&
            session.userId != null &&
            grant != null &&
            loadedDraftBook != null
        ? AttendanceDraftBook({
            for (final draft in loadedDraftBook.drafts.values)
              if (draft.matchesAuthority(
                expectedUserId: session.userId!,
                expectedMembershipId: grant.membershipId,
                expectedInstitutionId: grant.institutionId,
                expectedSelectionKey: grant.selectionKey,
              ))
                draft.storageKey: draft,
          })
        : null;
    final submissionError = submission.whenOrNull(
      error: (error, _) => _messageFor(error),
    );
    final draftError = drafts.whenOrNull(
      error: (error, _) => _messageFor(error),
    );

    ref.listen(academicDashboardControllerProvider, (_, next) {
      if (next.isLoading || next.hasError) return;
      final data = next.valueOrNull;
      if (data != null && targetDate == null) {
        ref
            .read(academicTargetDateProvider.notifier)
            .rememberServerToday(data.date);
      }
      if (data?.role == AppRole.faculty) {
        unawaited(
          ref
              .read(attendanceDraftControllerProvider.notifier)
              .reconcile(data!, historical: targetDate != null),
        );
      }
    });

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(academicDashboardControllerProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: Text(isFaculty ? 'Faculty academics' : 'Academics'),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (submissionError != null) ...[
                    _InlineError(message: submissionError),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (isFaculty && draftError != null) ...[
                    _InlineError(
                      message:
                          'Secure attendance drafts are unavailable. $draftError',
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (targetDate != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => ref
                            .read(academicTargetDateProvider.notifier)
                            .showToday(),
                        icon: const Icon(Icons.today_outlined),
                        label: const Text('Back to today'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  dashboard.when(
                    skipLoadingOnReload: false,
                    skipLoadingOnRefresh: false,
                    loading: () => const AppSkeleton(lines: 8),
                    error: (error, _) => AppErrorState(
                      message: _messageFor(error),
                      onRetry: () => unawaited(
                        ref
                            .read(academicDashboardControllerProvider.notifier)
                            .refresh(),
                      ),
                    ),
                    data: (data) => _DashboardBody(
                      dashboard: data,
                      canRecord: canSubmitAttendance(session.activeGrant),
                      submitting: submission.isLoading,
                      draftBook: scopedDraftBook,
                      draftsReady: scopedDraftBook != null,
                      networkStatus: networkStatus,
                      viewingHistoricalDate: targetDate != null,
                      onOpenDraft: (draft) async {
                        if (sameAttendanceDate(draft.sessionDate, data.date)) {
                          await ref
                              .read(
                                academicDashboardControllerProvider.notifier,
                              )
                              .refresh();
                        } else {
                          ref
                              .read(academicTargetDateProvider.notifier)
                              .showDraftDate(draft.sessionDate);
                        }
                      },
                      onSave: (scheduledClass, statuses) => _runDraftAction(
                        context,
                        () => ref
                            .read(attendanceDraftControllerProvider.notifier)
                            .save(
                              dashboard: data,
                              scheduledClass: scheduledClass,
                              statuses: statuses,
                            ),
                        successMessage: 'Draft saved securely on this device.',
                      ),
                      onDiscard: (draft) => _confirmDiscard(
                        context,
                        () => ref
                            .read(attendanceDraftControllerProvider.notifier)
                            .discard(draft),
                      ),
                      onSubmit: (scheduledClass, statuses) => ref
                          .read(attendanceSubmissionControllerProvider.notifier)
                          .submit(
                            scheduledClass: scheduledClass,
                            statuses: statuses,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.dashboard,
    required this.canRecord,
    required this.submitting,
    required this.draftBook,
    required this.draftsReady,
    required this.networkStatus,
    required this.viewingHistoricalDate,
    required this.onOpenDraft,
    required this.onSave,
    required this.onDiscard,
    required this.onSubmit,
  });

  final AcademicDashboard dashboard;
  final bool canRecord;
  final bool submitting;
  final AttendanceDraftBook? draftBook;
  final bool draftsReady;
  final NetworkStatus? networkStatus;
  final bool viewingHistoricalDate;
  final Future<void> Function(AttendanceDraft draft) onOpenDraft;
  final Future<void> Function(
    ScheduledClass scheduledClass,
    Map<String, AttendanceStatus> statuses,
  )
  onSave;
  final Future<void> Function(AttendanceDraft draft) onDiscard;
  final Future<void> Function(
    ScheduledClass scheduledClass,
    Map<String, AttendanceStatus> statuses,
  )
  onSubmit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        MaterialLocalizations.of(context).formatFullDate(dashboard.date),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(
        dashboard.role == AppRole.student
            ? "Today's timetable"
            : "Today's assigned classes",
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: AppSpacing.sm),
      if (dashboard.schedule.isEmpty)
        const AppEmptyState(
          title: 'No classes today',
          message: 'Scheduled classes will appear here.',
          icon: Icons.event_available_outlined,
        )
      else if (dashboard.role == AppRole.student)
        for (final scheduledClass in dashboard.schedule)
          _StudentScheduleCard(scheduledClass: scheduledClass)
      else
        for (final scheduledClass in dashboard.schedule)
          _FacultyClassCard(
            key: ValueKey(scheduledClass.timetableEntryId),
            scheduledClass: scheduledClass,
            sessionDate: dashboard.date,
            canRecord: canRecord,
            submitting: submitting,
            draft: draftBook?.forClass(scheduledClass, dashboard.date),
            draftsReady: draftsReady,
            networkStatus: networkStatus,
            allowNewSubmission: !viewingHistoricalDate,
            onSave: (statuses) => onSave(scheduledClass, statuses),
            onDiscard: (draft) => onDiscard(draft),
            onSubmit: (statuses) => onSubmit(scheduledClass, statuses),
          ),
      if (dashboard.role == AppRole.faculty && _otherDrafts.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Saved on this device',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Older or changed-class drafts remain visible here. '
          'They are never submitted automatically.',
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final draft in _otherDrafts)
          _AttendanceDraftRecoveryCard(
            draft: draft,
            onOpen: networkStatus == NetworkStatus.online
                ? () => unawaited(onOpenDraft(draft))
                : null,
            onDiscard: draft.state == AttendanceDraftState.submissionUncertain
                ? null
                : () => unawaited(onDiscard(draft)),
          ),
      ],
      if (dashboard.role == AppRole.student) ...[
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Attendance summary',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (dashboard.attendanceSummary.isEmpty)
          const AppEmptyState(
            title: 'No attendance yet',
            message: 'Your subject attendance will appear after classes.',
            icon: Icons.fact_check_outlined,
          )
        else
          for (final summary in dashboard.attendanceSummary)
            _AttendanceSummaryCard(summary: summary),
      ],
    ],
  );

  List<AttendanceDraft> get _otherDrafts {
    final book = draftBook;
    if (book == null) return const [];
    final visibleKeys = <String>{};
    for (final scheduledClass in dashboard.schedule) {
      final draft = book.forClass(scheduledClass, dashboard.date);
      if (draft != null) visibleKeys.add(draft.storageKey);
    }
    final drafts = [
      for (final draft in book.drafts.values)
        if (!visibleKeys.contains(draft.storageKey)) draft,
    ]..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    return drafts;
  }
}

class _AttendanceDraftRecoveryCard extends StatelessWidget {
  const _AttendanceDraftRecoveryCard({
    required this.draft,
    required this.onOpen,
    required this.onDiscard,
  });

  final AttendanceDraft draft;
  final VoidCallback? onOpen;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) => Card(
    key: Key('attendance-draft-recovery-${draft.storageKey}'),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${draft.subjectCode} · ${draft.subjectName}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${MaterialLocalizations.of(context).formatMediumDate(draft.sessionDate)}'
            ' · ${draft.startsAt}–${draft.endsAt}'
            ' · ${draft.roster.length} students',
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(
              label: _recoveryDraftLabel(draft.state),
              status: _recoveryDraftStatus(draft.state),
            ),
          ),
          if (draft.state == AttendanceDraftState.submissionUncertain) ...[
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Pending confirmation — not confirmed. Checking loads '
              'authoritative server data; it never submits automatically.',
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.manage_search_outlined),
            label: Text(
              draft.state == AttendanceDraftState.submissionUncertain
                  ? onOpen == null
                        ? 'Check when online'
                        : 'Check server status'
                  : onOpen == null
                  ? 'Review when online'
                  : 'Review class date',
            ),
          ),
          if (onDiscard != null)
            TextButton.icon(
              onPressed: onDiscard,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Discard draft'),
            ),
        ],
      ),
    ),
  );
}

class _StudentScheduleCard extends StatelessWidget {
  const _StudentScheduleCard({required this.scheduledClass});

  final ScheduledClass scheduledClass;

  @override
  Widget build(BuildContext context) => Card(
    key: Key('student-class-${scheduledClass.timetableEntryId}'),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimeBlock(
            startsAt: scheduledClass.startsAt,
            endsAt: scheduledClass.endsAt,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${scheduledClass.subjectCode} · '
                  '${scheduledClass.subjectName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${scheduledClass.sectionName} · '
                  '${scheduledClass.room}',
                ),
                const SizedBox(height: AppSpacing.sm),
                StatusBadge(
                  label: scheduledClass.attendanceSubmitted
                      ? 'Attendance recorded'
                      : 'Scheduled',
                  status: scheduledClass.attendanceSubmitted
                      ? AppStatus.success
                      : AppStatus.neutral,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _FacultyClassCard extends StatefulWidget {
  const _FacultyClassCard({
    required this.scheduledClass,
    required this.sessionDate,
    required this.canRecord,
    required this.submitting,
    required this.draft,
    required this.draftsReady,
    required this.networkStatus,
    required this.allowNewSubmission,
    required this.onSave,
    required this.onDiscard,
    required this.onSubmit,
    super.key,
  });

  final ScheduledClass scheduledClass;
  final DateTime sessionDate;
  final bool canRecord;
  final bool submitting;
  final AttendanceDraft? draft;
  final bool draftsReady;
  final NetworkStatus? networkStatus;
  final bool allowNewSubmission;
  final Future<void> Function(Map<String, AttendanceStatus> statuses) onSave;
  final Future<void> Function(AttendanceDraft draft) onDiscard;
  final Future<void> Function(Map<String, AttendanceStatus> statuses) onSubmit;

  @override
  State<_FacultyClassCard> createState() => _FacultyClassCardState();
}

class _FacultyClassCardState extends State<_FacultyClassCard> {
  late Map<String, AttendanceStatus> _statuses;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _statuses = _initialStatuses();
  }

  @override
  void didUpdateWidget(covariant _FacultyClassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scheduledClass != widget.scheduledClass ||
        oldWidget.draft?.updatedAt != widget.draft?.updatedAt ||
        oldWidget.draft?.state != widget.draft?.state) {
      _statuses = _initialStatuses();
      _dirty = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduledClass = widget.scheduledClass;
    final draft = widget.draft;
    final draftIsCurrent = draft == null || _draftIsCurrent(draft);
    final draftState = draftIsCurrent
        ? draft?.state
        : AttendanceDraftState.needsReview;
    final pending = draftState == AttendanceDraftState.submissionUncertain;
    final needsReview = draftState == AttendanceDraftState.needsReview;
    final online = widget.networkStatus == NetworkStatus.online;
    final canEdit =
        widget.canRecord &&
        widget.draftsReady &&
        widget.allowNewSubmission &&
        !widget.submitting &&
        !pending &&
        !needsReview;
    final canSubmit =
        widget.canRecord &&
        widget.draftsReady &&
        online &&
        !widget.submitting &&
        !needsReview &&
        widget.allowNewSubmission;
    final canSave = canEdit && (draft == null || _dirty);
    return Card(
      child: ExpansionTile(
        key: Key('faculty-class-${scheduledClass.timetableEntryId}'),
        leading: const Icon(Icons.co_present_outlined),
        title: Text(
          '${scheduledClass.subjectCode} · ${scheduledClass.subjectName}',
        ),
        subtitle: Text(
          '${scheduledClass.startsAt}–${scheduledClass.endsAt} · '
          '${scheduledClass.sectionName} · ${scheduledClass.room}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('${scheduledClass.roster.length} students'),
                Semantics(
                  liveRegion: true,
                  child: StatusBadge(
                    label: _draftLabel(
                      scheduledClass: scheduledClass,
                      draftState: draftState,
                      dirty: _dirty,
                    ),
                    status: _draftBadgeStatus(
                      scheduledClass: scheduledClass,
                      draftState: draftState,
                      dirty: _dirty,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!scheduledClass.attendanceSubmitted && pending) ...[
            const SizedBox(height: AppSpacing.xs),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'The previous request may have reached the server. '
                'Only this exact frozen submission can be retried.',
              ),
            ),
          ],
          if (!scheduledClass.attendanceSubmitted && needsReview) ...[
            const SizedBox(height: AppSpacing.xs),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'The class, roster, permission, or server result changed. '
                'Refresh and review before recording attendance.',
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (scheduledClass.roster.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('No enrolled students are available.'),
            )
          else
            for (final student in scheduledClass.roster)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(student.displayName),
                trailing: scheduledClass.attendanceSubmitted
                    ? StatusBadge(
                        label: student.status?.label ?? 'Not marked',
                        status: _badgeStatus(student.status),
                      )
                    : Tooltip(
                        message: 'Attendance status for ${student.displayName}',
                        child: DropdownButton<AttendanceStatus>(
                          key: Key('attendance-status-${student.userId}'),
                          value: _statuses[student.userId],
                          onChanged: !canEdit
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _statuses[student.userId] = value;
                                    _dirty =
                                        draft?.hasStatuses(_statuses) != true;
                                  });
                                },
                          items: [
                            for (final status in AttendanceStatus.values)
                              DropdownMenuItem(
                                value: status,
                                child: Text(status.label),
                              ),
                          ],
                        ),
                      ),
              ),
          if (!scheduledClass.attendanceSubmitted &&
              scheduledClass.roster.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            if (widget.canRecord)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!pending && !needsReview)
                    OutlinedButton.icon(
                      key: Key(
                        'save-attendance-draft-'
                        '${scheduledClass.timetableEntryId}',
                      ),
                      onPressed: canSave
                          ? () => unawaited(
                              widget.onSave(Map.unmodifiable(_statuses)),
                            )
                          : null,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        draft == null ? 'Save draft' : 'Save changes',
                      ),
                    ),
                  if (draft != null && !pending) ...[
                    const SizedBox(height: AppSpacing.xs),
                    TextButton.icon(
                      key: Key(
                        'discard-attendance-draft-'
                        '${scheduledClass.timetableEntryId}',
                      ),
                      onPressed: widget.submitting
                          ? null
                          : () => unawaited(widget.onDiscard(draft)),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Discard draft'),
                    ),
                  ],
                  if (!needsReview) ...[
                    const SizedBox(height: AppSpacing.xs),
                    FilledButton.icon(
                      key: Key(
                        'submit-attendance-${scheduledClass.timetableEntryId}',
                      ),
                      onPressed: canSubmit
                          ? () => unawaited(
                              widget.onSubmit(Map.unmodifiable(_statuses)),
                            )
                          : null,
                      icon: widget.submitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              pending
                                  ? Icons.sync_outlined
                                  : Icons.fact_check_outlined,
                            ),
                      label: Text(
                        _submitLabel(
                          submitting: widget.submitting,
                          draftsReady: widget.draftsReady,
                          online: online,
                          pending: pending,
                          allowNewSubmission: widget.allowNewSubmission,
                        ),
                      ),
                    ),
                  ],
                  if (!online) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.networkStatus == NetworkStatus.offline
                          ? 'Offline: drafts can still be saved; submission '
                                'waits for a connection.'
                          : 'Checking the connection before submission...',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (!widget.allowNewSubmission && !pending) ...[
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Past dates are read-only for new attendance. '
                      'Use server-status review for saved work.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (!widget.allowNewSubmission && pending) ...[
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Past pending work is checked against server data; '
                      'it is never resubmitted from this screen.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              )
            else
              const Text(
                'You can view this roster but cannot record attendance.',
              ),
          ],
        ],
      ),
    );
  }

  Map<String, AttendanceStatus> _initialStatuses() => {
    for (final student in widget.scheduledClass.roster)
      student.userId: _draftIsCurrent(widget.draft)
          ? widget.draft!.statuses[student.userId]!
          : student.status ?? AttendanceStatus.present,
  };

  bool _draftIsCurrent(AttendanceDraft? draft) =>
      draft != null &&
      draft.matchesClass(widget.scheduledClass, widget.sessionDate) &&
      draft.rosterMatches(widget.scheduledClass);
}

class _AttendanceSummaryCard extends StatelessWidget {
  const _AttendanceSummaryCard({required this.summary});

  final SubjectAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final percentage = summary.percentage;
    final percentageLabel = percentage == null
        ? 'No sessions yet'
        : '${percentage.toStringAsFixed(1)}%';
    return Card(
      key: Key('attendance-summary-${summary.courseOfferingId}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.subjectCode,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        summary.subjectName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                StatusBadge(label: percentageLabel, status: AppStatus.neutral),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: 'Attendance $percentageLabel',
              child: LinearProgressIndicator(
                value: percentage == null ? 0 : percentage / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${summary.attendedSessions} attended of '
              '${summary.totalSessions} · '
              '${summary.excusedSessions} excused',
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({required this.startsAt, required this.endsAt});

  final String startsAt;
  final String endsAt;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'From $startsAt to $endsAt',
    child: ExcludeSemantics(
      child: Column(
        children: [
          Text(startsAt, style: Theme.of(context).textTheme.titleMedium),
          Text(endsAt, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: const Text('Attendance action unavailable'),
        subtitle: Text(message),
      ),
    ),
  );
}

String _draftLabel({
  required ScheduledClass scheduledClass,
  required AttendanceDraftState? draftState,
  required bool dirty,
}) {
  if (scheduledClass.attendanceSubmitted) return 'Submitted';
  if (dirty) return 'Unsaved changes — not submitted';
  return switch (draftState) {
    null => 'Not submitted',
    AttendanceDraftState.saved => 'Draft — saved on this device',
    AttendanceDraftState.submissionUncertain =>
      'Pending confirmation — not confirmed',
    AttendanceDraftState.needsReview => 'Needs review — not submitted',
  };
}

AppStatus _draftBadgeStatus({
  required ScheduledClass scheduledClass,
  required AttendanceDraftState? draftState,
  required bool dirty,
}) {
  if (scheduledClass.attendanceSubmitted) return AppStatus.success;
  if (dirty) return AppStatus.warning;
  return switch (draftState) {
    null => AppStatus.neutral,
    AttendanceDraftState.saved => AppStatus.pending,
    AttendanceDraftState.submissionUncertain => AppStatus.warning,
    AttendanceDraftState.needsReview => AppStatus.danger,
  };
}

String _recoveryDraftLabel(AttendanceDraftState state) => switch (state) {
  AttendanceDraftState.saved => 'Draft — saved on this device',
  AttendanceDraftState.submissionUncertain =>
    'Pending confirmation — not confirmed',
  AttendanceDraftState.needsReview => 'Needs review — not submitted',
};

AppStatus _recoveryDraftStatus(AttendanceDraftState state) => switch (state) {
  AttendanceDraftState.saved => AppStatus.pending,
  AttendanceDraftState.submissionUncertain => AppStatus.warning,
  AttendanceDraftState.needsReview => AppStatus.danger,
};

String _submitLabel({
  required bool submitting,
  required bool draftsReady,
  required bool online,
  required bool pending,
  required bool allowNewSubmission,
}) {
  if (submitting) return 'Submitting…';
  if (!draftsReady) return 'Preparing secure drafts…';
  if (!allowNewSubmission) return 'Past date — check status';
  if (!online) return pending ? 'Retry when online' : 'Submit when online';
  return pending ? 'Retry exact submission' : 'Submit attendance';
}

Future<void> _runDraftAction(
  BuildContext context,
  Future<void> Function() action, {
  required String successMessage,
}) async {
  try {
    await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
  } on Object catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_messageFor(error))));
  }
}

Future<void> _confirmDiscard(
  BuildContext context,
  Future<void> Function() discard,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Discard attendance draft?'),
      content: const Text(
        'The saved marks on this device will be deleted. '
        'This does not change any server attendance.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep draft'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Discard'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await _runDraftAction(context, discard, successMessage: 'Draft discarded.');
}

String _messageFor(Object error) => error is AppFailure
    ? error.message
    : 'Unable to load academic information right now.';

AppStatus _badgeStatus(AttendanceStatus? status) => switch (status) {
  AttendanceStatus.present => AppStatus.success,
  AttendanceStatus.late => AppStatus.warning,
  AttendanceStatus.absent => AppStatus.danger,
  AttendanceStatus.excused => AppStatus.neutral,
  null => AppStatus.pending,
};
