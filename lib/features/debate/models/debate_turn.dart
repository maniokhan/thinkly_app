import '../../mascot/models/mascot_emotion.dart';

enum Speaker {
  user,
  ai,
}

class DebateTurn {
  final Speaker speaker;
  final String text;
  final DateTime timestamp;
  final MascotEmotion? emotion;

  DebateTurn({
    required this.speaker,
    required this.text,
    required this.timestamp,
    this.emotion,
  });
}
