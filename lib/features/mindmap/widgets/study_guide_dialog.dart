import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/mind_map_provider.dart';
import 'pdf_preview_dialog.dart';

class StudyGuideDialog extends StatelessWidget {
  final String title;
  final String markdownContent;

  const StudyGuideDialog({
    super.key,
    required this.title,
    required this.markdownContent,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MindMapProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;

    return Dialog(
      backgroundColor: AppColors.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.radiusL,
        side: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 32,
        vertical: isMobile ? 12 : 28,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840, maxHeight: 760),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 20,
                vertical: isMobile ? 12 : 16,
              ),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.hairlineBorder, width: 1.0)),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.raisedSurface,
                                borderRadius: AppRadius.radiusS,
                                border: Border.all(color: AppColors.hairlineBorder),
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                color: AppColors.accent,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s),
                            const Expanded(
                              child: Text(
                                'AI Study Guide & Flashcards',
                                style: AppTypography.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: AppColors.secondaryText),
                              onPressed: () => Navigator.of(context).pop(),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: markdownContent));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Study guide markdown copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 13),
                              label: const Text('Copy Markdown', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.raisedSurface,
                            borderRadius: AppRadius.radiusS,
                            border: Border.all(color: AppColors.hairlineBorder),
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: AppColors.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI Study Guide & Flashcards',
                                style: AppTypography.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                title,
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: markdownContent));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Study guide markdown copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          label: const Text('Copy Markdown'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: AppColors.secondaryText),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
            ),

            // Markdown Reading Body
            Expanded(
              child: Markdown(
                data: markdownContent,
                selectable: true,
                padding: EdgeInsets.all(isMobile ? 14 : 22),
                styleSheet: MarkdownStyleSheet(
                  p: AppTypography.bodyMedium.copyWith(color: AppColors.secondaryText, height: 1.6),
                  h1: AppTypography.display.copyWith(fontSize: 20),
                  h2: AppTypography.titleLarge.copyWith(fontSize: 16),
                  h3: AppTypography.titleMedium.copyWith(fontSize: 14),
                  strong: const TextStyle(
                    fontFamily: AppTypography.fontHeading,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                  code: const TextStyle(
                    fontFamily: AppTypography.fontMono,
                    fontSize: 12,
                    color: AppColors.accent,
                    backgroundColor: AppColors.raisedSurface,
                  ),
                  blockquote: AppTypography.bodyMedium.copyWith(color: AppColors.secondaryText, fontStyle: FontStyle.italic),
                  blockquoteDecoration: BoxDecoration(
                    color: AppColors.surface,
                    border: const Border(left: BorderSide(color: AppColors.accent, width: 2)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 20,
                vertical: 12,
              ),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.hairlineBorder, width: 1.0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppButton.ghost(
                    label: 'Close',
                    height: 40,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  AppButton.primary(
                    label: 'Export as Academic PDF',
                    icon: Icons.picture_as_pdf_rounded,
                    height: 40,
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (_) => PdfPreviewDialog(
                          session: provider.currentSession,
                          customSummary: markdownContent,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
