import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum NodeCategory {
  root,
  coreConcept,
  definition,
  example,
  question,
  studentNote;

  static NodeCategory fromString(String? val) {
    if (val == null) return NodeCategory.coreConcept;
    final normalized = val.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (normalized) {
      case 'root':
        return NodeCategory.root;
      case 'core_concept':
      case 'concept':
        return NodeCategory.coreConcept;
      case 'definition':
      case 'def':
        return NodeCategory.definition;
      case 'example':
      case 'case_study':
        return NodeCategory.example;
      case 'question':
      case 'quiz':
        return NodeCategory.question;
      case 'student_note':
      case 'note':
        return NodeCategory.studentNote;
      default:
        return NodeCategory.coreConcept;
    }
  }

  String get displayName {
    switch (this) {
      case NodeCategory.root:
        return 'Topic Root';
      case NodeCategory.coreConcept:
        return 'Core Concept';
      case NodeCategory.definition:
        return 'Definition';
      case NodeCategory.example:
        return 'Example';
      case NodeCategory.question:
        return 'Question';
      case NodeCategory.studentNote:
        return 'Student Note';
    }
  }

  Color get color {
    switch (this) {
      case NodeCategory.root:
        return AppColors.nodeRoot;
      case NodeCategory.coreConcept:
        return AppColors.nodeConcept;
      case NodeCategory.definition:
        return AppColors.nodeDefinition;
      case NodeCategory.example:
        return AppColors.nodeExample;
      case NodeCategory.question:
        return AppColors.nodeQuestion;
      case NodeCategory.studentNote:
        return AppColors.nodeStudentNote;
    }
  }

  IconData get icon {
    switch (this) {
      case NodeCategory.root:
        return Icons.hub_rounded;
      case NodeCategory.coreConcept:
        return Icons.lightbulb_rounded;
      case NodeCategory.definition:
        return Icons.menu_book_rounded;
      case NodeCategory.example:
        return Icons.science_rounded;
      case NodeCategory.question:
        return Icons.help_outline_rounded;
      case NodeCategory.studentNote:
        return Icons.edit_note_rounded;
    }
  }
}

class MindMapNode {
  final String id;
  String label;
  String summary;
  NodeCategory category;
  String? parentId;
  List<String> childIds;
  List<String> keyPoints;
  bool isKeyTakeaway;
  int importance; // 1 - 5
  String? studentNote;
  final DateTime timestamp;
  double x;
  double y;
  bool isCollapsed;

  MindMapNode({
    required this.id,
    required this.label,
    required this.summary,
    required this.category,
    this.parentId,
    List<String>? childIds,
    List<String>? keyPoints,
    this.isKeyTakeaway = false,
    this.importance = 3,
    this.studentNote,
    DateTime? timestamp,
    this.x = 0.0,
    this.y = 0.0,
    this.isCollapsed = false,
  })  : childIds = childIds ?? [],
        keyPoints = keyPoints ?? [],
        timestamp = timestamp ?? DateTime.now();

  MindMapNode copyWith({
    String? id,
    String? label,
    String? summary,
    NodeCategory? category,
    String? parentId,
    List<String>? childIds,
    List<String>? keyPoints,
    bool? isKeyTakeaway,
    int? importance,
    String? studentNote,
    DateTime? timestamp,
    double? x,
    double? y,
    bool? isCollapsed,
  }) {
    return MindMapNode(
      id: id ?? this.id,
      label: label ?? this.label,
      summary: summary ?? this.summary,
      category: category ?? this.category,
      parentId: parentId ?? this.parentId,
      childIds: childIds ?? List.from(this.childIds),
      keyPoints: keyPoints ?? List.from(this.keyPoints),
      isKeyTakeaway: isKeyTakeaway ?? this.isKeyTakeaway,
      importance: importance ?? this.importance,
      studentNote: studentNote ?? this.studentNote,
      timestamp: timestamp ?? this.timestamp,
      x: x ?? this.x,
      y: y ?? this.y,
      isCollapsed: isCollapsed ?? this.isCollapsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'summary': summary,
      'category': category.name,
      'parentId': parentId,
      'childIds': childIds,
      'keyPoints': keyPoints,
      'isKeyTakeaway': isKeyTakeaway,
      'importance': importance,
      'studentNote': studentNote,
      'timestamp': timestamp.toIso8601String(),
      'x': x,
      'y': y,
      'isCollapsed': isCollapsed,
    };
  }

  factory MindMapNode.fromJson(Map<String, dynamic> json) {
    return MindMapNode(
      id: json['id'] as String,
      label: (json['label'] ?? json['title']) as String? ?? 'Concept',
      summary: json['summary'] as String? ?? '',
      category: NodeCategory.fromString(json['category'] as String?),
      parentId: json['parentId'] as String?,
      childIds: (json['childIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      keyPoints: (json['keyPoints'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isKeyTakeaway: (json['isKeyTakeaway'] ?? json['isImportant']) as bool? ?? false,
      importance: (json['importance'] as num?)?.toInt() ?? 3,
      studentNote: json['studentNote'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      isCollapsed: json['isCollapsed'] as bool? ?? false,
    );
  }
}
