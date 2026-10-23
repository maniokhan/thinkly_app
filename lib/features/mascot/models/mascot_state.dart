enum MascotState {
  waking,
  idle,
  listening,
  speaking,
  happy,
  confused,
  drowsy;

  String get label {
    switch (this) {
      case MascotState.waking:
        return 'Waking Up';
      case MascotState.idle:
        return 'Idle';
      case MascotState.listening:
        return 'Listening';
      case MascotState.speaking:
        return 'Speaking';
      case MascotState.happy:
        return 'Happy';
      case MascotState.confused:
        return 'Confused';
      case MascotState.drowsy:
        return 'Drowsy';
    }
  }

  static MascotState fromString(String? value) {
    if (value == null) return MascotState.idle;
    final normalized = value.toLowerCase().trim();
    for (final s in MascotState.values) {
      if (s.name == normalized) return s;
    }
    return MascotState.idle;
  }
}
