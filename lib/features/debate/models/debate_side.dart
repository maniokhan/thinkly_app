enum DebateSide {
  forStance,
  againstStance;

  String get label {
    switch (this) {
      case DebateSide.forStance:
        return 'For (Pro)';
      case DebateSide.againstStance:
        return 'Against (Con)';
    }
  }

  DebateSide get opposite {
    return this == DebateSide.forStance ? DebateSide.againstStance : DebateSide.forStance;
  }
}
