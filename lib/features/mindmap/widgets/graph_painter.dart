import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/mind_map_node.dart';
import '../models/mind_map_edge.dart';

class GraphPainter extends CustomPainter {
  final List<MindMapNode> nodes;
  final List<MindMapEdge> edges;
  final String? selectedNodeId;
  final Offset centerOffset;
  final Set<String> hiddenNodeIds;

  GraphPainter({
    required this.nodes,
    required this.edges,
    required this.selectedNodeId,
    required this.centerOffset,
    this.hiddenNodeIds = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawMatteDotGrid(canvas, size);
    _drawEdges(canvas);
  }

  void _drawMatteDotGrid(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = AppColors.dotGrid
      ..style = PaintingStyle.fill;

    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  void _drawEdges(Canvas canvas) {
    final nodeMap = {for (var n in nodes) n.id: n};

    final defaultPaint = Paint()
      ..color = AppColors.borderLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final selectedPaint = Paint()
      ..color = AppColors.borderSelected
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const double halfWidth = 122.0;

    for (final edge in edges) {
      if (hiddenNodeIds.contains(edge.fromId) || hiddenNodeIds.contains(edge.toId)) {
        continue;
      }

      final from = nodeMap[edge.fromId];
      final to = nodeMap[edge.toId];
      if (from == null || to == null) continue;

      final Offset p1;
      final Offset p2;

      if (to.x >= from.x) {
        p1 = Offset(from.x + centerOffset.dx + halfWidth, from.y + centerOffset.dy);
        p2 = Offset(to.x + centerOffset.dx - halfWidth, to.y + centerOffset.dy);
      } else {
        p1 = Offset(from.x + centerOffset.dx - halfWidth, from.y + centerOffset.dy);
        p2 = Offset(to.x + centerOffset.dx + halfWidth, to.y + centerOffset.dy);
      }

      final isEdgeSelected = from.id == selectedNodeId || to.id == selectedNodeId;

      final path = Path();
      path.moveTo(p1.dx, p1.dy);

      final dx = (p2.dx - p1.dx) * 0.5;
      path.cubicTo(
        p1.dx + dx,
        p1.dy,
        p2.dx - dx,
        p2.dy,
        p2.dx,
        p2.dy,
      );

      canvas.drawPath(path, isEdgeSelected ? selectedPaint : defaultPaint);

      final midPoint = Offset(
        (p1.dx * 0.45) + (p2.dx * 0.55),
        (p1.dy * 0.45) + (p2.dy * 0.55),
      );
      final pulseDotPaint = Paint()
        ..color = isEdgeSelected ? AppColors.indigo : AppColors.borderSubtle
        ..style = PaintingStyle.fill;
      canvas.drawCircle(midPoint, isEdgeSelected ? 2.5 : 1.8, pulseDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.edges != edges ||
        oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.hiddenNodeIds != hiddenNodeIds;
  }
}
