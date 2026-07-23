import 'package:campus_connect/features/academics/domain/academic_dashboard.dart';

enum AttendanceDraftState { saved, submissionUncertain, needsReview }

class AttendanceDraft {
  AttendanceDraft({
    required this.userId,
    required this.membershipId,
    required this.institutionId,
    required this.selectionKey,
    required this.courseOfferingId,
    required this.timetableEntryId,
    required this.subjectCode,
    required this.subjectName,
    required this.startsAt,
    required this.endsAt,
    required this.sessionDate,
    required List<AttendanceDraftRosterMember> roster,
    required Map<String, AttendanceStatus> statuses,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.requestId,
  }) : roster = List.unmodifiable(roster),
       statuses = Map.unmodifiable(statuses);

  final String userId;
  final String membershipId;
  final String institutionId;
  final String selectionKey;
  final String courseOfferingId;
  final String timetableEntryId;
  final String subjectCode;
  final String subjectName;
  final String startsAt;
  final String endsAt;
  final DateTime sessionDate;
  final List<AttendanceDraftRosterMember> roster;
  final Map<String, AttendanceStatus> statuses;
  final AttendanceDraftState state;
  final String? requestId;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get storageKey =>
      '$userId|$membershipId|$selectionKey|'
      '$courseOfferingId|$timetableEntryId|${attendanceDateKey(sessionDate)}';

  bool get isEditable => state == AttendanceDraftState.saved;

  bool matchesAuthority({
    required String expectedUserId,
    required String expectedMembershipId,
    required String expectedInstitutionId,
    required String expectedSelectionKey,
  }) =>
      userId == expectedUserId &&
      membershipId == expectedMembershipId &&
      institutionId == expectedInstitutionId &&
      selectionKey == expectedSelectionKey;

  bool matchesClass(ScheduledClass scheduledClass, DateTime expectedDate) =>
      courseOfferingId == scheduledClass.courseOfferingId &&
      timetableEntryId == scheduledClass.timetableEntryId &&
      subjectCode == scheduledClass.subjectCode &&
      subjectName == scheduledClass.subjectName &&
      startsAt == scheduledClass.startsAt &&
      endsAt == scheduledClass.endsAt &&
      sameAttendanceDate(sessionDate, expectedDate);

  bool rosterMatches(ScheduledClass scheduledClass) {
    final currentRoster = [
      for (final student in scheduledClass.roster)
        AttendanceDraftRosterMember(
          enrolmentId: student.enrolmentId,
          userId: student.userId,
        ),
    ]..sort(_compareRosterMembers);
    final savedRoster = [...roster]..sort(_compareRosterMembers);
    if (currentRoster.length != savedRoster.length) return false;
    for (var index = 0; index < currentRoster.length; index += 1) {
      if (!currentRoster[index].sameAs(savedRoster[index])) return false;
    }
    final currentUserIds = currentRoster.map((entry) => entry.userId).toSet();
    return statuses.keys.toSet().containsAll(currentUserIds) &&
        currentUserIds.containsAll(statuses.keys);
  }

  bool hasStatuses(Map<String, AttendanceStatus> other) {
    if (statuses.length != other.length) return false;
    for (final entry in statuses.entries) {
      if (other[entry.key] != entry.value) return false;
    }
    return true;
  }

  AttendanceDraft copyWith({
    Map<String, AttendanceStatus>? statuses,
    AttendanceDraftState? state,
    String? requestId,
    bool clearRequestId = false,
    DateTime? updatedAt,
  }) => AttendanceDraft(
    userId: userId,
    membershipId: membershipId,
    institutionId: institutionId,
    selectionKey: selectionKey,
    courseOfferingId: courseOfferingId,
    timetableEntryId: timetableEntryId,
    subjectCode: subjectCode,
    subjectName: subjectName,
    startsAt: startsAt,
    endsAt: endsAt,
    sessionDate: sessionDate,
    roster: roster,
    statuses: statuses ?? this.statuses,
    state: state ?? this.state,
    requestId: clearRequestId ? null : requestId ?? this.requestId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class AttendanceDraftRosterMember {
  const AttendanceDraftRosterMember({
    required this.enrolmentId,
    required this.userId,
  });

  final String enrolmentId;
  final String userId;

  bool sameAs(AttendanceDraftRosterMember other) =>
      enrolmentId == other.enrolmentId && userId == other.userId;
}

class AttendanceDraftBook {
  AttendanceDraftBook(Map<String, AttendanceDraft> drafts)
    : drafts = Map.unmodifiable(drafts);

  AttendanceDraftBook.empty() : drafts = const {};

  final Map<String, AttendanceDraft> drafts;

  AttendanceDraft? forClass(
    ScheduledClass scheduledClass,
    DateTime sessionDate,
  ) {
    for (final draft in drafts.values) {
      if (draft.courseOfferingId == scheduledClass.courseOfferingId &&
          draft.timetableEntryId == scheduledClass.timetableEntryId &&
          sameAttendanceDate(draft.sessionDate, sessionDate)) {
        return draft;
      }
    }
    return null;
  }

  AttendanceDraftBook put(AttendanceDraft draft) =>
      AttendanceDraftBook({...drafts, draft.storageKey: draft});

  AttendanceDraftBook remove(String storageKey) {
    if (!drafts.containsKey(storageKey)) return this;
    return AttendanceDraftBook({...drafts}..remove(storageKey));
  }
}

abstract interface class AttendanceDraftStore {
  Future<List<AttendanceDraft>> loadAll();
  Future<void> upsert(AttendanceDraft draft);
  Future<void> delete(String storageKey);
  Future<void> deleteForUser(String userId);
  Future<void> deleteAll();
}

String attendanceDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

bool sameAttendanceDate(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

int _compareRosterMembers(
  AttendanceDraftRosterMember first,
  AttendanceDraftRosterMember second,
) {
  final userComparison = first.userId.compareTo(second.userId);
  return userComparison != 0
      ? userComparison
      : first.enrolmentId.compareTo(second.enrolmentId);
}
