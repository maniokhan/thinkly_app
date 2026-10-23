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
                color: AppColors.hairlineBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.m, 10, 12, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.hairlineBorder, width: 1.0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.library_books_rounded, color: AppColors.primaryText, size: 20),
                      SizedBox(width: AppSpacing.s),
                      Flexible(
                        child: Text(
                          'Saved Lectures',
                          style: AppTypography.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.secondaryText),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          Expanded(
            child: saved.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.l),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_border_rounded, size: 40, color: AppColors.secondaryText),
                          SizedBox(height: 12),
                          Text(
                            'No Saved Lectures Yet',
                            style: AppTypography.titleSmall,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Saved lectures will automatically appear here with one-click PDF export.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall,
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
                        selectedTileColor: AppColors.raisedSurface,
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCurrent ? AppColors.accent : AppColors.raisedSurface,
                            borderRadius: AppRadius.radiusS,
                            border: Border.all(color: AppColors.hairlineBorder),
                          ),
                          child: Icon(
                            Icons.hub_rounded,
                            size: 16,
                            color: isCurrent ? AppColors.accentText : AppColors.secondaryText,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontHeading,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${item.nodes.length} nodes • ${_formatDate(item.lastModified)}',
                          style: AppTypography.labelSmall,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 17, color: AppColors.accent),
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
                              icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.secondaryText),
                              tooltip: 'Delete',
                              onPressed: () {
                                provider.deleteSavedLecture(item.id);
                              },
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m = months[dt.month - 1];
    final d = dt.day;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$m $d • $hour:$min $ampm';
  }
}
