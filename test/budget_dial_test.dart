import 'package:budget_bites/widgets/budget_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BudgetDial shows remaining amount', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: BudgetDial(spent: 30, budget: 75, currency: '\$')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('\$45.00'), findsOneWidget);
  });

  testWidgets('BudgetDial shows over-budget state', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: BudgetDial(spent: 90, budget: 75, currency: '\$')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Over by'), findsOneWidget);
    expect(find.text('\$15.00'), findsOneWidget);
  });
}
