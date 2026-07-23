import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:campus_connect/core/configuration/app_config.dart';
import 'package:campus_connect/core/logging/app_logger.dart';
import 'package:campus_connect/core/storage/local_database_key_store.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

part 'campus_local_database.g.dart';

class AttendanceDraftRows extends Table {
  TextColumn get id => text()();
  TextColumn get scopeKey => text().unique()();
  IntColumn get payloadVersion => integer()();
  TextColumn get userId => text()();
  TextColumn get membershipId => text()();
  TextColumn get institutionId => text()();
  TextColumn get selectionKey => text()();
  TextColumn get courseOfferingId => text()();
  TextColumn get timetableEntryId => text()();
  TextColumn get subjectCode => text()();
  TextColumn get subjectName => text()();
  TextColumn get startsAt => text()();
  TextColumn get endsAt => text()();
  TextColumn get sessionDate => text()();
  TextColumn get state => text()();
  TextColumn get requestId => text().nullable()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AttendanceDraftMarkRows extends Table {
  TextColumn get draftId => text().references(
    AttendanceDraftRows,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get enrolmentId => text()();
  TextColumn get studentUserId => text()();
  TextColumn get status => text()();

  @override
  Set<Column<Object>> get primaryKey => {draftId, studentUserId};
}

@DriftDatabase(tables: [AttendanceDraftRows, AttendanceDraftMarkRows])
class CampusLocalDatabase extends _$CampusLocalDatabase {
  CampusLocalDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

typedef LocalDatabaseDirectoryProvider = Future<Directory> Function();

class CampusLocalDatabaseManager {
  CampusLocalDatabaseManager({
    required AppConfig config,
    required LocalDatabaseKeyStore keyStore,
    required AppLogger logger,
    LocalDatabaseDirectoryProvider? directoryProvider,
  }) : _namespace = _databaseNamespace(config),
       _keyStore = keyStore,
       _logger = logger,
       _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final String _namespace;
  final LocalDatabaseKeyStore _keyStore;
  final AppLogger _logger;
  final LocalDatabaseDirectoryProvider _directoryProvider;
  CampusLocalDatabase? _database;
  Future<CampusLocalDatabase>? _opening;

  String get namespace => _namespace;

  Future<CampusLocalDatabase> open() {
    final current = _database;
    if (current != null) return Future.value(current);
    final opening = _opening;
    if (opening != null) return opening;
    final result = _open();
    _opening = result;
    return result.whenComplete(() => _opening = null);
  }

  Future<CampusLocalDatabase> _open() async {
    final file = await _databaseFile();
    var key = await _keyStore.readKey();
    if (key == null || !RegExp(r'^[0-9a-f]{64}$').hasMatch(key)) {
      await _deleteDatabaseFiles(file);
      key = await _keyStore.createKey();
    }
    final executor = NativeDatabase.createInBackground(
      file,
      readPool: 0,
      setup: (rawDatabase) => _configureEncryptedDatabase(rawDatabase, key!),
    );
    final database = CampusLocalDatabase(executor);
    try {
      await database.customSelect('SELECT count(*) FROM sqlite_master').get();
    } on Object catch (error, stackTrace) {
      await database.close();
      _logger.error(
        'storage.encrypted_database_open_failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
    _database = database;
    return database;
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    if (database != null) await database.close();
  }

  Future<void> destroy() async {
    final file = await _databaseFile();
    // Delete the wrapping key first so an interrupted cleanup still leaves any
    // database remnants cryptographically unreadable after process death.
    Object? firstError;
    StackTrace? firstStackTrace;
    try {
      await _keyStore.deleteKey();
    } on Object catch (error, stackTrace) {
      firstError = error;
      firstStackTrace = stackTrace;
    }
    try {
      await close();
    } on Object catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }
    try {
      await _deleteDatabaseFiles(file);
    } on Object catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }
    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
  }

  Future<File> _databaseFile() async {
    final directory = await _directoryProvider();
    await directory.create(recursive: true);
    return File(path.join(directory.path, 'campus_connect_$_namespace.sqlite'));
  }

  Future<void> _deleteDatabaseFiles(File databaseFile) async {
    for (final suffix in const ['', '-wal', '-shm', '-journal']) {
      final candidate = File('${databaseFile.path}$suffix');
      if (await candidate.exists()) await candidate.delete();
    }
  }
}

void _configureEncryptedDatabase(sqlite.Database database, String hexKey) {
  if (database.select('PRAGMA cipher;').isEmpty) {
    throw StateError('Encrypted SQLite support is unavailable.');
  }
  database.execute("PRAGMA cipher = 'sqlcipher';");
  database.execute('PRAGMA key = "x\'$hexKey\'";');
  // PRAGMA key reports success before the key is actually used. Force a read
  // so a missing or wrong OS-protected key fails before Drift can run queries.
  database.select('SELECT count(*) FROM sqlite_master;');
  database.execute('PRAGMA foreign_keys = ON;');
  database.execute('PRAGMA journal_mode = DELETE;');
  database.execute('PRAGMA synchronous = FULL;');
  database.execute('PRAGMA secure_delete = ON;');
  database.execute('PRAGMA memory_security = ON;');
}

String databaseNamespaceFor(AppConfig config) => _databaseNamespace(config);

String _databaseNamespace(AppConfig config) {
  final uri = Uri.tryParse(config.supabaseUrl);
  final origin = uri == null || uri.host.isEmpty
      ? 'unconfigured'
      : '${uri.scheme}://${uri.authority}';
  final input = '${config.environment.name}|$origin';
  return sha256.convert(utf8.encode(input)).toString().substring(0, 24);
}
