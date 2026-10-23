class AnalysisKeyPoint {
  final String text;
  final String timestamp;

  const AnalysisKeyPoint({
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'timestamp': timestamp,
  };

  factory AnalysisKeyPoint.fromJson(Map<String, dynamic> json) {
    return AnalysisKeyPoint(
      text: json['text']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '00:00',
    );
  }
}

class AnalysisTopic {
  final String name;
  final int importance; // 0 - 100
  final int mentions;

  const AnalysisTopic({
    required this.name,
    required this.importance,
    required this.mentions,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'importance': importance,
    'mentions': mentions,
  };

  factory AnalysisTopic.fromJson(Map<String, dynamic> json) {
    final impRaw = json['importance'];
    final imp = impRaw is num ? impRaw.clamp(0, 100).toInt() : 50;
    final menRaw = json['mentions'];
    final men = menRaw is num ? menRaw.toInt() : 1;
    return AnalysisTopic(
      name: json['name']?.toString() ?? 'General Topic',
      importance: imp,
      mentions: men,
    );
  }
}

class AnalysisTimelinePoint {
  final String time;
  final String label;
  final double value; // 0.0 - 100.0 (engagement or conceptual depth)

  const AnalysisTimelinePoint({
    required this.time,
    required this.label,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
    'time': time,
    'label': label,
    'value': value,
  };

  factory AnalysisTimelinePoint.fromJson(Map<String, dynamic> json) {
    final valRaw = json['value'];
    final val = valRaw is num ? valRaw.toDouble().clamp(0.0, 100.0) : 50.0;
    return AnalysisTimelinePoint(
      time: json['time']?.toString() ?? '00:00',
      label: json['label']?.toString() ?? 'Lecture Segment',
      value: val,
    );
  }
}

class LectureAnalysis {
  final String title;
  final String summary;
  final List<AnalysisKeyPoint> keyPoints;
  final List<AnalysisTopic> topics;
  final List<AnalysisTimelinePoint> timeline;
  final List<String> definitions;
  final List<String> questions;
  final List<String> actionItems;
  final DateTime analyzedAt;

  const LectureAnalysis({
    required this.title,
    required this.summary,
    required this.keyPoints,
    required this.topics,
    required this.timeline,
    required this.definitions,
    required this.questions,
    required this.actionItems,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'summary': summary,
    'key_points': keyPoints.map((k) => k.toJson()).toList(),
    'topics': topics.map((t) => t.toJson()).toList(),
    'timeline': timeline.map((tl) => tl.toJson()).toList(),
    'definitions': definitions,
    'questions': questions,
    'action_items': actionItems,
    'analyzed_at': analyzedAt.toIso8601String(),
  };

  factory LectureAnalysis.fromJson(Map<String, dynamic> json) {
    final kpList = (json['key_points'] as List<dynamic>?)
            ?.map((e) => AnalysisKeyPoint.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];

    final topList = (json['topics'] as List<dynamic>?)
            ?.map((e) => AnalysisTopic.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];

    final tlList = (json['timeline'] as List<dynamic>?)
            ?.map((e) => AnalysisTimelinePoint.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];

    final defList = (json['definitions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final qList = (json['questions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final actList = (json['action_items'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    DateTime parsedDate;
    try {
      parsedDate = json['analyzed_at'] != null
          ? DateTime.parse(json['analyzed_at'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return LectureAnalysis(
      title: json['title']?.toString() ?? 'Lecture Analysis',
      summary: json['summary']?.toString() ?? 'Summary not available.',
      keyPoints: kpList,
      topics: topList,
      timeline: tlList,
      definitions: defList,
      questions: qList,
      actionItems: actList,
      analyzedAt: parsedDate,
    );
  }

  static LectureAnalysis empty([String? title]) => LectureAnalysis(
        title: title ?? 'Class Lecture',
        summary: 'No analysis available yet. Record audio or provide a link to analyze.',
        keyPoints: const [],
        topics: const [],
        timeline: const [],
        definitions: const [],
        questions: const [],
        actionItems: const [],
        analyzedAt: DateTime.now(),
      );
}
