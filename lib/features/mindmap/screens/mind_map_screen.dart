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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MindMapProvider>();
    final selectedNode = provider.selectedNode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. 100% Screen Interactive Canvas
          Positioned.fill(
            child: GraphCanvas(
              onNodeSelected: () {
                setState(() {
                  _showInspector = true;
                  _showHistory = false;
                });
              },
            ),
          ),

          // 2. Top Live Audio & Status Bar
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Center(
              child: LiveStatusAudioBar(
                onToggleHistory: () {
                  setState(() {
                    _showHistory = !_showHistory;
                    if (_showHistory) _showInspector = false;
                  });
                },
                isHistoryOpen: _showHistory,
              ),
            ),
          ),

          // 3. Floating Bottom Control Dock
          const Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: FloatingDock(),
            ),
          ),

          // 4. Slide-Over Node Inspector (Opened when a node is tapped)
          if (_showInspector && selectedNode != null)
            Positioned(
              top: 68,
              right: 14,
              bottom: 24,
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

          // 5. Collapsible Right-Side History Sidebar
          if (_showHistory)
            Positioned(
              top: 68,
              right: 14,
              bottom: 24,
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
