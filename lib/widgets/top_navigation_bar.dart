import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/env/env_config.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_button.dart';
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
        elevation: 0,
        builder: (_) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
            border: Border(
              top: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
              left: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
              right: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
            ),
          ),
          child: const SavedLecturesDrawer(),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => const Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
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
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isMobile ? AppRadius.l : AppRadius.m),
        border: Border.all(color: AppColors.hairlineBorder, width: 1.0),
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
                    Icon(Icons.edit_note_rounded, color: AppColors.primaryText, size: 20),
                    SizedBox(width: AppSpacing.s),
                    Flexible(
                      child: Text(
                        'Lecture Session Title',
                        style: AppTypography.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.secondaryText),
                onPressed: () => Navigator.pop(context),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: titleController,
            autofocus: true,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryText),
            decoration: const InputDecoration(
              labelText: 'Lecture Topic',
              hintText: 'e.g. Distributed Consensus & Paxos',
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton.ghost(
                label: 'Cancel',
                height: 42,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: AppSpacing.s),
              AppButton.primary(
                label: 'Save Title',
                height: 42,
                onPressed: () {
                  final text = titleController.text.trim();
                  if (text.isNotEmpty) {
                    mindMap.renameSession(text);
                  }
                  Navigator.pop(context);
                },
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
        elevation: 0,
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
          elevation: 0,
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
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.hairlineBorder, width: 1.0)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: screenWidth - 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Brand Logo & Tag
                  InkWell(
                    onTap: () => _showRenameLectureModal(context, mindMap),
                    borderRadius: AppRadius.radiusS,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.white.withAlpha(10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.raisedSurface,
                            borderRadius: AppRadius.radiusS,
                            border: Border.all(color: AppColors.hairlineBorder, width: 1.0),
                          ),
                          child: const Center(
                            child: Text(
                              'T',
                              style: TextStyle(
                                fontFamily: AppTypography.fontHeading,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        const Text(
                          'Thinkly',
                          style: TextStyle(
                            fontFamily: AppTypography.fontHeading,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.raisedSurface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.hairlineBorder, width: 1.0),
                          ),
                          child: const Text(
                            'AI CLASS NOTES',
                            style: AppTypography.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Middle Active Topic Pill (Desktop & Tablets)
                  if (!isCompact) ...[
                    const SizedBox(width: AppSpacing.m),
                    InkWell(
                      onTap: () => _showRenameLectureModal(context, mindMap),
                      borderRadius: AppRadius.radiusS,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.radiusS,
                          border: Border.all(color: AppColors.hairlineBorder, width: 1.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.school_outlined, size: 13, color: AppColors.secondaryText),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                mindMap.currentSession.title,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_outlined, size: 11, color: AppColors.secondaryText),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                  ] else ...[
                    const SizedBox(width: AppSpacing.s),
                  ],

                  // 3. Right Action Controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // PDF Export Button
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => PdfPreviewDialog(
                              session: mindMap.currentSession,
                            ),
                          );
                        },
                        borderRadius: AppRadius.radiusS,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: AppRadius.radiusS,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, size: 14, color: AppColors.accentText),
                              SizedBox(width: 5),
                              Text(
                                'Export PDF',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontHeading,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: AppColors.accentText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: AppSpacing.s),

                      // Saved Lectures Button
                      InkWell(
                        onTap: () => _showSavedLecturesModal(context),
                        borderRadius: AppRadius.radiusS,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.radiusS,
                            border: Border.all(color: AppColors.hairlineBorder, width: 1.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bookmark_outline_rounded, size: 14, color: AppColors.secondaryText),
                              const SizedBox(width: 4),
                              const Text(
                                'Saved',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontHeading,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              if (savedCount > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.raisedSurface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.hairlineBorder, width: 0.8),
                                  ),
                                  child: Text(
                                    '$savedCount',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primaryText,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: AppSpacing.s),

                      // Settings Gear Button
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => const ApiKeySettingsDialog(),
                          );
                        },
                        borderRadius: AppRadius.radiusS,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.radiusS,
                            border: Border.all(color: AppColors.hairlineBorder, width: 1.0),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.settings_outlined, size: 16, color: AppColors.secondaryText),
                              if (env.isConfigured)
                                Positioned(
                                  right: -1,
                                  top: -1,
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: AppColors.statusLive,
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
