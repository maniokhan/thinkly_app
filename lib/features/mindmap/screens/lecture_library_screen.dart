import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_empty_state.dart';
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
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.radiusL,
          side: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
        ),
        title: const Row(
          children: [
            Icon(Icons.add_to_photos_rounded, color: AppColors.primaryText, size: 20),
            SizedBox(width: AppSpacing.s),
            Text('Start New Lecture', style: AppTypography.titleMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the topic or subject for this lecture session:',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryText),
              decoration: const InputDecoration(
                hintText: 'e.g. Distributed Systems & Raft Consensus',
              ),
            ),
          ],
        ),
        actions: [
          AppButton.ghost(
            label: 'Cancel',
            height: 40,
            onPressed: () => Navigator.pop(ctx),
          ),
          const SizedBox(width: AppSpacing.s),
          AppButton.primary(
            label: 'Create & Open',
            height: 40,
            onPressed: () {
              final text = titleCtrl.text.trim();
              provider.startNewLecture(text.isEmpty ? 'New Lecture Knowledge Map' : text);
              Navigator.pop(ctx);
              widget.onSelectLecture();
            },
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
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Lecture Library',
          style: AppTypography.titleMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryText, size: 22),
            tooltip: 'New Lecture',
            onPressed: () => _showNewLectureDialog(context, provider),
          ),
          const SizedBox(width: AppSpacing.s),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.s, AppSpacing.m, AppSpacing.s),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _filterQuery = val.trim()),
              style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryText),
              decoration: InputDecoration(
                hintText: 'Search saved lectures...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.secondaryText),
                suffixIcon: _filterQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: AppColors.secondaryText),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filterQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 12),
              ),
            ),
          ),

          // Lecture List
          Expanded(
            child: filtered.isEmpty
                ? AppEmptyState(
                    icon: Icons.bookmark_outline_rounded,
                    title: _filterQuery.isEmpty ? 'No Saved Lectures Yet' : 'No Lectures Found',
                    description: _filterQuery.isEmpty
                        ? 'Your classes and generated mind maps will appear here with one-click PDF export.'
                        : 'No lecture topics match "$_filterQuery"',
                    actionLabel: 'Start New Lecture',
                    onAction: () => _showNewLectureDialog(context, provider),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isActive = item.id == currentId;
                      final notesCount = item.nodes.where((n) => n.studentNote?.isNotEmpty == true).length;
                      final takeawaysCount = item.nodes.where((n) => n.isKeyTakeaway).length;

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.s),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.radiusM,
                          border: Border.all(
                            color: isActive ? AppColors.accent : AppColors.hairlineBorder,
                            width: isActive ? 1.5 : 1.0,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            provider.loadLecture(item);
                            widget.onSelectLecture();
                          },
                          borderRadius: AppRadius.radiusM,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontHeading,
                                          fontSize: 14.5,
                                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                                          color: AppColors.primaryText,
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.s),
                                    if (isActive)
                                      const AppBadge(text: 'ACTIVE', isAccent: true),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(item.lastModified),
                                  style: AppTypography.labelSmall,
                                ),
                                const SizedBox(height: AppSpacing.m),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppColors.raisedSurface,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.hairlineBorder, width: 0.8),
                                              ),
                                              child: Text(
                                                '${item.nodes.length} CONCEPTS',
                                                style: AppTypography.labelSmall.copyWith(color: AppColors.primaryText),
                                              ),
                                            ),
                                            if (notesCount > 0) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.raisedSurface,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: AppColors.hairlineBorder, width: 0.8),
                                                ),
                                                child: Text(
                                                  '$notesCount NOTES',
                                                  style: AppTypography.labelSmall.copyWith(color: AppColors.accent),
                                                ),
                                              ),
                                            ],
                                            if (takeawaysCount > 0) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.raisedSurface,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: AppColors.hairlineBorder, width: 0.8),
                                                ),
                                                child: Text(
                                                  '$takeawaysCount EXAM KEY',
                                                  style: AppTypography.labelSmall.copyWith(color: AppColors.statusAmber),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    // Quick PDF export button
                                    IconButton(
                                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: AppColors.primaryText),
                                      tooltip: 'Export PDF Document',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => PdfPreviewDialog(session: item),
                                        );
                                      },
                                    ),
                                    // Delete lecture
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.secondaryText),
                                      tooltip: 'Delete Lecture',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: AppColors.surface,
                                            elevation: 0,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: AppRadius.radiusL,
                                              side: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
                                            ),
                                            title: const Text('Delete Lecture?', style: AppTypography.titleMedium),
                                            content: Text(
                                              'Are you sure you want to remove "${item.title}" from your library?',
                                              style: AppTypography.bodyMedium,
                                            ),
                                            actions: [
                                              AppButton.ghost(
                                                label: 'Cancel',
                                                height: 40,
                                                onPressed: () => Navigator.pop(ctx),
                                              ),
                                              const SizedBox(width: AppSpacing.s),
                                              AppButton.destructive(
                                                label: 'Delete',
                                                height: 40,
                                                onPressed: () {
                                                  provider.deleteSavedLecture(item.id);
                                                  Navigator.pop(ctx);
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate(delay: (index * 30).ms).fade(duration: 200.ms, curve: Curves.easeOut).slideY(begin: 0.05, end: 0, duration: 200.ms, curve: Curves.easeOut);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
