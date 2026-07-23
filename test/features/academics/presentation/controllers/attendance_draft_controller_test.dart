import 'dart:async';

import 'package:campus_connect/core/auth/access_grant.dart';
import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/auth/app_session.dart';
import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/configuration/app_config.dart';
import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/core/storage/key_value_store.dart';
import 'package:campus_connect/features/academics/data/drift_attendance_draft_store.dart';
import 'package:campus_connect/features/academics/domain/academic_dashboard.dart';
import 'package:campus_connect/features/academics/domain/attendance_draft.dart';
import 'package:campus_connect/features/academics/presentation/controllers/attendance_draft_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'attendance_draft_test_support.dart';

void main() {
  group('AttendanceDraftController', () {
    test('saves an editable, authority-scoped draft', () async {
      final store = MemoryAttendanceDraftStore();
      final container = await _facultyContainer(store);
      addTearDown(container.dispose);
      final controller = container.read(
        attendanceDraftControllerProvider.notifier,
      );

      await controller.save(
        dashboard: _dashboard(),
        scheduledClass: _dashboard().schedule.single,
        statuses: _marks,
      );

      final draft = store.drafts.single;
      expect(draft.state, AttendanceDraftState.saved);
      expect(draft.requestId, isNull);
      expect(draft.userId, 'development-user');
      expect(draft.membershipId, 'development-membership');
      expect(draft.selectionKey, 'development-institution:faculty');
      expect(draft.statuses, _marks);
      expect(
        container
            .read(attendanceDraftControllerProvider)
            .requireValue
            .drafts
            .values
            .single,
        same(draft),
      );
    });

    test(
      'an exact uncertain retry reuses its UUID after provider recreation',
      () async {
        final store = MemoryAttendanceDraftStore();
        final firstContainer = await _facultyContainer(store);
        final firstController = firstContainer.read(
          attendanceDraftControllerProvider.notifier,
        );
        var firstFactoryCalls = 0;
        final first = await firstController.beginSubmission(
          dashboard: _dashboard(),
          scheduledClass: _dashboard().schedule.single,
          statuses: _marks,
          requestIdFactory: () {
            firstFactoryCalls += 1;
            return 'request-durable';
          },
        );
        expect(firstFactoryCalls, 1);
        expect(first.state, AttendanceDraftState.submissionUncertain);
        firstContainer.dispose();

        final replacementContainer = await _facultyContainer(store);
        addTearDown(replacementContainer.dispose);
        final replacementController = replacementContainer.read(
          attendanceDraftControllerProvider.notifier,
        );
        var replacementFactoryCalls = 0;
        final retried = await replacementController.beginSubmission(
          dashboard: _dashboard(),
          scheduledClass: _dashboard().schedule.single,
          statuses: _marks,
          requestIdFactory: () {
            replacementFactoryCalls += 1;
            return 'request-must-not-be-used';
          },
        );

        expect(retried.requestId, 'request-durable');
        expect(replacementFactoryCalls, 0);
        expect(store.persistedUpserts, hasLength(1));
      },
    );

    test(
      'changed marks are rejected while a submission is uncertain',
      () async {
        final store = MemoryAttendanceDraftStore();
        final container = await _facultyContainer(store);
        addTearDown(container.dispose);
        final controller = container.read(
          attendanceDraftControllerProvider.notifier,
        );
        final pending = await controller.beginSubmission(
          dashboard: _dashboard(),
          scheduledClass: _dashboard().schedule.single,
          statuses: _marks,
          requestIdFactory: () => 'request-frozen',
        );

        await expectLater(
          controller.beginSubmission(
            dashboard: _dashboard(),
            scheduledClass: _dashboard().schedule.single,
            statuses: _changedMarks,
            requestIdFactory: () => 'request-replacement',
          ),
          throwsA(
            isA<AppFailure>().having(
              (failure) => failure.kind,
              'kind',
              FailureKind.conflict,
            ),
          ),
        );

        expect(store.drafts.single, same(pending));
        expect(store.persistedUpserts, hasLength(1));
        expect(store.drafts.single.requestId, 'request-frozen');
        expect(store.drafts.single.statuses, _marks);
      },
    );

    final failureTransitions =
        <({String label, Object error, AttendanceDraftState expected})>[
          (
            label: 'validation failure',
            error: const AppFailure(
              kind: FailureKind.validation,
              message: 'invalid marks',
            ),
            expected: AttendanceDraftState.saved,
          ),
          (
            label: 'authentication failure',
            error: const AppFailure(
              kind: FailureKind.authentication,
              message: 'session expired',
            ),
            expected: AttendanceDraftState.needsReview,
          ),
          (
            label: 'authorization failure',
            error: const AppFailure(
              kind: FailureKind.authorization,
              message: 'permission removed',
            ),
            expected: AttendanceDraftState.needsReview,
          ),
          (
            label: 'not-found failure',
            error: const AppFailure(
              kind: FailureKind.notFound,
              message: 'class removed',
            ),
            expected: AttendanceDraftState.needsReview,
          ),
          (
            label: 'conflict failure',
            error: const AppFailure(
              kind: FailureKind.conflict,
              message: 'server state changed',
            ),
            expected: AttendanceDraftState.needsReview,
          ),
          (
            label: 'connectivity failure',
            error: const AppFailure(
              kind: FailureKind.connectivity,
              message: 'offline',
            ),
            expected: AttendanceDraftState.submissionUncertain,
          ),
          (
            label: 'timeout failure',
            error: const AppFailure(
              kind: FailureKind.timeout,
              message: 'timed out',
            ),
            expected: AttendanceDraftState.submissionUncertain,
          ),
          (
            label: 'server failure',
            error: const AppFailure(
              kind: FailureKind.server,
              message: 'server unavailable',
            ),
            expected: AttendanceDraftState.submissionUncertain,
          ),
          (
            label: 'unexpected app failure',
            error: const AppFailure(
              kind: FailureKind.unexpected,
              message: 'unknown outcome',
            ),
            expected: AttendanceDraftState.submissionUncertain,
          ),
          (
            label: 'untyped failure',
            error: StateError('transport ended unexpectedly'),
            expected: AttendanceDraftState.submissionUncertain,
          ),
        ];

    for (final transition in failureTransitions) {
      test(
        '${transition.label} transitions to ${transition.expected.name}',
        () async {
          final store = MemoryAttendanceDraftStore();
          final container = await _facultyContainer(store);
          addTearDown(container.dispose);
          final controller = container.read(
            attendanceDraftControllerProvider.notifier,
          );
          final attempted = await controller.beginSubmission(
            dashboard: _dashboard(),
            scheduledClass: _dashboard().schedule.single,
            statuses: _marks,
            requestIdFactory: () => 'request-classification',
          );

          await controller.markSubmissionFailed(attempted, transition.error);

          final persisted = store.drafts.single;
          expect(persisted.state, transition.expected);
          if (transition.expected == AttendanceDraftState.submissionUncertain) {
            expect(persisted.requestId, 'request-classification');
            expect(store.persistedUpserts, hasLength(1));
          } else {
            expect(persisted.requestId, isNull);
            expect(store.persistedUpserts, hasLength(2));
          }
        },
      );
    }

    test(
      'confirmed submission deletes the durable draft and visible state',
      () async {
        final store = MemoryAttendanceDraftStore();
        final container = await _facultyContainer(store);
        addTearDown(container.dispose);
        final controller = container.read(
          attendanceDraftControllerProvider.notifier,
        );
        final attempted = await controller.beginSubmission(
          dashboard: _dashboard(),
          scheduledClass: _dashboard().schedule.single,
          statuses: _marks,
          requestIdFactory: () => 'request-confirmed',
        );

        await controller.completeSubmission(attempted);

        expect(store.drafts, isEmpty);
        expect(store.deletedKeys, [attempted.storageKey]);
        expect(
          container.read(attendanceDraftControllerProvider).requireValue.drafts,
          isEmpty,
        );
      },
    );

    test('reconcile deletes only an exact server confirmation', () async {
      final store = MemoryAttendanceDraftStore();
      final container = await _facultyContainer(store);
      addTearDown(container.dispose);
      final controller = container.read(
        attendanceDraftControllerProvider.notifier,
      );
      final attempted = await controller.beginSubmission(
        dashboard: _dashboard(),
        scheduledClass: _dashboard().schedule.single,
        statuses: _marks,
        requestIdFactory: () => 'request-reconciled',
      );

      await controller.reconcile(_dashboard(submitted: true));

      expect(store.deletedKeys, [attempted.storageKey]);
      expect(store.drafts, isEmpty);
    });

    test('reconcile freezes a non-exact server result for review', () async {
      final store = MemoryAttendanceDraftStore();
      final container = await _facultyContainer(store);
      addTearDown(container.dispose);
      final controller = container.read(
        attendanceDraftControllerProvider.notifier,
      );
      await controller.beginSubmission(
        dashboard: _dashboard(),
        scheduledClass: _dashboard().schedule.single,
        statuses: _marks,
        requestIdFactory: () => 'request-mismatch',
      );

      await controller.reconcile(
        _dashboard(
          submitted: true,
          submittedSecondStatus: AttendanceStatus.late,
        ),
      );

      expect(store.deletedKeys, isEmpty);
      expect(store.drafts.single.state, AttendanceDraftState.needsReview);
      expect(store.drafts.single.requestId, isNull);
    });

    test(
      'historical reconcile deletes an exact submitted confirmation',
      () async {
        final historicalDate = DateTime(2031, 1, 15);
        final pending = _draft(
          sessionDate: historicalDate,
          state: AttendanceDraftState.submissionUncertain,
          requestId: 'request-historical-confirmed',
        );
        final store = MemoryAttendanceDraftStore(initialDrafts: [pending]);
        final container = await _facultyContainer(store);
        addTearDown(container.dispose);

        await container
            .read(attendanceDraftControllerProvider.notifier)
            .reconcile(
              _dashboard(date: historicalDate, submitted: true),
              historical: true,
            );

        expect(store.deletedKeys, [pending.storageKey]);
        expect(store.persistedUpserts, isEmpty);
        expect(store.drafts, isEmpty);
        expect(
          container.read(attendanceDraftControllerProvider).requireValue.drafts,
          isEmpty,
        );
      },
    );

    final unresolvedHistoricalOutcomes =
        <({String label, AcademicDashboard dashboard})>[
          (
            label: 'authoritative unsubmitted class',
            dashboard: _dashboard(date: DateTime(2031, 1, 15)),
          ),
          (
            label: 'authoritative missing class',
            dashboard: _dashboard(
              date: DateTime(2031, 1, 15),
              includeClass: false,
            ),
          ),
          (
            label: 'authoritative submitted marks mismatch',
            dashboard: _dashboard(
              date: DateTime(2031, 1, 15),
              submitted: true,
              submittedSecondStatus: AttendanceStatus.late,
            ),
          ),
        ];

    for (final outcome in unresolvedHistoricalOutcomes) {
      test(
        'historical ${outcome.label} freezes uncertain draft without retry',
        () async {
          final pending = _draft(
            sessionDate: DateTime(2031, 1, 15),
            state: AttendanceDraftState.submissionUncertain,
            requestId: 'request-historical-pending',
          );
          final store = MemoryAttendanceDraftStore(initialDrafts: [pending]);
          final container = await _facultyContainer(store);
          addTearDown(container.dispose);

          await container
              .read(attendanceDraftControllerProvider.notifier)
              .reconcile(outcome.dashboard, historical: true);

          expect(store.deletedKeys, isEmpty);
          expect(store.persistedUpserts, hasLength(1));
          final reviewed = store.drafts.single;
          expect(reviewed.storageKey, pending.storageKey);
          expect(reviewed.state, AttendanceDraftState.needsReview);
          expect(reviewed.requestId, isNull);
        },
      );
    }

    test(
      'editable retention uses authoritative dashboard date, not updatedAt',
      () async {
        final currentServerDate = DateTime(2031, 2, 3);
        final expiredDespiteFreshUpdate = _draft(
          sessionDate: DateTime(2031, 1, 3),
          state: AttendanceDraftState.saved,
          updatedAt: DateTime(2031, 2, 3, 8, 29),
        );
        final retainedAtThirtyDayBoundary = _draft(
          sessionDate: DateTime(2031, 1, 4),
          state: AttendanceDraftState.saved,
          updatedAt: DateTime(2020, 1, 1),
        );
        final store = MemoryAttendanceDraftStore(
          initialDrafts: [
            expiredDespiteFreshUpdate,
            retainedAtThirtyDayBoundary,
          ],
        );
        final container = await _facultyContainer(store);
        addTearDown(container.dispose);

        await container
            .read(attendanceDraftControllerProvider.notifier)
            .reconcile(_dashboard(date: currentServerDate));

        expect(store.deletedKeys, [expiredDespiteFreshUpdate.storageKey]);
        expect(store.drafts.map((draft) => draft.storageKey), [
          retainedAtThirtyDayBoundary.storageKey,
        ]);
      },
    );

    test('uncertain and needs-review drafts never age-delete', () async {
      final uncertain = _draft(
        sessionDate: DateTime(2030, 10, 1),
        state: AttendanceDraftState.submissionUncertain,
        requestId: 'request-old-uncertain',
        updatedAt: DateTime(2030, 10, 1),
      );
      final needsReview = _draft(
        courseOfferingId: 'offering-2',
        timetableEntryId: 'entry-2',
        sessionDate: DateTime(2030, 10, 1),
        state: AttendanceDraftState.needsReview,
        updatedAt: DateTime(2030, 10, 1),
      );
      final store = MemoryAttendanceDraftStore(
        initialDrafts: [uncertain, needsReview],
      );
      final container = await _facultyContainer(store);
      addTearDown(container.dispose);

      await container
          .read(attendanceDraftControllerProvider.notifier)
          .reconcile(_dashboard(date: DateTime(2031, 2, 3)));

      expect(store.deletedKeys, isEmpty);
      expect(store.persistedUpserts, isEmpty);
      expect(
        store.drafts,
        containsAll(<AttendanceDraft>[uncertain, needsReview]),
      );
    });

    test('revoked and removed faculty scopes purge stored drafts', () async {
      final activeGrant = _facultyGrant(
        membershipId: 'membership-active',
        institutionId: 'institution-active',
      );
      final revokedGrant = _facultyGrant(
        membershipId: 'membership-revoked',
        institutionId: 'institution-revoked',
        permissions: const {AppPermission.rosterRead},
      );
      final activeDraft = _draftForGrant(activeGrant);
      final revokedDraft = _draftForGrant(revokedGrant);
      final removedDraft = _draft(
        membershipId: 'membership-removed',
        institutionId: 'institution-removed',
        selectionKey: 'institution-removed:faculty',
      );
      final store = MemoryAttendanceDraftStore(
        initialDrafts: [activeDraft, revokedDraft, removedDraft],
      );
      final session = _sessionWithGrants(
        activeGrant: activeGrant,
        grants: [activeGrant, revokedGrant],
      );
      final container = await _mutableFacultyContainer(store, session);
      addTearDown(container.dispose);

      expect(
        store.deletedKeys,
        unorderedEquals([revokedDraft.storageKey, removedDraft.storageKey]),
      );
      expect(store.drafts, [activeDraft]);
      expect(
        container
            .read(attendanceDraftControllerProvider)
            .requireValue
            .drafts
            .values,
        [activeDraft],
      );
    });

    test(
      'selectable non-current faculty scope stays stored but hidden',
      () async {
        final firstGrant = _facultyGrant(
          membershipId: 'membership-first',
          institutionId: 'institution-first',
        );
        final secondGrant = _facultyGrant(
          membershipId: 'membership-second',
          institutionId: 'institution-second',
        );
        final firstDraft = _draftForGrant(firstGrant);
        final secondDraft = _draftForGrant(secondGrant);
        final store = MemoryAttendanceDraftStore(
          initialDrafts: [firstDraft, secondDraft],
        );
        final firstSession = _sessionWithGrants(
          activeGrant: firstGrant,
          grants: [firstGrant, secondGrant],
        );
        final container = await _mutableFacultyContainer(store, firstSession);
        addTearDown(container.dispose);

        expect(store.deletedKeys, isEmpty);
        expect(store.drafts, unorderedEquals([firstDraft, secondDraft]));
        expect(
          container
              .read(attendanceDraftControllerProvider)
              .requireValue
              .drafts
              .values,
          [firstDraft],
        );

        (container.read(sessionControllerProvider.notifier)
                as _MutableSessionController)
            .replace(
              _sessionWithGrants(
                activeGrant: secondGrant,
                grants: [firstGrant, secondGrant],
              ),
            );
        await _waitUntil(
          () =>
              container
                  .read(attendanceDraftControllerProvider)
                  .valueOrNull
                  ?.drafts
                  .values
                  .singleOrNull ==
              secondDraft,
        );

        expect(store.deletedKeys, isEmpty);
        expect(store.drafts, unorderedEquals([firstDraft, secondDraft]));
      },
    );

    final identityBearingNonAuthenticatedStates =
        <
          ({String label, AppSession Function(IdentityContext identity) create})
        >[
          (
            label: 'access-blocked',
            create: (identity) => AppSession.accessBlocked(
              reason: AccessBlockReason.unavailable,
              identity: identity,
            ),
          ),
          (label: 'onboarding', create: AppSession.onboarding),
          (label: 'selection-required', create: AppSession.selectionRequired),
        ];

    for (final transition in identityBearingNonAuthenticatedStates) {
      test(
        '${transition.label} transition hides drafts while purging revoked scope',
        () async {
          final activeGrant = _facultyGrant(
            membershipId: 'membership-active',
            institutionId: 'institution-active',
          );
          final revokedGrant = _facultyGrant(
            membershipId: 'membership-revoked',
            institutionId: 'institution-revoked',
            permissions: const {AppPermission.rosterRead},
          );
          final activeDraft = _draftForGrant(activeGrant);
          final revokedDraft = _draftForGrant(revokedGrant);
          final initialSession = _sessionWithGrants(
            activeGrant: activeGrant,
            grants: [activeGrant, revokedGrant],
          );
          final store = MemoryAttendanceDraftStore(
            initialDrafts: [activeDraft],
          );
          final container = await _mutableFacultyContainer(
            store,
            initialSession,
          );
          final subscription = container.listen(
            attendanceDraftControllerProvider,
            (_, __) {},
            fireImmediately: true,
          );
          addTearDown(subscription.close);
          addTearDown(container.dispose);
          await store.upsert(revokedDraft);
          final loadStarted = Completer<void>();
          final allowLoad = Completer<void>();
          store
            ..loadStarted = loadStarted
            ..nextLoadGate = allowLoad;

          final identity = _identityWithGrants(
            grants: [activeGrant, revokedGrant],
            profileCompleted: transition.label != 'onboarding',
          );
          (container.read(sessionControllerProvider.notifier)
                  as _MutableSessionController)
              .replace(transition.create(identity));
          await loadStarted.future;

          expect(
            container
                    .read(attendanceDraftControllerProvider)
                    .valueOrNull
                    ?.drafts ??
                const <String, AttendanceDraft>{},
            isEmpty,
          );

          allowLoad.complete();
          await _waitUntil(
            () =>
                container
                    .read(attendanceDraftControllerProvider)
                    .valueOrNull
                    ?.drafts
                    .isEmpty ??
                false,
          );
          expect(store.deletedKeys, [revokedDraft.storageKey]);
          expect(store.drafts, [activeDraft]);
        },
      );
    }

    test(
      'revoking the last faculty grant hides then purges its durable draft',
      () async {
        final facultyGrant = _facultyGrant(
          membershipId: 'membership-last-faculty',
          institutionId: 'institution-last-faculty',
        );
        final draft = _draftForGrant(facultyGrant);
        final store = MemoryAttendanceDraftStore(initialDrafts: [draft]);
        final container = await _mutableFacultyContainer(
          store,
          _sessionWithGrants(activeGrant: facultyGrant, grants: [facultyGrant]),
        );
        final subscription = container.listen(
          attendanceDraftControllerProvider,
          (_, __) {},
          fireImmediately: true,
        );
        addTearDown(subscription.close);
        addTearDown(container.dispose);
        final loadStarted = Completer<void>();
        final allowLoad = Completer<void>();
        store
          ..loadStarted = loadStarted
          ..nextLoadGate = allowLoad;

        (container.read(sessionControllerProvider.notifier)
                as _MutableSessionController)
            .replace(
              AppSession.accessBlocked(
                reason: AccessBlockReason.noMembership,
                identity: _identityWithGrants(grants: const []),
              ),
            );
        await loadStarted.future;

        expect(
          container
                  .read(attendanceDraftControllerProvider)
                  .valueOrNull
                  ?.drafts ??
              const <String, AttendanceDraft>{},
          isEmpty,
        );
        expect(store.drafts, [draft]);

        allowLoad.complete();
        await _waitUntil(() => store.drafts.isEmpty);
        expect(store.deletedKeys, [draft.storageKey]);
        expect(
          container.read(attendanceDraftControllerProvider).valueOrNull?.drafts,
          isEmpty,
        );
      },
    );

    test(
      'newer authenticated session supersedes a gated blocked-state load',
      () async {
        final facultyGrant = _facultyGrant(
          membershipId: 'membership-restored',
          institutionId: 'institution-restored',
        );
        final draft = _draftForGrant(facultyGrant);
        final authenticated = _sessionWithGrants(
          activeGrant: facultyGrant,
          grants: [facultyGrant],
        );
        final store = MemoryAttendanceDraftStore(initialDrafts: [draft]);
        final container = await _mutableFacultyContainer(store, authenticated);
        final subscription = container.listen(
          attendanceDraftControllerProvider,
          (_, __) {},
          fireImmediately: true,
        );
        addTearDown(subscription.close);
        addTearDown(container.dispose);
        final loadStarted = Completer<void>();
        final allowBlockedLoad = Completer<void>();
        store
          ..loadStarted = loadStarted
          ..nextLoadGate = allowBlockedLoad;
        final sessionController =
            container.read(sessionControllerProvider.notifier)
                as _MutableSessionController;

        sessionController.replace(
          AppSession.accessBlocked(
            reason: AccessBlockReason.noMembership,
            identity: _identityWithGrants(grants: const []),
          ),
        );
        await loadStarted.future;
        expect(
          container
                  .read(attendanceDraftControllerProvider)
                  .valueOrNull
                  ?.drafts ??
              const <String, AttendanceDraft>{},
          isEmpty,
        );

        sessionController.replace(authenticated);
        allowBlockedLoad.complete();
        await _waitUntil(
          () =>
              container
                  .read(attendanceDraftControllerProvider)
                  .valueOrNull
                  ?.drafts
                  .values
                  .singleOrNull ==
              draft,
        );

        expect(store.deletedKeys, isEmpty);
        expect(store.deleteAllCalls, 0);
        expect(store.drafts, [draft]);
      },
    );

    test(
      'identity-bearing transition deletes foreign rows without exposure',
      () async {
        final facultyGrant = _facultyGrant(
          membershipId: 'membership-current',
          institutionId: 'institution-current',
        );
        final currentDraft = _draftForGrant(facultyGrant);
        final foreignDraft = _draft(
          userId: 'different-user',
          membershipId: 'membership-foreign',
          institutionId: 'institution-foreign',
          selectionKey: 'institution-foreign:faculty',
        );
        final store = MemoryAttendanceDraftStore(initialDrafts: [currentDraft]);
        final container = await _mutableFacultyContainer(
          store,
          _sessionWithGrants(activeGrant: facultyGrant, grants: [facultyGrant]),
        );
        final subscription = container.listen(
          attendanceDraftControllerProvider,
          (_, __) {},
          fireImmediately: true,
        );
        addTearDown(subscription.close);
        addTearDown(container.dispose);
        await store.upsert(foreignDraft);
        final loadStarted = Completer<void>();
        final allowLoad = Completer<void>();
        store
          ..loadStarted = loadStarted
          ..nextLoadGate = allowLoad;

        (container.read(sessionControllerProvider.notifier)
                as _MutableSessionController)
            .replace(
              AppSession.selectionRequired(
                _identityWithGrants(grants: [facultyGrant]),
              ),
            );
        await loadStarted.future;

        expect(
          container
                  .read(attendanceDraftControllerProvider)
                  .valueOrNull
                  ?.drafts ??
              const <String, AttendanceDraft>{},
          isEmpty,
        );

        allowLoad.complete();
        await _waitUntil(() => store.drafts.isEmpty);
        expect(store.deleteAllCalls, 1);
        expect(
          container.read(attendanceDraftControllerProvider).valueOrNull?.drafts,
          isEmpty,
        );
      },
    );

    test(
      'a delayed save cannot re-expose a draft after access is blocked',
      () async {
        final facultyGrant = _facultyGrant(
          membershipId: 'membership-delayed',
          institutionId: 'institution-delayed',
        );
        final store = MemoryAttendanceDraftStore();
        final container = await _mutableFacultyContainer(
          store,
          _sessionWithGrants(activeGrant: facultyGrant, grants: [facultyGrant]),
        );
        final subscription = container.listen(
          attendanceDraftControllerProvider,
          (_, __) {},
          fireImmediately: true,
        );
        addTearDown(subscription.close);
        addTearDown(container.dispose);
        final upsertStarted = Completer<void>();
        final allowUpsert = Completer<void>();
        store
          ..upsertStarted = upsertStarted
          ..nextUpsertGate = allowUpsert;
        final dashboard = _dashboard(institutionId: facultyGrant.institutionId);
        final save = container
            .read(attendanceDraftControllerProvider.notifier)
            .save(
              dashboard: dashboard,
              scheduledClass: dashboard.schedule.single,
              statuses: _marks,
            );
        await upsertStarted.future;

        (container.read(sessionControllerProvider.notifier)
                as _MutableSessionController)
            .replace(
              AppSession.accessBlocked(
                reason: AccessBlockReason.noMembership,
                identity: _identityWithGrants(grants: const []),
              ),
            );
        await Future<void>.delayed(Duration.zero);
        expect(
          container
                  .read(attendanceDraftControllerProvider)
                  .valueOrNull
                  ?.drafts ??
              const <String, AttendanceDraft>{},
          isEmpty,
        );

        allowUpsert.complete();
        await save;
        expect(
          container
                  .read(attendanceDraftControllerProvider)
                  .valueOrNull
                  ?.drafts ??
              const <String, AttendanceDraft>{},
          isEmpty,
        );
        await _waitUntil(() => store.drafts.isEmpty);
      },
    );

    test('role scope hides but preserves a faculty draft', () async {
      final store = MemoryAttendanceDraftStore();
      final container = await _facultyContainer(store);
      addTearDown(container.dispose);
      await container
          .read(attendanceDraftControllerProvider.notifier)
          .save(
            dashboard: _dashboard(),
            scheduledClass: _dashboard().schedule.single,
            statuses: _marks,
          );

      await container
          .read(sessionControllerProvider.notifier)
          .selectAccess('development-institution', AppRole.student);
      await _waitUntil(
        () =>
            container
                .read(attendanceDraftControllerProvider)
                .valueOrNull
                ?.drafts
                .isEmpty ??
            false,
      );
      expect(store.drafts, hasLength(1));

      await container
          .read(sessionControllerProvider.notifier)
          .selectAccess('development-institution', AppRole.faculty);
      await _waitUntil(
        () =>
            container
                .read(attendanceDraftControllerProvider)
                .valueOrNull
                ?.drafts
                .length ==
            1,
      );
      expect(store.drafts, hasLength(1));
    });

    test('delayed A load cannot let B save against the stale A book', () async {
      final store = MemoryAttendanceDraftStore();
      final container = await _mutableFacultyContainer(store, _sessionFor('A'));
      final subscription = container.listen(
        attendanceDraftControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      addTearDown(container.dispose);
      final controller = container.read(
        attendanceDraftControllerProvider.notifier,
      );
      final dashboard = _dashboard();
      await controller.save(
        dashboard: dashboard,
        scheduledClass: dashboard.schedule.single,
        statuses: _marks,
      );
      final loadStarted = Completer<void>();
      final allowLoad = Completer<void>();
      store
        ..loadStarted = loadStarted
        ..nextLoadGate = allowLoad;

      (container.read(sessionControllerProvider.notifier)
              as _MutableSessionController)
          .replace(_sessionFor('B'));
      await loadStarted.future;
      final staleSave = controller.save(
        dashboard: dashboard,
        scheduledClass: dashboard.schedule.single,
        statuses: _changedMarks,
      );
      allowLoad.complete();

      await expectLater(
        staleSave,
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.kind,
            'kind',
            FailureKind.validation,
          ),
        ),
      );
      expect(store.upsertAttempts, hasLength(1));
      expect(store.drafts, isEmpty);
    });

    test('sign-out clears every durable draft', () async {
      final store = MemoryAttendanceDraftStore();
      final container = await _facultyContainer(store);
      addTearDown(container.dispose);
      await container
          .read(attendanceDraftControllerProvider.notifier)
          .save(
            dashboard: _dashboard(),
            scheduledClass: _dashboard().schedule.single,
            statuses: _marks,
          );

      await container.read(sessionControllerProvider.notifier).signOut();
      container.read(attendanceDraftControllerProvider);
      await _waitUntil(() => store.deleteAllCalls > 0);

      expect(store.deleteAllCalls, greaterThan(0));
      expect(store.drafts, isEmpty);
      expect(
        container.read(attendanceDraftControllerProvider).valueOrNull?.drafts,
        isEmpty,
      );
    });

    test(
      'a different authenticated user cannot inherit existing drafts',
      () async {
        final store = MemoryAttendanceDraftStore();
        final container = await _facultyContainer(
          store,
          enableGalleryDemo: true,
        );
        addTearDown(container.dispose);
        await container
            .read(attendanceDraftControllerProvider.notifier)
            .save(
              dashboard: _dashboard(),
              scheduledClass: _dashboard().schedule.single,
              statuses: _marks,
            );

        container.read(sessionControllerProvider.notifier).enterGalleryDemo();
        container.read(attendanceDraftControllerProvider);
        await _waitUntil(() => store.deleteAllCalls > 0);

        expect(store.deleteAllCalls, greaterThan(0));
        expect(
          container.read(sessionControllerProvider).userId,
          'gallery-user',
        );
        expect(store.drafts, isEmpty);
        expect(
          container.read(attendanceDraftControllerProvider).valueOrNull?.drafts,
          isEmpty,
        );
      },
    );
  });
}

const _marks = <String, AttendanceStatus>{
  'student-1': AttendanceStatus.present,
  'student-2': AttendanceStatus.absent,
};

const _changedMarks = <String, AttendanceStatus>{
  'student-1': AttendanceStatus.present,
  'student-2': AttendanceStatus.late,
};

Future<ProviderContainer> _facultyContainer(
  MemoryAttendanceDraftStore store, {
  bool enableGalleryDemo = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(
        AppConfig(
          environment: AppEnvironment.test,
          supabaseUrl: '',
          supabaseAnonKey: '',
          enableDesignSystemGallery: enableGalleryDemo,
          enableDemoSession: true,
        ),
      ),
      attendanceDraftStoreProvider.overrideWithValue(store),
      attendanceDraftClockProvider.overrideWithValue(
        () => DateTime.utc(2031, 2, 3, 8, 30),
      ),
      keyValueStoreProvider.overrideWithValue(_MemoryKeyValueStore()),
    ],
  );
  await container
      .read(sessionControllerProvider.notifier)
      .selectAccess('development-institution', AppRole.faculty);
  await container.read(attendanceDraftControllerProvider.future);
  return container;
}

Future<ProviderContainer> _mutableFacultyContainer(
  MemoryAttendanceDraftStore store,
  AppSession initialSession,
) async {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(
        const AppConfig(
          environment: AppEnvironment.test,
          supabaseUrl: '',
          supabaseAnonKey: '',
          enableDesignSystemGallery: false,
          enableDemoSession: false,
        ),
      ),
      sessionControllerProvider.overrideWith(
        () => _MutableSessionController(initialSession),
      ),
      attendanceDraftStoreProvider.overrideWithValue(store),
      attendanceDraftClockProvider.overrideWithValue(
        () => DateTime.utc(2031, 2, 3, 8, 30),
      ),
      keyValueStoreProvider.overrideWithValue(_MemoryKeyValueStore()),
    ],
  );
  await container.read(attendanceDraftControllerProvider.future);
  return container;
}

AppSession _sessionFor(String userId) {
  const grant = AccessGrant(
    membershipId: 'development-membership',
    institutionId: 'development-institution',
    institutionName: 'Development institution',
    role: AppRole.faculty,
    permissions: {AppPermission.rosterRead, AppPermission.attendanceRecord},
  );
  return AppSession.authenticated(
    identity: IdentityContext(
      userId: userId,
      profileCompleted: true,
      memberships: const [
        MembershipSummary(
          id: 'development-membership',
          institutionId: 'development-institution',
          institutionName: 'Development institution',
          institutionActive: true,
          status: MembershipStatus.active,
          grants: [grant],
        ),
      ],
    ),
    activeGrant: grant,
  );
}

AcademicDashboard _dashboard({
  String institutionId = 'development-institution',
  DateTime? date,
  bool submitted = false,
  bool includeClass = true,
  AttendanceStatus submittedSecondStatus = AttendanceStatus.absent,
}) => AcademicDashboard(
  institutionId: institutionId,
  role: AppRole.faculty,
  date: date ?? DateTime(2031, 2, 3),
  schedule: includeClass
      ? [
          ScheduledClass(
            timetableEntryId: 'entry-1',
            courseOfferingId: 'offering-1',
            subjectCode: 'CS701',
            subjectName: 'Distributed Systems',
            sectionName: 'CSE A',
            startsAt: '09:00',
            endsAt: '10:00',
            room: 'A-101',
            attendanceSessionId: submitted ? 'session-1' : null,
            attendanceSubmitted: submitted,
            roster: [
              RosterStudent(
                enrolmentId: 'enrolment-1',
                userId: 'student-1',
                displayName: 'Ada Student',
                status: submitted ? AttendanceStatus.present : null,
              ),
              RosterStudent(
                enrolmentId: 'enrolment-2',
                userId: 'student-2',
                displayName: 'Lin Student',
                status: submitted ? submittedSecondStatus : null,
              ),
            ],
          ),
        ]
      : const [],
  attendanceSummary: const [],
);

AttendanceDraft _draft({
  String userId = 'development-user',
  String membershipId = 'development-membership',
  String institutionId = 'development-institution',
  String selectionKey = 'development-institution:faculty',
  String courseOfferingId = 'offering-1',
  String timetableEntryId = 'entry-1',
  DateTime? sessionDate,
  AttendanceDraftState state = AttendanceDraftState.saved,
  String? requestId,
  DateTime? updatedAt,
}) {
  final timestamp = updatedAt ?? DateTime(2031, 2, 3, 8, 30);
  return AttendanceDraft(
    userId: userId,
    membershipId: membershipId,
    institutionId: institutionId,
    selectionKey: selectionKey,
    courseOfferingId: courseOfferingId,
    timetableEntryId: timetableEntryId,
    subjectCode: 'CS701',
    subjectName: 'Distributed Systems',
    startsAt: '09:00',
    endsAt: '10:00',
    sessionDate: sessionDate ?? DateTime(2031, 2, 3),
    roster: const [
      AttendanceDraftRosterMember(
        enrolmentId: 'enrolment-1',
        userId: 'student-1',
      ),
      AttendanceDraftRosterMember(
        enrolmentId: 'enrolment-2',
        userId: 'student-2',
      ),
    ],
    statuses: _marks,
    state: state,
    requestId: requestId,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

AttendanceDraft _draftForGrant(AccessGrant grant) => _draft(
  membershipId: grant.membershipId,
  institutionId: grant.institutionId,
  selectionKey: grant.selectionKey,
);

AccessGrant _facultyGrant({
  required String membershipId,
  required String institutionId,
  Set<AppPermission> permissions = const {
    AppPermission.rosterRead,
    AppPermission.attendanceRecord,
  },
}) => AccessGrant(
  membershipId: membershipId,
  institutionId: institutionId,
  institutionName: '$institutionId name',
  role: AppRole.faculty,
  permissions: permissions,
);

AppSession _sessionWithGrants({
  required AccessGrant activeGrant,
  required List<AccessGrant> grants,
}) => AppSession.authenticated(
  identity: _identityWithGrants(grants: grants),
  activeGrant: activeGrant,
);

IdentityContext _identityWithGrants({
  required List<AccessGrant> grants,
  bool profileCompleted = true,
}) => IdentityContext(
  userId: 'development-user',
  profileCompleted: profileCompleted,
  memberships: [
    for (final grant in grants)
      MembershipSummary(
        id: grant.membershipId,
        institutionId: grant.institutionId,
        institutionName: grant.institutionName,
        institutionActive: true,
        status: MembershipStatus.active,
        grants: [grant],
      ),
  ],
);

class _MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}

class _MutableSessionController extends SessionController {
  _MutableSessionController(this._initialSession);

  final AppSession _initialSession;

  @override
  AppSession build() => _initialSession;

  void replace(AppSession session) => state = session;
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 200; attempt += 1) {
    await Future<void>.delayed(Duration.zero);
    if (condition()) return;
  }
  fail('Condition did not become true.');
}
