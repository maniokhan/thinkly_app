import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../core/services/pdf_notes_service.dart';
import '../../../core/theme/app_theme.dart';
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
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Academic PDF Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            Text(
              session.title,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                    )
                  : const Icon(Icons.share_rounded, size: 20),
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
              icon: const Icon(Icons.copy_rounded, size: 20),
              tooltip: 'Copy Flashcards Markdown',
              onPressed: _cachedStudyGuide == null
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: _cachedStudyGuide!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Study guide copied to clipboard!'),
                          backgroundColor: AppColors.cardElevated,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
            ),
          ],
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedView = 0),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedView == 0 ? AppColors.pillTag : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedView == 0 ? AppColors.borderSelected : Colors.transparent,
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
                              color: _selectedView == 0 ? AppColors.rose : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Academic Document',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedView == 0 ? FontWeight.w700 : FontWeight.w500,
                                color: _selectedView == 0 ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedView = 1);
                      if (_cachedStudyGuide == null && !provider.isExtracting) {
                        _loadStudyGuide(provider);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedView == 1 ? AppColors.pillTag : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedView == 1 ? AppColors.borderSelected : Colors.transparent,
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
                              color: _selectedView == 1 ? AppColors.cyan : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Flashcards & Guide',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedView == 1 ? FontWeight.w700 : FontWeight.w500,
                                color: _selectedView == 1 ? AppColors.textPrimary : AppColors.textSecondary,
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
              loadingWidget: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(strokeWidth: 2, color: AppColors.alabaster),
                    SizedBox(height: 12),
                    Text(
                      'Synthesizing publication-grade PDF notes...',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : _isLoadingGuide
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
                      SizedBox(height: 12),
                      Text(
                        'Gemini synthesizing active recall flashcards...',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : _cachedStudyGuide == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_stories_rounded, size: 40, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'AI Study Guide & Active Recall',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Synthesize real-time concept cards and question-answer pairs for spaced repetition.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _loadStudyGuide(provider),
                              icon: const Icon(Icons.auto_awesome, size: 16),
                              label: const Text('Generate Study Guide'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Markdown(
                      data: _cachedStudyGuide!,
                      selectable: true,
                      padding: const EdgeInsets.all(18),
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.textSecondary),
                        h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        h2: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        h3: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        strong: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        blockquote: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        blockquoteDecoration: BoxDecoration(
                          color: AppColors.card,
                          border: const Border(left: BorderSide(color: AppColors.borderSelected, width: 3)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
    );
  }
}
