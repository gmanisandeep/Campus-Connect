import 'package:campus_connect/core/auth/app_role.dart';

enum CampusFeatureId {
  dashboard,
  feed,
  chat,
  calendar,
  attendance,
  courses,
  studentPlatform,
  skills,
  opportunities,
  internships,
  jobs,
  partTime,
}

enum CampusFeatureDelivery {
  available('Available'),
  foundation('Foundation'),
  planned('Planned');

  const CampusFeatureDelivery(this.label);

  final String label;

  bool get hasCompleteVerticalSlice => this == CampusFeatureDelivery.available;
}

class CampusFeatureNode {
  const CampusFeatureNode({
    required this.id,
    required this.label,
    required this.summary,
    required this.delivery,
    this.children = const [],
  });

  final CampusFeatureId id;
  final String label;
  final String summary;
  final CampusFeatureDelivery delivery;
  final List<CampusFeatureNode> children;

  Iterable<CampusFeatureNode> get depthFirst sync* {
    yield this;
    for (final child in children) {
      yield* child.depthFirst;
    }
  }
}

class RoleFeatureBlueprint {
  const RoleFeatureBlueprint({required this.role, required this.dashboard});

  final AppRole role;
  final CampusFeatureNode dashboard;

  Iterable<CampusFeatureNode> get features => dashboard.depthFirst;
}

abstract final class CampusFeatureCatalog {
  static const student = RoleFeatureBlueprint(
    role: AppRole.student,
    dashboard: CampusFeatureNode(
      id: CampusFeatureId.dashboard,
      label: 'Student Dashboard',
      summary:
          'Role-aware home for today, attendance, official updates, and '
          'deadlines.',
      delivery: CampusFeatureDelivery.foundation,
      children: [
        CampusFeatureNode(
          id: CampusFeatureId.feed,
          label: 'Feed',
          summary: 'Official, audience-targeted campus updates.',
          delivery: CampusFeatureDelivery.planned,
        ),
        CampusFeatureNode(
          id: CampusFeatureId.chat,
          label: 'Chat',
          summary: 'Authorized course conversations with explicit membership.',
          delivery: CampusFeatureDelivery.planned,
        ),
        CampusFeatureNode(
          id: CampusFeatureId.calendar,
          label: 'Calendar',
          summary: 'Timetable-first agenda with events and deadlines later.',
          delivery: CampusFeatureDelivery.foundation,
        ),
        CampusFeatureNode(
          id: CampusFeatureId.attendance,
          label: 'Attendance',
          summary: 'Personal server-confirmed subject attendance summary.',
          delivery: CampusFeatureDelivery.available,
        ),
        CampusFeatureNode(
          id: CampusFeatureId.courses,
          label: 'Courses',
          summary: 'Enrolled offerings backed by the academic foundation.',
          delivery: CampusFeatureDelivery.foundation,
        ),
        CampusFeatureNode(
          id: CampusFeatureId.studentPlatform,
          label: 'Student Platform (Career)',
          summary: 'Student-owned skills and verified opportunities.',
          delivery: CampusFeatureDelivery.planned,
          children: [
            CampusFeatureNode(
              id: CampusFeatureId.skills,
              label: 'Skills',
              summary: 'Self-declared and institution-verified skill profiles.',
              delivery: CampusFeatureDelivery.planned,
            ),
            CampusFeatureNode(
              id: CampusFeatureId.opportunities,
              label: 'Opportunities',
              summary: 'One verified opportunity system with typed filters.',
              delivery: CampusFeatureDelivery.planned,
              children: [
                CampusFeatureNode(
                  id: CampusFeatureId.internships,
                  label: 'Internships',
                  summary: 'Verified internship opportunities and deadlines.',
                  delivery: CampusFeatureDelivery.planned,
                ),
                CampusFeatureNode(
                  id: CampusFeatureId.jobs,
                  label: 'Jobs',
                  summary: 'Verified graduate and campus job opportunities.',
                  delivery: CampusFeatureDelivery.planned,
                ),
                CampusFeatureNode(
                  id: CampusFeatureId.partTime,
                  label: 'Part-time',
                  summary: 'Verified part-time opportunities.',
                  delivery: CampusFeatureDelivery.planned,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  static const faculty = RoleFeatureBlueprint(
    role: AppRole.faculty,
    dashboard: CampusFeatureNode(
      id: CampusFeatureId.dashboard,
      label: 'Faculty Dashboard (Teaching Overview)',
      summary:
          'Operational home for assigned classes, attendance actions, and '
          'communication.',
      delivery: CampusFeatureDelivery.foundation,
      children: [
        CampusFeatureNode(
          id: CampusFeatureId.feed,
          label: 'Feed',
          summary: 'Official updates visible to the active Faculty grant.',
          delivery: CampusFeatureDelivery.planned,
        ),
        CampusFeatureNode(
          id: CampusFeatureId.chat,
          label: 'Chat',
          summary: 'Assigned-course conversations with membership rechecks.',
          delivery: CampusFeatureDelivery.planned,
        ),
        CampusFeatureNode(
          id: CampusFeatureId.calendar,
          label: 'Calendar',
          summary: 'Assigned timetable first, with authorized events later.',
          delivery: CampusFeatureDelivery.foundation,
        ),
        CampusFeatureNode(
          id: CampusFeatureId.attendance,
          label: 'Attendance',
          summary:
              'Exact-roster capture with encrypted drafts and server '
              'confirmation.',
          delivery: CampusFeatureDelivery.available,
        ),
      ],
    ),
  );

  static RoleFeatureBlueprint? forRole(AppRole role) => switch (role) {
    AppRole.student => student,
    AppRole.faculty => faculty,
    _ => null,
  };
}
