import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sohba/models/prayer_log.dart';
import 'package:sohba/services/prayer_engine.dart';
import 'package:sohba/widgets/prayer_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  PrayerLog empty(PrayerName p) => PrayerLog(
        id: 'test',
        userId: 'u1',
        date: DateTime.now(),
        prayer: p,
      );

  testWidgets('shows prayer name', (tester) async {
    final p = PrayerName.fajr;
    final timeline = PrayerEngine.computeTimeline(prayer: p);
    await tester.pumpWidget(wrap(PrayerCard(
      prayer: p,
      log: empty(p),
      timeline: timeline,
      onTap: () {},
    )));
    expect(find.text(p.arabicName), findsOneWidget);
  });

  testWidgets('shows status chip', (tester) async {
    final p = PrayerName.fajr;
    final timeline = PrayerEngine.computeTimeline(prayer: p);
    final log = empty(p).copyWith(status: PrayerStatus.congregation, hasanat: 27);
    await tester.pumpWidget(wrap(PrayerCard(
      prayer: p,
      log: log,
      timeline: timeline,
      onTap: () {},
    )));
    expect(find.text('جماعة'), findsOneWidget);
  });

  testWidgets('calls onTap when pressed', (tester) async {
    var tapped = false;
    final p = PrayerName.dhuhr;
    final timeline = PrayerEngine.computeTimeline(prayer: p);
    await tester.pumpWidget(wrap(PrayerCard(
      prayer: p,
      log: empty(p),
      timeline: timeline,
      onTap: () => tapped = true,
    )));
    await tester.tap(find.byType(PrayerCard));
    await tester.pump();
    expect(tapped, true);
  });
}