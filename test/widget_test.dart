import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinkly_app/main.dart';

void main() {
  setUp(() {
    Animate.restartOnHotReload = false;
  });

  testWidgets('AI Debate App smoke test', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(const AIDebateApp());
    // Advance time past entrance delays
    await tester.pump(const Duration(seconds: 1));

    // Verify home screen elements are present
    expect(find.text('AI DEBATE ARENA'), findsOneWidget);
    expect(find.text('START DEBATE'), findsOneWidget);

    // Unmount app and advance past any cleanup timers
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
