import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/mind_map_provider.dart';
import 'pdf_preview_dialog.dart';

class LectureHistorySidebar extends StatelessWidget {
  final VoidCallback onClose;

  const LectureHistorySidebar({
    super.key,
    required this.onClose,
  });

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m = months[dt.month - 1];
    final d = dt.day;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$m $d, $hour:$min $ampm';
  }

  void _showNewLectureDialog(BuildContext context, MindMapProvider provider) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.add_to_photos_rounded, color: AppColors.textPrimary, size: 20),
            SizedBox(width: 8),
            Text('Start New Lecture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the topic or subject for this lecture session:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. Distributed Consensus (Raft & Paxos)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = titleCtrl.text.trim();
              provider.startNewLecture(text.isEmpty ? 'New Lecture Knowledge Map' : text);
              Navigator.pop(ctx);
            },
            child: const Text('Create Lecture'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MindMapProvider>();
    final currentId = provider.currentSession.id;
    final savedLectures = provider.savedLectures;

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_edu_rounded, size: 18, color: AppColors.textPrimary),
                    SizedBox(width: 8),
                    Text(
                      'Lecture History',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                  tooltip: 'Close History',
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                ),
              ],
            ),
          ),

          // + New Lecture Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showNewLectureDialog(context, provider),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text('New Lecture', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: AppColors.border),

          // List of Lectures
          Expanded(
            child: savedLectures.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_rounded, size: 32, color: AppColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          const Text(
                            'No Past Sessions',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Recorded classes will appear here for one-click review & PDF export.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    itemCount: savedLectures.length,
                    itemBuilder: (context, index) {
                      final session = savedLectures[index];
                      final isActive = session.id == currentId;
                      final dateStr = _formatDate(session.lastModified);
                      final notesCount = session.nodes.where((n) => n.studentNote?.isNotEmpty == true).length;

                      return InkWell(
                        onTap: () {
                          provider.loadLecture(session);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.pillTag : AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive ? AppColors.borderSelected : AppColors.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      session.title,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.emerald.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.emerald,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${session.nodes.length} nodes',
                                        style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
                                      ),
                                      if (notesCount > 0) ...[
                                        const SizedBox(width: 4),
                                        const Text('•', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.edit_note_rounded, size: 12, color: AppColors.nodeStudentNote),
                                        const SizedBox(width: 2),
                                        Text(
                                          '$notesCount',
                                          style: const TextStyle(fontSize: 9.5, color: AppColors.nodeStudentNote, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => PdfPreviewDialog(session: session),
                                          );
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(2),
                                          child: Icon(Icons.picture_as_pdf_rounded, size: 14, color: AppColors.rose),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (c) => AlertDialog(
                                              backgroundColor: AppColors.surface,
                                              title: const Text('Delete Lecture?', style: TextStyle(fontSize: 14)),
                                              content: Text('Delete "${session.title}" from saved history?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(c, true),
                                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            provider.deleteSavedLecture(session.id);
                                          }
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(2),
                                          child: Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.textMuted),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateStr,
                                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
