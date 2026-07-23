enum AppRole {
  platformAdministrator('Platform administrator'),
  institutionAdministrator('Institution administrator'),
  departmentAdministrator('Department administrator'),
  faculty('Faculty'),
  mentor('Mentor'),
  placementOfficer('Placement officer'),
  clubCoordinator('Club coordinator'),
  student('Student');

  const AppRole(this.label);
  final String label;

  bool get isStudentExperience => this == AppRole.student;

  String get databaseKey => switch (this) {
    AppRole.platformAdministrator => 'platform_administrator',
    AppRole.institutionAdministrator => 'institution_administrator',
    AppRole.departmentAdministrator => 'department_administrator',
    AppRole.faculty => 'faculty',
    AppRole.mentor => 'mentor',
    AppRole.placementOfficer => 'placement_officer',
    AppRole.clubCoordinator => 'club_coordinator',
    AppRole.student => 'student',
  };

  static AppRole? fromDatabaseKey(String key) => switch (key) {
    'platform_administrator' => AppRole.platformAdministrator,
    'institution_administrator' => AppRole.institutionAdministrator,
    'department_administrator' => AppRole.departmentAdministrator,
    'faculty' => AppRole.faculty,
    'mentor' => AppRole.mentor,
    'placement_officer' => AppRole.placementOfficer,
    'club_coordinator' => AppRole.clubCoordinator,
    'student' => AppRole.student,
    _ => null,
  };
}

enum AppPermission {
  institutionManage,
  academicsManage,
  rosterRead,
  attendanceRecord,
  attendanceReadOwn,
  announcementsPublish,
  eventsManage,
  mentorshipManage,
  opportunitiesManage,
  clubsManage,
  auditRead;

  String get databaseKey => switch (this) {
    AppPermission.institutionManage => 'institution_manage',
    AppPermission.academicsManage => 'academics_manage',
    AppPermission.rosterRead => 'roster_read',
    AppPermission.attendanceRecord => 'attendance_record',
    AppPermission.attendanceReadOwn => 'attendance_read_own',
    AppPermission.announcementsPublish => 'announcements_publish',
    AppPermission.eventsManage => 'events_manage',
    AppPermission.mentorshipManage => 'mentorship_manage',
    AppPermission.opportunitiesManage => 'opportunities_manage',
    AppPermission.clubsManage => 'clubs_manage',
    AppPermission.auditRead => 'audit_read',
  };

  static AppPermission? fromDatabaseKey(String key) => switch (key) {
    'institution_manage' => AppPermission.institutionManage,
    'academics_manage' => AppPermission.academicsManage,
    'roster_read' => AppPermission.rosterRead,
    'attendance_record' => AppPermission.attendanceRecord,
    'attendance_read_own' => AppPermission.attendanceReadOwn,
    'announcements_publish' => AppPermission.announcementsPublish,
    'events_manage' => AppPermission.eventsManage,
    'mentorship_manage' => AppPermission.mentorshipManage,
    'opportunities_manage' => AppPermission.opportunitiesManage,
    'clubs_manage' => AppPermission.clubsManage,
    'audit_read' => AppPermission.auditRead,
    _ => null,
  };
}
