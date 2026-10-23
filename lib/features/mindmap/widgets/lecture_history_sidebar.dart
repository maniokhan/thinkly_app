import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/mind_map_provider.dart';
import 'pdf_preview_dialog.dart';

class LectureHistorySidebar extends StatelessWidget {
  final VoidCallback onClose;
  final bool isBottomSheet;

  const LectureHistorySidebar({
    super.key,
    required this.onClose,
    this.isBottomSheet = false,
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
      width: isBottomSheet ? double.infinity : 290,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: isBottomSheet
            ? const BorderRadius.vertical(top: Radius.circular(AppRadius.l))
            : AppRadius.radiusL,
        border: Border.all(color: AppColors.hairlineBorder, width: 1.0),
      ),
      child: Column(
        mainAxisSize: isBottomSheet ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBottomSheet)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                decoration: BoxDecoration(
                  color: AppColors.borderRoot,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.history_edu_rounded, size: 18, color: AppColors.textPrimary),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Lecture History',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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
          Flexible(
            child: savedLectures.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
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
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: isBottomSheet,
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
                          if (isBottomSheet) onClose();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.pillTag : AppColors.card,
                            borderRadius: BorderRadius.circular(10),
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
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateStr,
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${session.nodes.length} nodes',
                                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                      ),
                                      if (notesCount > 0) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '• $notesCount notes',
                                          style: const TextStyle(fontSize: 10, color: AppColors.nodeStudentNote),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => PdfPreviewDialog(session: session),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF261919),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFF482525)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.picture_as_pdf_rounded, size: 11, color: AppColors.rose),
                                          SizedBox(width: 3),
                                          Text('PDF', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.rose)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => provider.deleteSavedLecture(session.id),
                                    borderRadius: BorderRadius.circular(4),
                                    child: const Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.textMuted),
                                    ),
                                  ),
                                ],
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
