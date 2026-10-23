import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinkly_app/features/debate/models/debate_turn.dart';
import 'package:thinkly_app/features/debate/widgets/transcript_sheet.dart';

void main() {
  testWidgets('TranscriptSheet renders turns and triggers onClose', (tester) async {
    bool closed = false;
    final turns = [
      DebateTurn(
        speaker: Speaker.user,
        text: 'The affirmative case is sound.',
        timestamp: DateTime.now(),
      ),
      DebateTurn(
        speaker: Speaker.ai,
        text: 'I disagree completely with that premise.',
        timestamp: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSheet(
            turns: turns,
            onClose: () => closed = true,
          ),
        ),
      ),
    );

    // Verify turn text is displayed
    expect(find.text('The affirmative case is sound.'), findsOneWidget);
    expect(find.text('I disagree completely with that premise.'), findsOneWidget);
    expect(find.text('2 turns'), findsOneWidget);

    // Verify close icon button is present and triggers onClose
    final closeButton = find.byTooltip('Close Transcript');
    expect(closeButton, findsOneWidget);
    await tester.tap(closeButton);
    await tester.pump();

    expect(closed, isTrue);
  });
}
