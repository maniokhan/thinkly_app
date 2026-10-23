import 'dart:convert';
import '../../../core/models/lecture_analysis.dart';
import 'mind_map_node.dart';
import 'mind_map_edge.dart';

class LectureSession {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime lastModified;
  final List<MindMapNode> nodes;
  final List<MindMapEdge> edges;
  String transcriptHistory;
  String? aiStudyGuide;
  LectureAnalysis? analysis;

  LectureSession({
    required this.id,
    required this.title,
    DateTime? createdAt,
    DateTime? lastModified,
    List<MindMapNode>? nodes,
    List<MindMapEdge>? edges,
    this.transcriptHistory = '',
    this.aiStudyGuide,
    this.analysis,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now(),
        nodes = nodes ?? [],
        edges = edges ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'lastModified': lastModified.toIso8601String(),
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
        'transcriptHistory': transcriptHistory,
        'aiStudyGuide': aiStudyGuide,
        'analysis': analysis?.toJson(),
      };

  factory LectureSession.fromJson(Map<String, dynamic> json) {
    LectureAnalysis? parsedAnalysis;
    if (json['analysis'] != null && json['analysis'] is Map) {
      try {
        parsedAnalysis = LectureAnalysis.fromJson(
            Map<String, dynamic>.from(json['analysis'] as Map));
      } catch (_) {}
    }

    return LectureSession(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Lecture',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastModified: json['lastModified'] != null
          ? DateTime.tryParse(json['lastModified'] as String) ?? DateTime.now()
          : DateTime.now(),
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((e) => MindMapNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) => MindMapEdge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      transcriptHistory: json['transcriptHistory'] as String? ?? '',
      aiStudyGuide: json['aiStudyGuide'] as String?,
      analysis: parsedAnalysis,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory LectureSession.fromJsonString(String source) =>
      LectureSession.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
