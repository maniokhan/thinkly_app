import 'debate_round.dart';

class DebateRoundScore {
  final DebateRound round;
  final int userScore; // 0-25
  final int aiScore; // 0-25
  final String critique;

  const DebateRoundScore({
    required this.round,
    required this.userScore,
    required this.aiScore,
    required this.critique,
  });
}

class DebateScore {
  final int overallScore; // 0 - 100
  final int logicScore; // 0 - 25
  final int rhetoricScore; // 0 - 25
  final int responsivenessScore; // 0 - 25
  final int timeManagementScore; // 0 - 25
  final String winnerVerdict; // User Wins by Decision | AI Wins by Decision | Split Decision
  final String judgeCommentary;
  final List<DebateRoundScore> roundScores;
  final List<String> strengths;
  final List<String> weaknesses;
  final Duration debateDuration;
  final int turnsCount;
  final int interruptionCount;

  const DebateScore({
    required this.overallScore,
    required this.logicScore,
    required this.rhetoricScore,
    required this.responsivenessScore,
    required this.timeManagementScore,
    required this.winnerVerdict,
    required this.judgeCommentary,
    required this.roundScores,
    required this.strengths,
    required this.weaknesses,
    required this.debateDuration,
    required this.turnsCount,
    required this.interruptionCount,
  });

  /// Generate a realistic debate rubric evaluation based on session performance
  factory DebateScore.calculateFromSession({
    required Duration duration,
    required int turnsCount,
    required int interruptionCount,
    required String topic,
    required String userStance,
  }) {
    // Rubric 1: Logic & Evidence (0 - 25)
    final logic = (17 + (turnsCount % 6) - (interruptionCount > 3 ? 2 : 0)).clamp(12, 24);

    // Rubric 2: Rhetoric & Style (0 - 25)
    final rhetoric = (18 + (duration.inSeconds % 5)).clamp(14, 25);

    // Rubric 3: Responsiveness to Opponent (0 - 25)
    final responsiveness = (16 + (turnsCount >= 4 ? 5 : 2) - (interruptionCount % 3)).clamp(12, 24);

    // Rubric 4: Time Management & Composure (0 - 25)
    final timeScore = (duration.inSeconds >= 45 ? 21 : 16) - (interruptionCount > 4 ? 3 : 0);
    final timeManagement = timeScore.clamp(10, 24);

    final overall = logic + rhetoric + responsiveness + timeManagement;

    // Winner declaration
    String winner;
    String commentary;
    if (overall >= 78) {
      winner = 'User Wins by Decision';
      commentary =
          'The affirmative delivered exceptional rhetorical command and incisive cross-examination counters. While the AI maintained steady pressure, the user\'s closing rebuttal decisively carried the floor.';
    } else if (overall >= 66) {
      winner = 'Split Decision';
      commentary =
          'A fiercely contested clash of philosophies with razor-thin margins. Both sides traded formidable points on core premises, leaving the adjudicators deadlocked on overall rhetorical impact.';
    } else {
      winner = 'AI Wins by Decision';
      commentary =
          'The AI opponent successfully exploited structural inconsistencies in the opening framing. Tighter evidence chaining and proactive rebuttal pacing would elevate future competitive engagements.';
    }

    final roundScores = [
      DebateRoundScore(
        round: DebateRound.opening,
        userScore: (logic * 0.95).round().clamp(10, 25),
        aiScore: 21,
        critique: 'Clear initial thesis presented for $userStance; well-framed context.',
      ),
      DebateRoundScore(
        round: DebateRound.rebuttal,
        userScore: (responsiveness * 0.95).round().clamp(10, 25),
        aiScore: 22,
        critique: 'Pointed counter-arguments neutralized the AI\'s first premise.',
      ),
      DebateRoundScore(
        round: DebateRound.crossExamination,
        userScore: (rhetoric * 0.92).round().clamp(10, 25),
        aiScore: 20,
        critique: 'Sharp, fast-paced exchanges; composure was tested under pressure.',
      ),
      DebateRoundScore(
        round: DebateRound.closing,
        userScore: (timeManagement * 0.98).round().clamp(10, 25),
        aiScore: 21,
        critique: 'Effective synthesis of the debate\'s critical battleground issues.',
      ),
    ];

    final strengths = [
      'Articulated the core premises of the "$userStance" stance clearly and directly.',
      'Maintained consistent composure and rapid response timing during rapid exchanges.',
      'Effectively challenged the opponent\'s key counterarguments on critical points.',
    ];

    final weaknesses = [
      'Incorporate more empirical citations and statistical precedents to cement rebuttals.',
      'Watch out for defensive rhetorical traps laid by the AI in high-tempo rounds.',
      'Anticipate the opponent\'s follow-up counter-punch before yielding the spoken floor.',
    ];

    return DebateScore(
      overallScore: overall,
      logicScore: logic,
      rhetoricScore: rhetoric,
      responsivenessScore: responsiveness,
      timeManagementScore: timeManagement,
      winnerVerdict: winner,
      judgeCommentary: commentary,
      roundScores: roundScores,
      strengths: strengths,
      weaknesses: weaknesses,
      debateDuration: duration,
      turnsCount: turnsCount,
      interruptionCount: interruptionCount,
    );
  }
}
