import 'package:campus_connect/core/theme/app_theme.dart';
import 'package:campus_connect/features/foundation/presentation/widgets/feature_blueprint_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders both role trees and truthful delivery states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SingleChildScrollView(child: FeatureBlueprintSection()),
        ),
      ),
    );

    expect(find.text('Student Dashboard'), findsOneWidget);
    expect(find.text('Faculty Dashboard (Teaching Overview)'), findsOneWidget);
    expect(find.text('Student Platform (Career)'), findsOneWidget);
    expect(find.text('Internships'), findsOneWidget);
    expect(find.text('Jobs'), findsOneWidget);
    expect(find.text('Part-time'), findsOneWidget);
    expect(find.text('Available'), findsNWidgets(6));
    expect(find.text('Foundation'), findsNWidgets(5));
    expect(find.text('Planned'), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('remains usable at a narrow phone width and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(child: FeatureBlueprintSection()),
          ),
        ),
      ),
    );

    expect(find.text('Student Dashboard'), findsOneWidget);
    expect(find.text('Faculty Dashboard (Teaching Overview)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
