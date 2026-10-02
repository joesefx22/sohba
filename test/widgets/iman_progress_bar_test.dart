import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sohba/widgets/iman_progress_bar.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows level badge', (tester) async {
    await tester.pumpWidget(wrap(const ImanProgressBar(
      currentIman: 50,
      nextTierAt: 100,
      level: 1,
    )));
    await tester.pump();
    expect(find.textContaining('المستوى'), findsOneWidget);
  });

  testWidgets('shows iman numbers', (tester) async {
    await tester.pumpWidget(wrap(const ImanProgressBar(
      currentIman: 42.5,
      nextTierAt: 100,
      level: 1,
    )));
    await tester.pump();
    expect(find.textContaining('42.5'), findsOneWidget);
  });

  testWidgets('handles zero next tier safely', (tester) async {
    await tester.pumpWidget(wrap(const ImanProgressBar(
      currentIman: 0,
      nextTierAt: 0,
      level: 1,
    )));
    await tester.pump();
    expect(find.byType(ImanProgressBar), findsOneWidget);
  });
}