import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../core/services/pdf_notes_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../providers/mind_map_provider.dart';

class PdfNotesScreen extends StatefulWidget {
  const PdfNotesScreen({super.key});

  @override
  State<PdfNotesScreen> createState() => _PdfNotesScreenState();
}

class _PdfNotesScreenState extends State<PdfNotesScreen> {
  final PdfNotesService _pdfService = PdfNotesService();
  bool _isSharing = false;
  int _selectedView = 0; // 0 = PDF Document, 1 = AI Flashcards & Guide
  String? _cachedStudyGuide;
  bool _isLoadingGuide = false;

  Future<void> _loadStudyGuide(MindMapProvider provider) async {
    setState(() => _isLoadingGuide = true);
    try {
      final guide = await provider.generateStudyGuide();
      if (mounted) setState(() => _cachedStudyGuide = guide);
    } finally {
      if (mounted) setState(() => _isLoadingGuide = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MindMapProvider>();
    final session = provider.currentSession;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Academic PDF Notes',
              style: AppTypography.titleMedium,
            ),
            Text(
              session.title,
              style: AppTypography.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (_selectedView == 0) ...[
            IconButton(
              icon: _isSharing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accent),
                    )
                  : const Icon(Icons.share_rounded, size: 20, color: AppColors.primaryText),
              tooltip: 'Share / Save PDF',
              onPressed: _isSharing
                  ? null
                  : () async {
                      setState(() => _isSharing = true);
                      try {
                        await _pdfService.sharePdf(session);
                      } finally {
                        if (mounted) setState(() => _isSharing = false);
                      }
                    },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.primaryText),
              tooltip: 'Copy Flashcards Markdown',
              onPressed: _cachedStudyGuide == null
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: _cachedStudyGuide!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Study guide copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
            ),
          ],
          const SizedBox(width: AppSpacing.s),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.hairlineBorder, width: 1.0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedView = 0),
                    borderRadius: AppRadius.radiusS,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedView == 0 ? AppColors.raisedSurface : Colors.transparent,
                        borderRadius: AppRadius.radiusS,
                        border: Border.all(
                          color: _selectedView == 0 ? AppColors.accent : Colors.transparent,
                          width: 1.0,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 15,
                              color: _selectedView == 0 ? AppColors.accent : AppColors.secondaryText,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Academic Document',
                              style: TextStyle(
                                fontFamily: AppTypography.fontHeading,
                                fontSize: 12,
                                fontWeight: _selectedView == 0 ? FontWeight.w700 : FontWeight.w500,
                                color: _selectedView == 0 ? AppColors.primaryText : AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedView = 1);
                      if (_cachedStudyGuide == null && !provider.isExtracting) {
                        _loadStudyGuide(provider);
                      }
                    },
                    borderRadius: AppRadius.radiusS,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedView == 1 ? AppColors.raisedSurface : Colors.transparent,
                        borderRadius: AppRadius.radiusS,
                        border: Border.all(
                          color: _selectedView == 1 ? AppColors.accent : Colors.transparent,
                          width: 1.0,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_stories_rounded,
                              size: 15,
                              color: _selectedView == 1 ? AppColors.accent : AppColors.secondaryText,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Flashcards & Guide',
                              style: TextStyle(
                                fontFamily: AppTypography.fontHeading,
                                fontSize: 12,
                                fontWeight: _selectedView == 1 ? FontWeight.w700 : FontWeight.w500,
                                color: _selectedView == 1 ? AppColors.primaryText : AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _selectedView == 0
          ? PdfPreview(
              build: (format) => _pdfService.generateLectureNotesPdf(session: session),
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              pdfFileName: '${session.title.replaceAll(' ', '_')}_Thinkly_Notes.pdf',
              loadingWidget: const AppLoader(
                message: 'Synthesizing publication-grade PDF notes...',
              ),
            )
          : _isLoadingGuide
              ? const AppLoader(
                  message: 'Gemini synthesizing active recall flashcards...',
                )
              : _cachedStudyGuide == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.radiusM,
                                border: Border.all(color: AppColors.hairlineBorder),
                              ),
                              child: const Icon(Icons.auto_stories_rounded, size: 24, color: AppColors.secondaryText),
                            ),
                            const SizedBox(height: AppSpacing.m),
                            const Text(
                              'AI Study Guide & Active Recall',
                              style: AppTypography.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              'Synthesize real-time concept cards and question-answer pairs for spaced repetition.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.l),
                            AppButton.primary(
                              label: 'Generate Study Guide',
                              icon: Icons.auto_awesome,
                              onPressed: () => _loadStudyGuide(provider),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Markdown(
                      data: _cachedStudyGuide!,
                      selectable: true,
                      padding: const EdgeInsets.all(AppSpacing.l),
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
    );
  }
}
