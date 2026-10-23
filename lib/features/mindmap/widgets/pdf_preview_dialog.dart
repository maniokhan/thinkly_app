import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_theme.dart';
import '../models/lecture_session.dart';
import '../../../core/services/pdf_notes_service.dart';
import '../../../core/widgets/app_loader.dart';

class PdfPreviewDialog extends StatefulWidget {
  final LectureSession session;
  final String? customSummary;

  const PdfPreviewDialog({
    super.key,
    required this.session,
    this.customSummary,
  });

  @override
  State<PdfPreviewDialog> createState() => _PdfPreviewDialogState();
}

class _PdfPreviewDialogState extends State<PdfPreviewDialog> {
  final PdfNotesService _pdfService = PdfNotesService();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
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
        horizontal: isMobile ? 10 : 24,
        vertical: isMobile ? 12 : 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 840),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18, vertical: 12),
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
                              child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accent, size: 16),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Thinkly AI Study Notes • PDF Document Preview',
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
                                widget.session.title,
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _isSharing
                                  ? null
                                  : () async {
                                      setState(() => _isSharing = true);
                                      try {
                                        await _pdfService.sharePdf(
                                          widget.session,
                                          widget.customSummary,
                                        );
                                      } finally {
                                        if (mounted) setState(() => _isSharing = false);
                                      }
                                    },
                              icon: const Icon(Icons.share_rounded, size: 13),
                              label: const Text('Share / Save', style: TextStyle(fontSize: 11)),
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
                            Icons.picture_as_pdf_rounded,
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
                                'Thinkly AI Study Notes • PDF Document Preview',
                                style: AppTypography.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.session.title,
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isSharing
                              ? null
                              : () async {
                                  setState(() => _isSharing = true);
                                  try {
                                    await _pdfService.sharePdf(
                                      widget.session,
                                      widget.customSummary,
                                    );
                                  } finally {
                                    if (mounted) setState(() => _isSharing = false);
                                  }
                                },
                          icon: _isSharing
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primaryText),
                                )
                              : const Icon(Icons.share_rounded, size: 14),
                          label: Text(_isSharing ? 'Sharing...' : 'Share / Save'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: AppColors.secondaryText),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
            ),

            // Interactive PDF View Area
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.l)),
                child: PdfPreview(
                  build: (format) => _pdfService.generateLectureNotesPdf(
                    session: widget.session,
                    customSummary: widget.customSummary,
                  ),
                  allowPrinting: true,
                  allowSharing: true,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  pdfFileName: '${widget.session.title.replaceAll(' ', '_')}_Notes.pdf',
                  loadingWidget: const AppLoader(
                    message: 'Synthesizing publication-grade notes...',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
