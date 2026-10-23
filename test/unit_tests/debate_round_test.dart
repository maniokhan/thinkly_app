import 'package:flutter_test/flutter_test.dart';
import 'package:thinkly_app/features/debate/models/debate_round.dart';

void main() {
  group('DebateRound Tests', () {
    test('Debate rounds progress sequentially across 4 formal stages', () {
      expect(DebateRound.opening.next, DebateRound.rebuttal);
      expect(DebateRound.rebuttal.next, DebateRound.crossExamination);
      expect(DebateRound.crossExamination.next, DebateRound.closing);
      expect(DebateRound.closing.next, isNull);
    });

    test('Each debate round has valid duration and titles', () {
      for (final round in DebateRound.values) {
        expect(round.roundNumber, inInclusiveRange(1, 4));
        expect(round.durationSeconds, greaterThan(0));
        expect(round.title.isNotEmpty, isTrue);
        expect(round.label.contains('Round ${round.roundNumber} of 4'), isTrue);
      }
    });
  });
}
