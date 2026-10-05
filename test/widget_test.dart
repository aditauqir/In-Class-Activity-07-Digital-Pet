import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_pet/main.dart';

void main() {
  testWidgets('Digital Pet smoke and care action test', (WidgetTester tester) async {
    // Set a realistic mobile device screen size for the test
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const DigitalPetApp());

    // Verify initial values
    expect(find.text('Pip'), findsWidgets);
    expect(find.text('Mood: Neutral'), findsOneWidget);
    expect(find.text('50 / 100'), findsNWidgets(2)); // Happiness & Hunger both start at 50

    // Feed the pet
    final feedButton = find.text('Feed (-10 Hunger)');
    await tester.ensureVisible(feedButton);
    await tester.tap(feedButton);
    await tester.pump();

    // Verify hunger decreased (50 - 10 = 40)
    expect(find.text('40 / 100'), findsOneWidget);

    // Play with the pet
    final playButton = find.text('Play (+15 Happy)');
    await tester.ensureVisible(playButton);
    await tester.tap(playButton);
    await tester.pump();

    // Reset game
    final resetButton = find.text('Reset');
    await tester.ensureVisible(resetButton);
    await tester.tap(resetButton);
    await tester.pump();

    // Verify reset restores initial state
    expect(find.text('Pet care restarted!'), findsOneWidget);
    expect(find.text('50 / 100'), findsNWidgets(2));
  });
}
