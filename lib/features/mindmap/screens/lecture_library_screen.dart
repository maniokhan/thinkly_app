import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/mind_map_provider.dart';
import '../widgets/pdf_preview_dialog.dart';

class LectureLibraryScreen extends StatefulWidget {
  final VoidCallback onSelectLecture;

  const LectureLibraryScreen({super.key, required this.onSelectLecture});

  @override
  State<LectureLibraryScreen> createState() => _LectureLibraryScreenState();
}

class _LectureLibraryScreenState extends State<LectureLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _showNewLectureDialog(BuildContext context, MindMapProvider provider) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. Distributed Systems & Raft Consensus',
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
              widget.onSelectLecture();
            },
            child: const Text('Create & Open'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MindMapProvider>();
    final currentId = provider.currentSession.id;
    final allSaved = provider.savedLectures;

    final filtered = _filterQuery.isEmpty
        ? allSaved
        : allSaved.where((l) => l.title.toLowerCase().contains(_filterQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Lecture Library',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.textPrimary),
            tooltip: 'New Lecture',
            onPressed: () => _showNewLectureDialog(context, provider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _filterQuery = val.trim()),
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search saved lectures...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                suffixIcon: _filterQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filterQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // Lecture List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_outline_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                            _filterQuery.isEmpty ? 'No Saved Lectures Yet' : 'No Lectures Found',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _filterQuery.isEmpty
                                ? 'Your classes and generated mind maps will appear here with one-click PDF export.'
                                : 'No lecture topics match "$_filterQuery"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showNewLectureDialog(context, provider),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Start New Lecture'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isActive = item.id == currentId;
                      final notesCount = item.nodes.where((n) => n.studentNote?.isNotEmpty == true).length;
                      final takeawaysCount = item.nodes.where((n) => n.isKeyTakeaway).length;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive ? AppColors.borderSelected : AppColors.border,
                            width: isActive ? 1.5 : 1.0,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            provider.loadLecture(item);
                            widget.onSelectLecture();
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.emerald.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
                                        ),
                                        child: const Text(
                                          'ACTIVE',
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.emerald),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatDate(item.lastModified),
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.pillTag,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${item.nodes.length} Concepts',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                      ),
                                    ),
                                    if (notesCount > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF14202A),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFF1E3548)),
                                        ),
                                        child: Text(
                                          '$notesCount Notes',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.nodeStudentNote),
                                        ),
                                      ),
                                    ],
                                    if (takeawaysCount > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF261D12),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFF4C381E)),
                                        ),
                                        child: Text(
                                          '$takeawaysCount Exam Keys',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.amber),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: AppColors.rose),
                                      tooltip: 'Export PDF',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => PdfPreviewDialog(session: item),
                                        );
                                      },
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
                                      tooltip: 'Delete Lecture',
                                      onPressed: () => provider.deleteSavedLecture(item.id),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
