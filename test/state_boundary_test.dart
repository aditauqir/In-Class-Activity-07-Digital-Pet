import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_pet/main.dart';

void main() {
  testWidgets('State boundary test: Meters stay clamped between 0 and 100',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const DigitalPetApp());

    final feedButton = find.text('Feed (-10 Hunger)');
    final playButton = find.text('Play (+15 Happy)');
    final restButton = find.text('Rest (+25 Energy)');

    await tester.ensureVisible(feedButton);

    // Feed repeatedly down to 0 hunger
    for (int i = 0; i < 8; i++) {
      await tester.tap(feedButton);
      await tester.pump();
    }
    // Hunger and happiness both clamp at 0 and do not drop below 0
    expect(find.text('0 / 100'), findsWidgets);

    // Rest repeatedly up to 100 energy
    await tester.ensureVisible(restButton);
    for (int i = 0; i < 5; i++) {
      await tester.tap(restButton);
      await tester.pump();
    }
    // Energy must clamp at 100 and not exceed 100
    expect(find.text('100 / 100'), findsWidgets);

    // Play repeatedly: test happiness ceiling and energy exhaustion
    await tester.ensureVisible(playButton);
    for (int i = 0; i < 7; i++) {
      await tester.tap(playButton);
      await tester.pump();
    }

    // When energy drops below 15, play should be restricted and show message
    expect(find.textContaining('exhausted'), findsOneWidget);
  });

  testWidgets('Win condition: Happiness > 80 initiates win timer countdown',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const DigitalPetApp());

    final playButton = find.text('Play (+15 Happy)');
    await tester.ensureVisible(playButton);

    // Initial happiness is 50. Tap play twice: 50 -> 65 -> 80
    await tester.tap(playButton);
    await tester.pump();
    await tester.tap(playButton);
    await tester.pump();

    // At exactly 80, win timer must NOT start (must be strictly > 80)
    expect(find.textContaining('Win Countdown'), findsNothing);

    // Tap play once more: 80 -> 95 (> 80)
    await tester.tap(playButton);
    await tester.pump();

    // Now win countdown must be active
    expect(find.textContaining('Win Countdown'), findsOneWidget);
  });

  testWidgets('Reset action restores initial state and cancels win countdown',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const DigitalPetApp());

    final playButton = find.text('Play (+15 Happy)');
    final resetButton = find.text('Reset');

    await tester.ensureVisible(playButton);
    // Push happiness above 80
    await tester.tap(playButton);
    await tester.pump();
    await tester.tap(playButton);
    await tester.pump();
    await tester.tap(playButton);
    await tester.pump();

    expect(find.textContaining('Win Countdown'), findsOneWidget);

    // Tap Reset
    await tester.ensureVisible(resetButton);
    await tester.tap(resetButton);
    await tester.pump();

    // Countdown canceled, meters restored to 50, 50, 70
    expect(find.textContaining('Win Countdown'), findsNothing);
    expect(find.text('50 / 100'), findsNWidgets(2));
    expect(find.text('70 / 100'), findsOneWidget);
  });
}
