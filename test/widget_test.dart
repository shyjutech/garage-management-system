// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_management_system/src/app.dart';
import 'package:garage_management_system/src/store/garage_store.dart';
import 'package:garage_management_system/src/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('app renders main modules', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1280, 800)),
        child: ChangeNotifierProvider(
          create: (_) => GarageStore.memory()..seed(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const HomeShell(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SARATHI'), findsOneWidget);
    expect(find.text('Party'), findsOneWidget);
    expect(find.text('Job Cards'), findsOneWidget);
  });

  testWidgets('estimates page renders without autocomplete errors',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1280, 800)),
        child: ChangeNotifierProvider(
          create: (_) => GarageStore.memory()..seed(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const HomeShell(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Estimates'));
    await tester.pumpAndSettle();

    expect(find.text('Open Estimates'), findsOneWidget);

    await tester.tap(find.text('Job Cards'));
    await tester.pumpAndSettle();

    expect(find.text('Live Job Cards'), findsOneWidget);
  });
}
