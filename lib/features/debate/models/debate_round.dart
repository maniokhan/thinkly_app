enum DebateRound {
  opening(
    roundNumber: 1,
    title: 'Opening Arguments',
    description: 'Establish core premise and framing',
    durationSeconds: 60,
  ),
  rebuttal(
    roundNumber: 2,
    title: 'Rebuttal',
    description: 'Attack opponent logic and counter claims',
    durationSeconds: 60,
  ),
  crossExamination(
    roundNumber: 3,
    title: 'Cross-Examination',
    description: 'Fast-paced probing questions and defenses',
    durationSeconds: 45,
  ),
  closing(
    roundNumber: 4,
    title: 'Closing Statements',
    description: 'Summarize winning arguments and conclude',
    durationSeconds: 60,
  );

  final int roundNumber;
  final String title;
  final String description;
  final int durationSeconds;

  const DebateRound({
    required this.roundNumber,
    required this.title,
    required this.description,
    required this.durationSeconds,
  });

  String get label => 'Round $roundNumber of 4 · $title';

  DebateRound? get next {
    switch (this) {
      case DebateRound.opening:
        return DebateRound.rebuttal;
      case DebateRound.rebuttal:
        return DebateRound.crossExamination;
      case DebateRound.crossExamination:
        return DebateRound.closing;
      case DebateRound.closing:
        return null;
    }
  }
}
