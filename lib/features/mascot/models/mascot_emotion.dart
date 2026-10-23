enum MascotEmotion {
  neutral,
  happy,
  angry,
  sad,
  surprised,
  confused,
  thinking,
  excited,
  laughing,
  annoyed;

  String get label {
    switch (this) {
      case MascotEmotion.neutral:
        return 'Neutral';
      case MascotEmotion.happy:
        return 'Happy';
      case MascotEmotion.angry:
        return 'Angry';
      case MascotEmotion.sad:
        return 'Sad';
      case MascotEmotion.surprised:
        return 'Surprised';
      case MascotEmotion.confused:
        return 'Confused';
      case MascotEmotion.thinking:
        return 'Thinking';
      case MascotEmotion.excited:
        return 'Excited';
      case MascotEmotion.laughing:
        return 'Laughing';
      case MascotEmotion.annoyed:
        return 'Annoyed';
    }
  }

  static MascotEmotion fromString(String? value) {
    if (value == null) return MascotEmotion.neutral;
    final normalized = value.toLowerCase().trim();
    for (final e in MascotEmotion.values) {
      if (e.name == normalized) return e;
    }
    return MascotEmotion.neutral;
  }
}
