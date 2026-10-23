import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_theme.dart';
import '../models/lecture_session.dart';
import '../../../core/services/pdf_notes_service.dart';

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 24,
        vertical: isMobile ? 12 : 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 840),
        child: Column(
          children: [
            // Header (Adaptive for mobile screens)
            Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
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
                                color: const Color(0xFF2E1A1A),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: const Color(0xFF4C2222)),
                              ),
                              child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.rose, size: 16),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Thinkly AI Study Notes • PDF Document Preview',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
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
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
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
                            color: const Color(0xFF2E1A1A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF4C2222)),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: AppColors.rose,
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
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                widget.session.title,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
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
                          icon: const Icon(Icons.share_rounded, size: 14),
                          label: const Text('Share / Save', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                          onPressed: () => Navigator.of(context).pop(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
            ),

            // PDF Interactive Viewer
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
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
                  pdfFileName: '${widget.session.title.replaceAll(' ', '_')}_Thinkly_Notes.pdf',
                  loadingWidget: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.alabaster,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Synthesizing publication-grade PDF notes...',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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
    );
  }
}
