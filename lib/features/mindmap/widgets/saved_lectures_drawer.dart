import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/mind_map_provider.dart';
import 'pdf_preview_dialog.dart';

class SavedLecturesDrawer extends StatelessWidget {
  const SavedLecturesDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MindMapProvider>();
    final saved = provider.savedLectures;

    return Material(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.library_books_rounded, color: AppColors.textPrimary, size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Saved Lectures',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          Expanded(
            child: saved.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_border_rounded, size: 40, color: AppColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'No Saved Lectures Yet',
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Saved lectures will automatically appear here with one-click PDF export.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: saved.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final item = saved[index];
                      final isCurrent = item.id == provider.currentSession.id;

                      return ListTile(
                        selected: isCurrent,
                        selectedTileColor: AppColors.pillTag,
                        leading: CircleAvatar(
                          backgroundColor: isCurrent ? AppColors.alabaster : AppColors.card,
                          radius: 16,
                          child: Icon(
                            Icons.hub_rounded,
                            size: 16,
                            color: isCurrent ? AppColors.alabasterText : AppColors.textSecondary,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${item.nodes.length} nodes • ${_formatDate(item.lastModified)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 17, color: AppColors.rose),
                              tooltip: 'Export Notes PDF',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => PdfPreviewDialog(session: item),
                                );
                              },
                              splashRadius: 16,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                              tooltip: 'Delete Lecture',
                              onPressed: () => provider.deleteSavedLecture(item.id),
                              splashRadius: 16,
                            ),
                          ],
                        ),
                        onTap: () {
                          provider.loadLecture(item);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
