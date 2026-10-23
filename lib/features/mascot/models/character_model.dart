import 'package:flutter/material.dart';

class CharacterModel {
  final String name;
  final String tagline;
  final String description;
  final Color bodyColor;
  final Color eyeColor;
  final String defaultVoice;

  const CharacterModel({
    required this.name,
    required this.tagline,
    required this.description,
    required this.bodyColor,
    required this.eyeColor,
    required this.defaultVoice,
  });

  static const List<CharacterModel> allCharacters = [
    CharacterModel(
      name: 'Strobi',
      tagline: 'The Logical Sentinel',
      description: 'Balanced, fair, and meticulous. Great for structured debates.',
      bodyColor: Color(0xFF5B7FE5),
      eyeColor: Color(0xFF111316),
      defaultVoice: 'Puck',
    ),
    CharacterModel(
      name: 'Grok bot',
      tagline: 'The Sharp Contrarian',
      description: 'Direct, incisive, and unyielding. Challenges every premise.',
      bodyColor: Color(0xFF1E293B),
      eyeColor: Color(0xFFFFFFFF),
      defaultVoice: 'Fenrir',
    ),
    CharacterModel(
      name: 'Nova',
      tagline: 'The Socratic Inquirer',
      description: 'Elegant and curious. Probes deeper with philosophical depth.',
      bodyColor: Color(0xFF55B6C3),
      eyeColor: Color(0xFF111316),
      defaultVoice: 'Aoede',
    ),
    CharacterModel(
      name: 'Freddy',
      tagline: 'The Pragmatic Realist',
      description: 'Grounds every argument in data, history, and real-world results.',
      bodyColor: Color(0xFFE6855C),
      eyeColor: Color(0xFFFFFFFF),
      defaultVoice: 'Charon',
    ),
    CharacterModel(
      name: 'Kirby',
      tagline: 'The Energetic Rhetorician',
      description: 'Vibrant, witty, and persuasive. Uses vivid metaphors and flair.',
      bodyColor: Color(0xFFFFC2E9),
      eyeColor: Color(0xFF3E4E65),
      defaultVoice: 'Kore',
    ),
    CharacterModel(
      name: 'Cubee',
      tagline: 'The First-Principles Thinker',
      description: 'Breaks complex issues into elementary building blocks.',
      bodyColor: Color(0xFFE65C5C),
      eyeColor: Color(0xFF111316),
      defaultVoice: 'Puck',
    ),
  ];

  static CharacterModel findByName(String name) {
    return allCharacters.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => allCharacters.first,
    );
  }
}
