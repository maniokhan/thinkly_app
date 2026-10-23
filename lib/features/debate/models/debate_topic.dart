class DebateTopic {
  final String title;
  final String category;
  final String contextDescription;

  const DebateTopic({
    required this.title,
    required this.category,
    required this.contextDescription,
  });

  static const List<DebateTopic> presets = [
    DebateTopic(
      title: 'AI will enhance rather than diminish human creativity',
      category: 'Technology',
      contextDescription: 'Debate on generative AI, original thought, artistic soul, and cognitive automation.',
    ),
    DebateTopic(
      title: 'Universal Basic Income is essential in an automated economy',
      category: 'Economics',
      contextDescription: 'Debate on economic safety nets, inflation, workforce motivation, and dignity of work.',
    ),
    DebateTopic(
      title: 'Social media platforms have done more net harm than good',
      category: 'Society',
      contextDescription: 'Debate on mental health, polarized discourse, connectivity, and digital democracy.',
    ),
    DebateTopic(
      title: 'Humanity should prioritize Mars colonization over Earth restoration',
      category: 'Science',
      contextDescription: 'Debate on existential redundancy, planetary stewardship, and astronomical resource allocation.',
    ),
    DebateTopic(
      title: 'Remote work produces superior societal and economic outcomes to office work',
      category: 'Workplace',
      contextDescription: 'Debate on autonomy, work-life balance, serendipity, and corporate culture.',
    ),
    DebateTopic(
      title: 'Nuclear power is indispensable to solving the climate crisis',
      category: 'Environment',
      contextDescription: 'Debate on zero-carbon baseload energy, safety protocols, waste management, and solar/wind parity.',
    ),
  ];
}
