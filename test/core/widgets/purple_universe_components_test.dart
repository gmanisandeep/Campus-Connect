import 'package:campus_connect/core/theme/app_theme.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:campus_connect/core/widgets/app_search_field.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_ambient_background.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_button.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_scaffold.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('aurora is decorative, static, and blur free', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const CcAmbientBackground(
          tone: CcAmbientTone.immersive,
          child: Text('Operational content'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Operational content'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('surface variants consume the typed theme roles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Column(
            children: [
              CcSurface(key: Key('base'), child: Text('Base')),
              CcSurface(
                key: Key('raised'),
                variant: CcSurfaceVariant.raised,
                child: Text('Raised'),
              ),
              CcSurface(
                key: Key('glass'),
                variant: CcSurfaceVariant.glass,
                child: Text('Glass'),
              ),
            ],
          ),
        ),
      ),
    );

    final base = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const Key('base')),
        matching: find.byType(DecoratedBox),
      ),
    );
    final raised = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const Key('raised')),
        matching: find.byType(DecoratedBox),
      ),
    );
    final glass = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const Key('glass')),
        matching: find.byType(DecoratedBox),
      ),
    );
    final theme = AppTheme.light().extension<CcThemeExtension>()!;

    expect((base.decoration as BoxDecoration).color, theme.surface);
    expect((raised.decoration as BoxDecoration).color, theme.raisedSurface);
    expect((raised.decoration as BoxDecoration).boxShadow, theme.cardShadow);
    final glassDecoration = glass.decoration as BoxDecoration;
    expect(glassDecoration.color, isNull);
    expect(glassDecoration.gradient, isA<LinearGradient>());
    expect(glassDecoration.boxShadow, theme.cardShadow);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('primary button keeps Material disabled and loading behavior', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: CcPrimaryButton(
            label: 'Continue',
            isLoading: true,
            onPressed: () => presses += 1,
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    expect(presses, 0);
  });

  testWidgets('auth composition survives a small phone at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const CcAuthScaffold(
          heroTitle: 'Your campus, in one place.',
          heroDescription: 'Verified access for campus work.',
          panelTitle: 'Welcome back',
          panelDescription: 'Sign in to your campus',
          child: Column(
            children: [
              TextField(decoration: InputDecoration(labelText: 'Email')),
              SizedBox(height: 16),
              CcPrimaryButton(label: 'Sign in', onPressed: null),
            ],
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Sign in'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('auth composition has no empty idle scroll extent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const CcAuthScaffold(
          heroTitle: 'Your campus, in one place.',
          heroDescription: 'Verified access for campus work.',
          panelTitle: 'Welcome back',
          child: Text('Sign in'),
        ),
      ),
    );

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, 0);
  });

  testWidgets('auth glass composition remains usable in phone landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const CcAuthScaffold(
          heroTitle: 'Your campus, in one place.',
          heroDescription: 'Verified access for campus work.',
          panelTitle: 'Welcome back',
          panelDescription: 'Sign in to your campus',
          child: Column(
            children: [
              TextField(decoration: InputDecoration(labelText: 'Email')),
              SizedBox(height: 16),
              TextField(decoration: InputDecoration(labelText: 'Password')),
              SizedBox(height: 16),
              CcPrimaryButton(label: 'Sign in', onPressed: null),
            ],
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Sign in'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('uncontrolled search clear removes the visible value', (
    tester,
  ) async {
    var query = '';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppSearchField(
            hint: 'Search campus',
            onChanged: (value) => query = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'library');
    await tester.pump();
    expect(query, 'library');

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '',
    );
    expect(query, '');
  });
}
