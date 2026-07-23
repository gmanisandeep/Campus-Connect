import 'package:campus_connect/core/auth/app_role.dart';
import 'package:campus_connect/core/product/campus_feature_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps only the approved Student and Faculty experiences', () {
    expect(
      CampusFeatureCatalog.forRole(AppRole.student),
      same(CampusFeatureCatalog.student),
    );
    expect(
      CampusFeatureCatalog.forRole(AppRole.faculty),
      same(CampusFeatureCatalog.faculty),
    );
    expect(CampusFeatureCatalog.forRole(AppRole.placementOfficer), isNull);
  });

  test('Student blueprint preserves the approved hierarchy', () {
    final dashboard = CampusFeatureCatalog.student.dashboard;

    expect(dashboard.label, 'Student Dashboard');
    expect(dashboard.children.map((feature) => feature.id), [
      CampusFeatureId.feed,
      CampusFeatureId.chat,
      CampusFeatureId.calendar,
      CampusFeatureId.attendance,
      CampusFeatureId.courses,
      CampusFeatureId.studentPlatform,
    ]);

    final studentPlatform = dashboard.children.last;
    expect(studentPlatform.children.map((feature) => feature.id), [
      CampusFeatureId.skills,
      CampusFeatureId.opportunities,
    ]);
    expect(
      studentPlatform.children.last.children.map((feature) => feature.id),
      [
        CampusFeatureId.internships,
        CampusFeatureId.jobs,
        CampusFeatureId.partTime,
      ],
    );
  });

  test('Faculty blueprint treats Dashboard as the Teaching Overview', () {
    final dashboard = CampusFeatureCatalog.faculty.dashboard;

    expect(dashboard.label, 'Faculty Dashboard (Teaching Overview)');
    expect(dashboard.children.map((feature) => feature.id), [
      CampusFeatureId.feed,
      CampusFeatureId.chat,
      CampusFeatureId.calendar,
      CampusFeatureId.attendance,
    ]);
    expect(dashboard.featuresWithId(CampusFeatureId.dashboard), hasLength(1));
  });

  test('delivery states match the current implementation evidence', () {
    for (final blueprint in [
      CampusFeatureCatalog.student,
      CampusFeatureCatalog.faculty,
    ]) {
      expect(
        blueprint.features
            .where((feature) => feature.id == CampusFeatureId.attendance)
            .single
            .delivery,
        CampusFeatureDelivery.available,
      );
      expect(
        blueprint.features
            .where((feature) => feature.id == CampusFeatureId.calendar)
            .single
            .delivery,
        CampusFeatureDelivery.foundation,
      );
      expect(
        blueprint.features
            .where((feature) => feature.id == CampusFeatureId.feed)
            .single
            .delivery,
        CampusFeatureDelivery.planned,
      );
      expect(
        blueprint.features
            .where((feature) => feature.id == CampusFeatureId.chat)
            .single
            .delivery,
        CampusFeatureDelivery.planned,
      );
    }
  });

  test('only available features have a complete vertical slice', () {
    expect(CampusFeatureDelivery.available.hasCompleteVerticalSlice, isTrue);
    expect(CampusFeatureDelivery.foundation.hasCompleteVerticalSlice, isFalse);
    expect(CampusFeatureDelivery.planned.hasCompleteVerticalSlice, isFalse);
  });

  test('each role tree uses every feature id at most once', () {
    for (final blueprint in [
      CampusFeatureCatalog.student,
      CampusFeatureCatalog.faculty,
    ]) {
      final ids = blueprint.features.map((feature) => feature.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    }
  });
}

extension on CampusFeatureNode {
  List<CampusFeatureNode> featuresWithId(CampusFeatureId id) =>
      depthFirst.where((feature) => feature.id == id).toList();
}
