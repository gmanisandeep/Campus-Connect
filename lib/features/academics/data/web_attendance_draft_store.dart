import 'package:campus_connect/features/academics/domain/attendance_draft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Browser fallback for the desktop administration surface.
///
/// The mobile/desktop native application keeps encrypted durable drafts. The
/// web console intentionally keeps drafts only for the current tab because the
/// native SQLCipher store cannot be compiled into a browser and unencrypted
/// persistence would weaken the attendance recovery contract.
final attendanceDraftStoreProvider = Provider<AttendanceDraftStore>(
  (ref) => _WebAttendanceDraftStore(),
);

class _WebAttendanceDraftStore implements AttendanceDraftStore {
  final Map<String, AttendanceDraft> _drafts = {};

  @override
  Future<List<AttendanceDraft>> loadAll() async =>
      List.unmodifiable(_drafts.values);

  @override
  Future<void> upsert(AttendanceDraft draft) async {
    _drafts[draft.storageKey] = draft;
  }

  @override
  Future<void> delete(String storageKey) async {
    _drafts.remove(storageKey);
  }

  @override
  Future<void> deleteForUser(String userId) async {
    _drafts.removeWhere((_, draft) => draft.userId == userId);
  }

  @override
  Future<void> deleteAll() async => _drafts.clear();
}
