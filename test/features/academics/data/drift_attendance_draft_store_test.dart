import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:campus_connect/core/configuration/app_config.dart';
import 'package:campus_connect/core/logging/app_logger.dart';
import 'package:campus_connect/core/storage/campus_local_database.dart';
import 'package:campus_connect/core/storage/local_database_key_store.dart';
import 'package:campus_connect/core/storage/secure_store.dart';
import 'package:campus_connect/features/academics/data/drift_attendance_draft_store.dart';
import 'package:campus_connect/features/academics/domain/academic_dashboard.dart';
import 'package:campus_connect/features/academics/domain/attendance_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late _StoreFixture fixture;

  setUp(() async {
    fixture = await _StoreFixture.create();
  });

  tearDown(() async {
    await fixture.dispose();
  });

  test(
    'encrypted store round-trips only attendance identifiers and statuses',
    () async {
      final saved = _draft(
        state: AttendanceDraftState.submissionUncertain,
        requestId: 'request-sensitive-001',
        createdAt: DateTime.parse('2026-07-20T05:00:00+05:30'),
        updatedAt: DateTime.parse('2026-07-20T05:15:00+05:30'),
      );

      await fixture.store.upsert(saved);
      final loaded = await fixture.store.loadAll();

      expect(loaded, hasLength(1));
      final restored = loaded.single;
      expect(restored.userId, saved.userId);
      expect(restored.membershipId, saved.membershipId);
      expect(restored.institutionId, saved.institutionId);
      expect(restored.selectionKey, saved.selectionKey);
      expect(restored.courseOfferingId, saved.courseOfferingId);
      expect(restored.timetableEntryId, saved.timetableEntryId);
      expect(attendanceDateKey(restored.sessionDate), '2026-07-20');
      expect(restored.roster, hasLength(2));
      expect(restored.roster.map((member) => member.userId), [
        'student-user-001',
        'student-user-002',
      ]);
      expect(restored.statuses, {
        'student-user-001': AttendanceStatus.present,
        'student-user-002': AttendanceStatus.absent,
      });
      expect(restored.state, AttendanceDraftState.submissionUncertain);
      expect(restored.requestId, 'request-sensitive-001');
      expect(restored.createdAt, saved.createdAt.toUtc());
      expect(restored.updatedAt, saved.updatedAt.toUtc());

      final database = await fixture.manager.open();
      final markColumns = await database
          .customSelect('PRAGMA table_info(attendance_draft_mark_rows)')
          .get();
      expect(markColumns.map((row) => row.data['name']).toSet(), {
        'draft_id',
        'enrolment_id',
        'student_user_id',
        'status',
      });
      expect(
        markColumns.map((row) => row.data['name']),
        isNot(contains(anyOf('display_name', 'full_name', 'student_name'))),
      );
    },
  );

  test(
    'ciphertext contains no known identifiers, statuses, or display names',
    () async {
      await fixture.store.upsert(_draft());
      await fixture.manager.close();

      final bytes = await fixture.databaseFile.readAsBytes();

      expect(bytes, isNotEmpty);
      for (final plaintext in const [
        'faculty-user-sensitive-001',
        'membership-sensitive-001',
        'institution-sensitive-001',
        'student-user-001',
        'enrolment-sensitive-001',
        'present',
        'absent',
        'Ada Student Display Name',
      ]) {
        expect(
          _containsBytes(bytes, utf8.encode(plaintext)),
          isFalse,
          reason: 'encrypted database leaked "$plaintext"',
        );
      }
    },
  );

  test(
    'same class scopes remain isolated across users and memberships',
    () async {
      final firstTenant = _draft();
      final secondTenant = _draft(
        membershipId: 'membership-sensitive-002',
        institutionId: 'institution-sensitive-002',
        statuses: const {
          'student-user-001': AttendanceStatus.late,
          'student-user-002': AttendanceStatus.present,
        },
      );
      final secondUser = _draft(
        userId: 'faculty-user-sensitive-002',
        membershipId: 'membership-sensitive-003',
        institutionId: 'institution-sensitive-003',
      );

      await fixture.store.upsert(firstTenant);
      await fixture.store.upsert(secondTenant);
      await fixture.store.upsert(secondUser);

      var loaded = await fixture.store.loadAll();
      expect(loaded, hasLength(3));
      expect(loaded.map((draft) => draft.storageKey).toSet(), hasLength(3));

      await fixture.store.delete(firstTenant.storageKey);
      loaded = await fixture.store.loadAll();
      expect(loaded, hasLength(2));
      expect(
        loaded.any((draft) => draft.storageKey == secondTenant.storageKey),
        isTrue,
      );
      expect(
        loaded.any((draft) => draft.storageKey == secondUser.storageKey),
        isTrue,
      );

      await fixture.store.deleteForUser(secondTenant.userId);
      loaded = await fixture.store.loadAll();
      expect(loaded.map((draft) => draft.userId), [
        'faculty-user-sensitive-002',
      ]);
    },
  );

  test(
    'concurrent same-scope upserts are serialized and replace marks',
    () async {
      final base = _draft();
      final writes = <Future<void>>[];
      for (var index = 0; index < 24; index += 1) {
        writes.add(
          fixture.store.upsert(
            _draft(
              statuses: {
                'student-user-001': index.isEven
                    ? AttendanceStatus.present
                    : AttendanceStatus.absent,
                'student-user-002': index.isEven
                    ? AttendanceStatus.late
                    : AttendanceStatus.present,
              },
              updatedAt: base.updatedAt.add(Duration(minutes: index)),
            ),
          ),
        );
      }

      await Future.wait(writes);
      final loaded = await fixture.store.loadAll();

      expect(loaded, hasLength(1));
      expect(
        loaded.single.updatedAt,
        base.updatedAt.add(const Duration(minutes: 23)),
      );
      expect(loaded.single.statuses, {
        'student-user-001': AttendanceStatus.absent,
        'student-user-002': AttendanceStatus.present,
      });
      final database = await fixture.manager.open();
      expect(
        await database.select(database.attendanceDraftRows).get(),
        hasLength(1),
      );
      expect(
        await database.select(database.attendanceDraftMarkRows).get(),
        hasLength(2),
      );
    },
  );

  test('rejects invalid drafts before any partial database write', () async {
    final invalid = _draft(
      statuses: const {'student-user-001': AttendanceStatus.present},
    );

    await expectLater(fixture.store.upsert(invalid), throwsFormatException);

    expect(await fixture.store.loadAll(), isEmpty);
    final database = await fixture.manager.open();
    expect(await database.select(database.attendanceDraftRows).get(), isEmpty);
    expect(
      await database.select(database.attendanceDraftMarkRows).get(),
      isEmpty,
    );
  });

  test(
    'unknown persisted state and version are forced into needs-review',
    () async {
      await fixture.store.upsert(_draft());
      final database = await fixture.manager.open();
      await database.customStatement(
        "UPDATE attendance_draft_rows SET state = 'future_state', "
        "payload_version = 99, request_id = 'untrusted-request'",
      );

      final loaded = await fixture.store.loadAll();

      expect(loaded, hasLength(1));
      expect(loaded.single.state, AttendanceDraftState.needsReview);
      expect(loaded.single.requestId, isNull);
      expect(loaded.single.isEditable, isFalse);
    },
  );

  test(
    'corrupt authority scope is discarded instead of being returned',
    () async {
      await fixture.store.upsert(_draft());
      final database = await fixture.manager.open();
      await database.customStatement(
        "UPDATE attendance_draft_rows SET institution_id = '', "
        "scope_key = 'tampered-scope'",
      );

      expect(await fixture.store.loadAll(), isEmpty);
      expect(
        await database.select(database.attendanceDraftRows).get(),
        isEmpty,
      );
      expect(
        fixture.logger.warnings,
        contains('attendance.draft.invalid_rows_discarded'),
      );
    },
  );

  test(
    'corrupt mark status discards the draft and cascades its marks',
    () async {
      await fixture.store.upsert(_draft());
      final database = await fixture.manager.open();
      await database.customStatement(
        "UPDATE attendance_draft_mark_rows SET status = 'future_status'",
      );

      expect(await fixture.store.loadAll(), isEmpty);
      expect(
        await database.select(database.attendanceDraftRows).get(),
        isEmpty,
      );
      expect(
        await database.select(database.attendanceDraftMarkRows).get(),
        isEmpty,
      );
    },
  );

  test('delete removes a draft and cascades all roster marks', () async {
    final draft = _draft();
    await fixture.store.upsert(draft);

    await fixture.store.delete(draft.storageKey);

    expect(await fixture.store.loadAll(), isEmpty);
    final database = await fixture.manager.open();
    expect(
      await database.select(database.attendanceDraftMarkRows).get(),
      isEmpty,
    );
  });

  test(
    'wrong key cannot open ciphertext and does not damage valid data',
    () async {
      await fixture.store.upsert(_draft());
      await fixture.manager.close();
      final before = await fixture.databaseFile.readAsBytes();

      final wrongSecureStore = _MemorySecureStore();
      wrongSecureStore.values[fixture.keyName] = List.filled(64, 'f').join();
      final wrongManager = fixture.createManager(wrongSecureStore);

      await expectLater(wrongManager.open(), throwsA(anything));
      await wrongManager.close();
      expect(await fixture.databaseFile.readAsBytes(), before);

      final loaded = await fixture.store.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.single.userId, 'faculty-user-sensitive-001');
    },
  );

  test(
    'missing key fails closed by replacing ciphertext with an empty store',
    () async {
      await fixture.store.upsert(_draft());
      await fixture.manager.close();
      final oldKey = await fixture.keyStore.readKey();
      final ciphertext = await fixture.databaseFile.readAsBytes();
      await fixture.secureStore.delete(fixture.keyName);

      final replacementManager = fixture.createManager(fixture.secureStore);
      final replacementStore = DriftAttendanceDraftStore(
        replacementManager,
        fixture.logger,
        idFactory: () => 'replacement-id',
      );

      expect(await replacementStore.loadAll(), isEmpty);
      final replacementKey = await fixture.keyStore.readKey();
      expect(replacementKey, isNotNull);
      expect(replacementKey, isNot(oldKey));
      expect(await fixture.databaseFile.readAsBytes(), isNot(ciphertext));
      await replacementManager.close();
    },
  );

  test(
    'cryptographic destroy deletes the key before removing database files',
    () async {
      await fixture.store.upsert(_draft());
      await fixture.manager.close();
      final encryptedSnapshot = await fixture.databaseFile.readAsBytes();
      expect(await fixture.keyStore.readKey(), isNotNull);
      bool? databaseExistedWhenKeyWasDeleted;
      fixture.secureStore.beforeDelete = (key) {
        if (key == fixture.keyName) {
          databaseExistedWhenKeyWasDeleted = fixture.databaseFile.existsSync();
        }
      };

      await fixture.store.deleteAll();

      expect(databaseExistedWhenKeyWasDeleted, isTrue);
      expect(await fixture.keyStore.readKey(), isNull);
      expect(await fixture.databaseFile.exists(), isFalse);
      for (final suffix in const ['-wal', '-shm', '-journal']) {
        expect(
          File('${fixture.databaseFile.path}$suffix').existsSync(),
          isFalse,
        );
      }
      expect(
        _containsBytes(
          encryptedSnapshot,
          utf8.encode('faculty-user-sensitive-001'),
        ),
        isFalse,
      );
    },
  );

  test(
    'failed key deletion still closes and erases the encrypted database',
    () async {
      await fixture.store.upsert(_draft());
      final openedDatabase = await fixture.manager.open();
      final retainedKey = await fixture.keyStore.readKey();
      expect(await fixture.databaseFile.exists(), isTrue);
      bool? databaseAcceptedQueryAtKeyDeletion;
      bool? fileExistedAtKeyDeletion;
      fixture.secureStore.beforeDelete = (key) async {
        if (key == fixture.keyName) {
          fileExistedAtKeyDeletion = fixture.databaseFile.existsSync();
          try {
            await openedDatabase
                .customSelect('SELECT count(*) FROM sqlite_master')
                .get();
            databaseAcceptedQueryAtKeyDeletion = true;
          } on Object {
            databaseAcceptedQueryAtKeyDeletion = false;
          }
        }
      };
      fixture.secureStore.failNextDelete = true;

      await expectLater(
        fixture.store.deleteAll(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'simulated secure-store deletion failure',
          ),
        ),
      );

      expect(databaseAcceptedQueryAtKeyDeletion, isTrue);
      expect(fileExistedAtKeyDeletion, isTrue);
      await expectLater(
        openedDatabase.customSelect('SELECT 1').get(),
        throwsA(anything),
      );
      expect(await fixture.keyStore.readKey(), retainedKey);
      expect(await fixture.databaseFile.exists(), isFalse);
      for (final suffix in const ['-wal', '-shm', '-journal']) {
        expect(
          File('${fixture.databaseFile.path}$suffix').existsSync(),
          isFalse,
        );
      }

      // The failed cleanup remains visible to its caller, but does not poison
      // the serialized store or leave the prior attendance data recoverable.
      expect(await fixture.store.loadAll(), isEmpty);
      final replacementDatabase = await fixture.manager.open();
      expect(replacementDatabase, isNot(same(openedDatabase)));
      expect(
        await replacementDatabase.customSelect('SELECT 1 AS value').get(),
        hasLength(1),
      );
    },
  );
}

AttendanceDraft _draft({
  String userId = 'faculty-user-sensitive-001',
  String membershipId = 'membership-sensitive-001',
  String institutionId = 'institution-sensitive-001',
  Map<String, AttendanceStatus>? statuses,
  AttendanceDraftState state = AttendanceDraftState.saved,
  String? requestId,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final created = createdAt ?? DateTime.utc(2026, 7, 20, 5);
  return AttendanceDraft(
    userId: userId,
    membershipId: membershipId,
    institutionId: institutionId,
    selectionKey: 'faculty|membership-sensitive-001',
    courseOfferingId: 'offering-sensitive-001',
    timetableEntryId: 'timetable-sensitive-001',
    subjectCode: 'CS701',
    subjectName: 'Secure Systems',
    startsAt: '09:00',
    endsAt: '10:00',
    sessionDate: DateTime(2026, 7, 20),
    roster: const [
      AttendanceDraftRosterMember(
        enrolmentId: 'enrolment-sensitive-001',
        userId: 'student-user-001',
      ),
      AttendanceDraftRosterMember(
        enrolmentId: 'enrolment-sensitive-002',
        userId: 'student-user-002',
      ),
    ],
    statuses:
        statuses ??
        const {
          'student-user-001': AttendanceStatus.present,
          'student-user-002': AttendanceStatus.absent,
        },
    state: state,
    requestId: requestId,
    createdAt: created,
    updatedAt: updatedAt ?? created.add(const Duration(minutes: 5)),
  );
}

bool _containsBytes(List<int> haystack, List<int> needle) {
  if (needle.isEmpty) return true;
  for (var start = 0; start <= haystack.length - needle.length; start += 1) {
    var matches = true;
    for (var offset = 0; offset < needle.length; offset += 1) {
      if (haystack[start + offset] != needle[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}

class _StoreFixture {
  _StoreFixture._({
    required this.directory,
    required this.config,
    required this.secureStore,
    required this.keyStore,
    required this.logger,
    required this.manager,
    required this.store,
  });

  static Future<_StoreFixture> create() async {
    final directory = await Directory.systemTemp.createTemp(
      'campus-connect-encrypted-draft-',
    );
    const config = AppConfig(
      environment: AppEnvironment.test,
      supabaseUrl: 'http://127.0.0.1:54321',
      supabaseAnonKey: 'sb_publishable_test',
      enableDesignSystemGallery: false,
      enableDemoSession: false,
    );
    final namespace = databaseNamespaceFor(config);
    final secureStore = _MemorySecureStore();
    final keyStore = LocalDatabaseKeyStore(secureStore, namespace: namespace);
    final logger = _RecordingLogger();
    final manager = CampusLocalDatabaseManager(
      config: config,
      keyStore: keyStore,
      logger: logger,
      directoryProvider: () async => directory,
    );
    var id = 0;
    final store = DriftAttendanceDraftStore(
      manager,
      logger,
      idFactory: () => 'draft-${++id}',
    );
    return _StoreFixture._(
      directory: directory,
      config: config,
      secureStore: secureStore,
      keyStore: keyStore,
      logger: logger,
      manager: manager,
      store: store,
    );
  }

  final Directory directory;
  final AppConfig config;
  final _MemorySecureStore secureStore;
  final LocalDatabaseKeyStore keyStore;
  final _RecordingLogger logger;
  final CampusLocalDatabaseManager manager;
  final DriftAttendanceDraftStore store;

  String get keyName =>
      'campus_connect.local_database_key.v1.${manager.namespace}';

  File get databaseFile => File(
    path.join(directory.path, 'campus_connect_${manager.namespace}.sqlite'),
  );

  CampusLocalDatabaseManager createManager(SecureStore secureStore) =>
      CampusLocalDatabaseManager(
        config: config,
        keyStore: LocalDatabaseKeyStore(
          secureStore,
          namespace: manager.namespace,
        ),
        logger: logger,
        directoryProvider: () async => directory,
      );

  Future<void> dispose() async {
    await manager.close();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

class _MemorySecureStore implements SecureStore {
  final Map<String, String> values = {};
  FutureOr<void> Function(String key)? beforeDelete;
  bool failNextDelete = false;

  @override
  Future<void> delete(String key) async {
    await beforeDelete?.call(key);
    if (failNextDelete) {
      failNextDelete = false;
      throw StateError('simulated secure-store deletion failure');
    }
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class _RecordingLogger implements AppLogger {
  final List<String> warnings = [];
  final List<String> errors = [];

  @override
  void debug(String event, {Map<String, Object?> fields = const {}}) {}

  @override
  void error(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const {},
  }) {
    errors.add(event);
  }

  @override
  void fatal(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const {},
  }) {
    errors.add(event);
  }

  @override
  void info(String event, {Map<String, Object?> fields = const {}}) {}

  @override
  void warning(String event, {Map<String, Object?> fields = const {}}) {
    warnings.add(event);
  }
}
