import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/mind_map_node.dart';
import '../providers/mind_map_provider.dart';
import 'graph_painter.dart';

class GraphCanvas extends StatefulWidget {
  final VoidCallback onNodeSelected;

  const GraphCanvas({super.key, required this.onNodeSelected});

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  late TransformationController _transformationController;
  static const double _canvasSize = 4000.0;
  static const Offset _centerOffset = Offset(_canvasSize / 2, _canvasSize / 2);
  bool _hasInitialCentered = false;
  Size _lastViewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  void _centerCanvas([Size? viewportSize]) {
    final size = viewportSize ?? _lastViewportSize;
    if (size.width > 0 && size.height > 0) {
      final double initialX = -(_centerOffset.dx - (size.width / 2));
      final double initialY = -(_centerOffset.dy - (size.height / 2));
      _transformationController.value = Matrix4.translationValues(initialX, initialY, 1.0);
    }
  }

  void _zoom(double factor) {
    final matrix = _transformationController.value.clone();
    matrix.multiply(Matrix4.diagonal3Values(factor, factor, 1.0));
    _transformationController.value = matrix;
  }

  Set<String> _getHiddenNodeIds(List<MindMapNode> allNodes) {
    final hiddenIds = <String>{};
    final nodeMap = {for (var n in allNodes) n.id: n};

    void markDescendantsHidden(MindMapNode parent) {
      for (final childId in parent.childIds) {
        if (hiddenIds.add(childId)) {
          final child = nodeMap[childId];
          if (child != null) {
            markDescendantsHidden(child);
          }
        }
      }
    }

    for (final node in allNodes) {
      if (node.isCollapsed) {
        markDescendantsHidden(node);
      }
    }
    return hiddenIds;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MindMapProvider>();
    final nodes = provider.nodes;
    final edges = provider.edges;
    final selectedNode = provider.selectedNode;
    final hiddenNodeIds = _getHiddenNodeIds(nodes);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        _lastViewportSize = viewportSize;

        if (!_hasInitialCentered && constraints.maxWidth > 0) {
          _hasInitialCentered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _centerCanvas(viewportSize);
          });
        }

        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformationController,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(1200),
              minScale: 0.2,
              maxScale: 2.8,
              child: SizedBox(
                width: _canvasSize,
                height: _canvasSize,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GraphPainter(
                          nodes: nodes,
                          edges: edges,
                          selectedNodeId: selectedNode?.id,
                          centerOffset: _centerOffset,
                          hiddenNodeIds: hiddenNodeIds,
                        ),
                      ),
                    ),
                    for (final node in nodes)
                      if (!hiddenNodeIds.contains(node.id))
                        _buildNodeWidget(context, provider, node, selectedNode?.id == node.id),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 84,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCanvasIconButton(
                      icon: Icons.add,
                      tooltip: 'Zoom In',
                      onTap: () => _zoom(1.2),
                    ),
                    _buildCanvasIconButton(
                      icon: Icons.remove,
                      tooltip: 'Zoom Out',
                      onTap: () => _zoom(0.8),
                    ),
                    const Divider(height: 6, thickness: 1, color: AppColors.border),
                    _buildCanvasIconButton(
                      icon: Icons.filter_center_focus_rounded,
                      tooltip: 'Center Graph',
                      onTap: () => _centerCanvas(viewportSize),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNodeWidget(
    BuildContext context,
    MindMapProvider provider,
    MindMapNode node,
    bool isSelected,
  ) {
    const double nodeWidth = 244.0;
    final isRoot = node.category == NodeCategory.root;
    final isActiveTopic = provider.activeNodeId == node.id;
    final left = _centerOffset.dx + node.x - (nodeWidth / 2);
    final top = _centerOffset.dy + node.y - (isRoot ? 48 : 42);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          provider.selectNode(node);
          widget.onNodeSelected();
        },
        onPanUpdate: (details) {
          final scale = _transformationController.value.getMaxScaleOnAxis();
          final effectiveScale = scale > 0.05 ? scale : 1.0;
          provider.moveNode(node.id, Offset(details.delta.dx / effectiveScale, details.delta.dy / effectiveScale));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: nodeWidth,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isRoot ? AppColors.cardRoot : AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActiveTopic
                  ? AppColors.alabaster
                  : (isRoot
                      ? (isSelected ? AppColors.textPrimary : AppColors.borderRoot)
                      : (isSelected ? AppColors.borderSelected : const Color(0xFF2E2E2E))),
              width: isActiveTopic ? 1.8 : (isRoot ? 1.5 : (isSelected ? 1.5 : 1.0)),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isActiveTopic)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.pillTag,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.record_voice_over_rounded, size: 10, color: AppColors.textPrimary),
                          SizedBox(width: 4),
                          Text(
                            'LIVE FOCUS',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (node.studentNote != null && node.studentNote!.isNotEmpty)
                        Tooltip(
                          message: 'Contains Personal Student Note',
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.pillTag,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_note_rounded, size: 14, color: AppColors.textPrimary),
                          ),
                        ),
                      if (node.isKeyTakeaway)
                        const Icon(Icons.star_rounded, size: 15, color: AppColors.amber),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                node.label,
                style: TextStyle(
                  fontSize: isRoot ? 14 : 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                node.summary,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (node.keyPoints.isNotEmpty) ...[
                const SizedBox(height: 6),
                ...node.keyPoints.take(2).map(
                      (kp) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                kp,
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
              if (node.studentNote != null && node.studentNote!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141A18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF22362A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.edit_note_rounded, size: 11, color: AppColors.emerald),
                          SizedBox(width: 4),
                          Text(
                            'STUDENT NOTE',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.emerald,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        node.studentNote!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFE2E8F0),
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (node.childIds.isNotEmpty)
                    InkWell(
                      onTap: () => provider.toggleNodeCollapsed(node.id),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.pillTag,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              node.isCollapsed ? Icons.add_circle_outline : Icons.remove_circle_outline,
                              size: 11,
                              color: AppColors.textPill,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              node.isCollapsed
                                  ? '+ ${node.childIds.length}'
                                  : '${node.childIds.length} sub',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPill,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  InkWell(
                    onTap: provider.isExtracting
                        ? null
                        : () => provider.expandNodeWithAi(node.id),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.pillTag,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 10, color: AppColors.textPill),
                          SizedBox(width: 4),
                          Text(
                            '+ AI Expand',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPill,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18, color: AppColors.textSecondary),
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
    );
  }
}
