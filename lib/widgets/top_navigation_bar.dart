import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/env/env_config.dart';
import '../core/theme/app_theme.dart';
import '../features/mindmap/providers/mind_map_provider.dart';
import '../features/mindmap/widgets/saved_lectures_drawer.dart';
import '../features/mindmap/widgets/pdf_preview_dialog.dart';
import 'api_key_settings_dialog.dart';

class TopNavigationBar extends StatelessWidget {
  const TopNavigationBar({super.key});

  void _showSavedLecturesModal(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const SavedLecturesDrawer(),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => const Dialog(
          backgroundColor: Colors.transparent,
          child: SizedBox(
            width: 440,
            height: 600,
            child: SavedLecturesDrawer(),
          ),
        ),
      );
    }
  }

  void _showRenameLectureModal(BuildContext context, MindMapProvider mindMap) {
    final titleController = TextEditingController(text: mindMap.currentSession.title);
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget content = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isMobile ? 20 : 16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: AppColors.textPrimary, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Lecture Session Title',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: titleController,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Lecture Topic',
              hintText: 'e.g. Distributed Consensus & Paxos',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final text = titleController.text.trim();
                  if (text.isNotEmpty) {
                    mindMap.renameSession(text);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save Title'),
              ),
            ],
          ),
        ],
      ),
    );

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 12,
            right: 12,
            top: 12,
          ),
          child: content,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: SizedBox(width: 440, child: content),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvConfig>();
    final mindMap = context.watch<MindMapProvider>();
    final savedCount = mindMap.savedLectures.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 700;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.0)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: screenWidth - 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Brand Logo & Tag
                  InkWell(
                    onTap: () => _showRenameLectureModal(context, mindMap),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.cardElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderRoot),
                          ),
                          child: const Center(
                            child: Text(
                              'T',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.alabaster,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Thinkly',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.pillTag,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'AI CLASS NOTES',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.textPill,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Middle Active Topic Pill (Desktop & Tablets)
                  if (!isCompact) ...[
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => _showRenameLectureModal(context, mindMap),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 340),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.school_outlined, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                mindMap.currentSession.title,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_outlined, size: 11, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ] else ...[
                    const SizedBox(width: 8),
                  ],

                  // 3. Right Action Controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // PDF Export
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => PdfPreviewDialog(
                              session: mindMap.currentSession,
                            ),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 13, color: AppColors.alabasterText),
                        label: const Text('Export PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.alabaster,
                          foregroundColor: AppColors.alabasterText,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          elevation: 0,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Saved Lectures Button
                      InkWell(
                        onTap: () => _showSavedLecturesModal(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bookmark_outline_rounded, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              const Text(
                                'Saved',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                              if (savedCount > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.pillTag,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$savedCount',
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textPill),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Settings Gear Button
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => const ApiKeySettingsDialog(),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.settings_outlined, size: 15, color: AppColors.textSecondary),
                              if (env.isConfigured)
                                Positioned(
                                  right: -1,
                                  top: -1,
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: AppColors.emerald,
                                      shape: BoxShape.circle,
                                    ),
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
        ),
      ),
    );
  }
}
