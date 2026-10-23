import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mind_map_provider.dart';
import '../widgets/graph_canvas.dart';
import '../widgets/floating_dock.dart';
import '../widgets/node_inspector_sheet.dart';
import '../widgets/live_status_audio_bar.dart';
import '../widgets/lecture_history_sidebar.dart';

class MindMapScreen extends StatefulWidget {
  const MindMapScreen({super.key});

  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> {
  bool _showInspector = false;
  bool _showHistory = false;

  void _openMobileNodeInspector(BuildContext context) {
    final provider = context.read<MindMapProvider>();
    final node = provider.selectedNode;
    if (node == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.80,
        ),
        child: NodeInspectorSheet(
          node: node,
          isBottomSheet: true,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  void _openMobileHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.80,
        ),
        child: LectureHistorySidebar(
          isBottomSheet: true,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MindMapProvider>();
    final selectedNode = provider.selectedNode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 700;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. 100% Screen Interactive Canvas
          Positioned.fill(
            child: GraphCanvas(
              onNodeSelected: () {
                if (isCompact) {
                  _openMobileNodeInspector(context);
                } else {
                  setState(() {
                    _showInspector = true;
                    _showHistory = false;
                  });
                }
              },
            ),
          ),

          // 2. Top Live Audio & Status Bar
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Center(
              child: LiveStatusAudioBar(
                onToggleHistory: () {
                  if (isCompact) {
                    _openMobileHistory(context);
                  } else {
                    setState(() {
                      _showHistory = !_showHistory;
                      if (_showHistory) _showInspector = false;
                    });
                  }
                },
                isHistoryOpen: !isCompact && _showHistory,
              ),
            ),
          ),

          // 3. Floating Bottom Control Dock
          const Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: FloatingDock(),
            ),
          ),

          // 4. Slide-Over Node Inspector (Tablet & Desktop Only)
          if (!isCompact && _showInspector && selectedNode != null)
            Positioned(
              top: 56,
              right: 14,
              bottom: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: NodeInspectorSheet(
                  node: selectedNode,
                  onClose: () {
                    setState(() => _showInspector = false);
                  },
                ),
              ),
            ),

          // 5. Collapsible Right-Side History Sidebar (Tablet & Desktop Only)
          if (!isCompact && _showHistory)
            Positioned(
              top: 56,
              right: 14,
              bottom: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LectureHistorySidebar(
                  onClose: () {
                    setState(() => _showHistory = false);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
