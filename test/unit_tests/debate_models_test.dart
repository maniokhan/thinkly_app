import 'package:flutter_test/flutter_test.dart';
import 'package:thinkly_app/features/debate/models/debate_difficulty.dart';
import 'package:thinkly_app/features/debate/models/debate_score.dart';
import 'package:thinkly_app/features/debate/models/debate_side.dart';
import 'package:thinkly_app/features/debate/models/debate_topic.dart';
import 'package:thinkly_app/features/mascot/models/character_model.dart';
import 'package:thinkly_app/features/mascot/models/mascot_emotion.dart';
import 'package:thinkly_app/features/mascot/models/mascot_state.dart';

void main() {
  group('Debate Models Tests', () {
    test('DebateSide opposite returns the inverted stance', () {
      expect(DebateSide.forStance.opposite, DebateSide.againstStance);
      expect(DebateSide.againstStance.opposite, DebateSide.forStance);
    });

    test('DebateDifficulty provides valid descriptions', () {
      expect(DebateDifficulty.easy.description.isNotEmpty, true);
      expect(DebateDifficulty.medium.description.isNotEmpty, true);
      expect(DebateDifficulty.hard.description.isNotEmpty, true);
    });

    test('DebateScore calculates valid rubric within 0-100 range', () {
      final score = DebateScore.calculateFromSession(
        duration: const Duration(minutes: 3, seconds: 30),
        turnsCount: 6,
        interruptionCount: 1,
        topic: 'AI and Creativity',
        userStance: 'For (Pro)',
      );

      expect(score.overallScore, inInclusiveRange(0, 100));
      expect(score.logicScore, inInclusiveRange(0, 25));
      expect(score.rhetoricScore, inInclusiveRange(0, 25));
      expect(score.responsivenessScore, inInclusiveRange(0, 25));
      expect(score.timeManagementScore, inInclusiveRange(0, 25));
      expect(score.roundScores.length, 4);
      expect(score.strengths.isNotEmpty, true);
      expect(score.weaknesses.isNotEmpty, true);
      expect(score.winnerVerdict.isNotEmpty, true);
      expect(score.judgeCommentary.isNotEmpty, true);
    });

    test('DebateTopic presets contain diverse topics', () {
      expect(DebateTopic.presets.length, greaterThanOrEqualTo(5));
      for (final topic in DebateTopic.presets) {
        expect(topic.title.isNotEmpty, true);
        expect(topic.category.isNotEmpty, true);
      }
    });

    test('MascotEmotion and MascotState string parsers handle case insensitivity', () {
      expect(MascotEmotion.fromString('HAPPY'), MascotEmotion.happy);
      expect(MascotEmotion.fromString('angry'), MascotEmotion.angry);
      expect(MascotEmotion.fromString('non_existent'), MascotEmotion.neutral);

      expect(MascotState.fromString('WAKING'), MascotState.waking);
      expect(MascotState.fromString('speaking'), MascotState.speaking);
      expect(MascotState.fromString('invalid'), MascotState.idle);
    });

    test('CharacterModel includes all 6 core characters', () {
      final names = CharacterModel.allCharacters.map((c) => c.name).toList();
      expect(names, containsAll(['Strobi', 'Grok bot', 'Nova', 'Freddy', 'Kirby', 'Cubee']));
    });
  });
}
