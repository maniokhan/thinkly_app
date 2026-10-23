import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/mind_map_node.dart';
import '../providers/mind_map_provider.dart';

class NodeInspectorSheet extends StatefulWidget {
  final MindMapNode node;
  final VoidCallback onClose;

  const NodeInspectorSheet({
    super.key,
    required this.node,
    required this.onClose,
  });

  @override
  State<NodeInspectorSheet> createState() => _NodeInspectorSheetState();
}

class _NodeInspectorSheetState extends State<NodeInspectorSheet> {
  late TextEditingController _notesController;
  bool _isSavingNote = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.node.studentNote ?? '');
  }

  @override
  void didUpdateWidget(covariant NodeInspectorSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id) {
      _notesController.text = widget.node.studentNote ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveNote(MindMapProvider provider) {
    setState(() => _isSavingNote = true);
    provider.updateNodeStudentNote(widget.node.id, _notesController.text.trim());
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isSavingNote = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MindMapProvider>();
    final isRoot = widget.node.category == NodeCategory.root;

    return Container(
      width: 360,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border, width: 1.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16,
            offset: Offset(-3, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inspector Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.node.category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Concept Inspector',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                  onPressed: widget.onClose,
                  splashRadius: 18,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.pillTag,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.node.category.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.node.category.displayName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPill,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.node.isKeyTakeaway)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.pillTag,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 13, color: AppColors.amber),
                            SizedBox(width: 4),
                            Text(
                              'Key Exam Takeaway',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  widget.node.label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI SUMMARY & CONTEXT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.node.summary.isNotEmpty
                            ? widget.node.summary
                            : 'No summary available for this concept.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                if (widget.node.keyPoints.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.format_list_bulleted_rounded, size: 14, color: AppColors.textPill),
                            SizedBox(width: 6),
                            Text(
                              'CAPTURED POINTS & EMPHASIS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...widget.node.keyPoints.map(
                          (point) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Personal Student Notes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.edit_note_rounded, size: 18, color: AppColors.nodeStudentNote),
                        SizedBox(width: 6),
                        Text(
                          'Personal Student Notes',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (_isSavingNote)
                      const Text('Saved', style: TextStyle(fontSize: 11, color: AppColors.emerald))
                  ],
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Add reflections, notes, or teacher emphasis (auto-saves)...',
                  ),
                  onChanged: (val) => _saveNote(provider),
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: provider.isExtracting
                      ? null
                      : () => provider.expandNodeWithAi(widget.node.id),
                  icon: const Icon(Icons.auto_awesome, size: 15),
                  label: Text(
                    provider.isExtracting
                        ? 'Gemini Generating Sub-Nodes...'
                        : 'Expand with AI (+Sub-Nodes)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alabaster,
                    foregroundColor: AppColors.alabasterText,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),

                const SizedBox(height: 8),

                if (widget.node.childIds.isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: () => provider.toggleNodeCollapsed(widget.node.id),
                    icon: Icon(
                      widget.node.isCollapsed ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                      size: 15,
                    ),
                    label: Text(
                      widget.node.isCollapsed
                          ? 'Expand Children (+${widget.node.childIds.length} sub-nodes)'
                          : 'Collapse Children (-${widget.node.childIds.length} sub-nodes)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                OutlinedButton.icon(
                  onPressed: () => provider.toggleNodeImportance(widget.node.id),
                  icon: Icon(
                    widget.node.isKeyTakeaway ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.amber,
                    size: 16,
                  ),
                  label: Text(
                    widget.node.isKeyTakeaway ? 'Unflag Exam Priority' : 'Flag as High Exam Priority',
                    style: const TextStyle(color: AppColors.amber, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.amber.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),

                if (!isRoot) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => provider.deleteNode(widget.node.id),
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.rose),
                    label: const Text('Delete Node from Graph', style: TextStyle(color: AppColors.rose, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
