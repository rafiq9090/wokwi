// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_monitor/main.dart';

void main() {
  testWidgets('shows the family safety dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const FamilyMonitorApp());

    expect(find.text('Care Circle'), findsOneWidget);
    expect(find.text('Mum is safe'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Simulate fall alert'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Simulate fall alert'), findsOneWidget);
  });

  testWidgets('shows and acknowledges a demo alert', (WidgetTester tester) async {
    await tester.pumpWidget(const FamilyMonitorApp());
    await tester.scrollUntilVisible(
      find.text('Simulate fall alert'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Simulate fall alert'));
    await tester.pump();

    expect(find.text('Fall alert active'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Acknowledge alert'),
      -300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Acknowledge alert'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Mum is safe'),
      -300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Mum is safe'), findsOneWidget);
  });
}
