enum DebateDifficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case DebateDifficulty.easy:
        return 'Easy';
      case DebateDifficulty.medium:
        return 'Medium';
      case DebateDifficulty.hard:
        return 'Hard';
    }
  }

  String get description {
    switch (this) {
      case DebateDifficulty.easy:
        return 'Friendly & conversational. Forgiving of flaws, explores core concepts gently.';
      case DebateDifficulty.medium:
        return 'Challenging & structured. Demands empirical evidence and counters logical fallacies.';
      case DebateDifficulty.hard:
        return 'Ruthless grandmaster. Steel-mans arguments, relentless cross-examination, razor-sharp counters.';
    }
  }
}
