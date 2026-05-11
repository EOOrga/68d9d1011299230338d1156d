import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foyer_fargeaula_ops/main.dart';

Future<void> pumpOperationsApp(WidgetTester tester) async {
  final store = OperationsStore(screenshotMode: true);
  final data = await store.load();
  await tester.pumpWidget(FargeaulaOpsApp(store: store, initialData: data));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows operations dashboard and navigates tabs', (tester) async {
    await pumpOperationsApp(tester);

    expect(find.text(publicAppName), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_quality')));
    await tester.pumpAndSettle();

    expect(find.text('Quality control'), findsOneWidget);
    expect(find.textContaining('checks complete'), findsOneWidget);
  });

  testWidgets('creates a local appointment record', (tester) async {
    await pumpOperationsApp(tester);

    await tester.tap(find.byKey(const Key('nav_appointments')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add_record_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('appointment_guest_field')),
      'New family visit',
    );
    await tester.enterText(
      find.byKey(const Key('appointment_service_field')),
      'Front desk intake',
    );
    await tester.tap(find.byKey(const Key('save_appointment_button')));
    await tester.pumpAndSettle();

    expect(find.text('New family visit'), findsOneWidget);
    expect(
      find.text('Front desk intake | May 12, 2026 | 10:00 AM'),
      findsOneWidget,
    );
  });
}
