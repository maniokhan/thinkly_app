class MindMapEdge {
  final String fromId;
  final String toId;
  final String? label;

  const MindMapEdge({
    required this.fromId,
    required this.toId,
    this.label,
  });

  Map<String, dynamic> toJson() => {
    'fromId': fromId,
    'toId': toId,
    if (label != null) 'label': label,
  };

  factory MindMapEdge.fromJson(Map<String, dynamic> json) => MindMapEdge(
    fromId: json['fromId'] as String,
    toId: json['toId'] as String,
    label: json['label'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MindMapEdge &&
          runtimeType == other.runtimeType &&
          fromId == other.fromId &&
          toId == other.toId;

  @override
  int get hashCode => fromId.hashCode ^ toId.hashCode;
}
