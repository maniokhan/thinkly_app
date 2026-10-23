import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/mindmap/models/lecture_session.dart';
import '../../features/mindmap/models/mind_map_node.dart';

class PdfNotesService {
  static final PdfNotesService _instance = PdfNotesService._internal();
  factory PdfNotesService() => _instance;
  PdfNotesService._internal();

  /// Generates production-ready PDF bytes for the given lecture session
  Future<Uint8List> generateLectureNotesPdf({
    required LectureSession session,
    String? customSummary,
  }) async {
    final pdf = pw.Document(
      title: '${session.title} - Thinkly Study Notes',
      author: 'Thinkly AI Academic Assistant',
      creator: 'Thinkly App',
      subject: 'Class Notes & Concept Blueprint',
    );

    // Styling constants
    const primaryColor = PdfColor.fromInt(0xFF1E293B); // Slate 800
    const accentColor = PdfColor.fromInt(0xFF2563EB);  // Royal Blue
    const emeraldColor = PdfColor.fromInt(0xFF059669); // Emerald 600
    const amberColor = PdfColor.fromInt(0xFFD97706);   // Amber 600
    const textDark = PdfColor.fromInt(0xFF0F172A);     // Slate 900
    const textMuted = PdfColor.fromInt(0xFF64748B);    // Slate 500
    const bgLight = PdfColor.fromInt(0xFFF8FAFC);      // Slate 50
    const borderSubtle = PdfColor.fromInt(0xFFE2E8F0); // Slate 200

    final dateFormat = DateFormat('MMMM dd, yyyy - hh:mm a');
    final formattedDate = dateFormat.format(session.createdAt);

    final keyTakeaways = session.nodes.where((n) => n.isKeyTakeaway).toList();
    final studentNotes = session.nodes.where((n) => n.studentNote != null && n.studentNote!.isNotEmpty).toList();

    // Use MultiPage for clean multi-page flow with header & footer on every page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            // First page gets full branding banner
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 18),
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: borderSubtle, width: 1.5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 28,
                        height: 28,
                        decoration: pw.BoxDecoration(
                          color: primaryColor,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'T',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'THINKLY',
                            style: pw.TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          pw.Text(
                            'AI Real-Time Class Notes & Concept Blueprint',
                            style: const pw.TextStyle(
                              color: textMuted,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: bgLight,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: borderSubtle),
                    ),
                    child: pw.Text(
                      'STUDY GUIDE & EXAM NOTES',
                      style: pw.TextStyle(
                        color: accentColor,
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Running header on page 2+
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              padding: const pw.EdgeInsets.only(bottom: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: borderSubtle, width: 0.75)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    session.title,
                    style: pw.TextStyle(
                      color: textMuted,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Thinkly Academic Companion',
                    style: const pw.TextStyle(
                      color: textMuted,
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ),
            );
          }
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 14),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: borderSubtle, width: 0.75)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated with Thinkly | Focus on your class, not on writing notes',
                  style: const pw.TextStyle(color: textMuted, fontSize: 8),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(
                    color: textMuted,
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Lecture Title & Metadata Card
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: bgLight,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderSubtle),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    session.title,
                    style: pw.TextStyle(
                      color: textDark,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    formattedDate,
                    style: const pw.TextStyle(color: textMuted, fontSize: 10),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    children: [
                      _buildMetricBadge('Concepts Extracted', '${session.nodes.length}', accentColor),
                      pw.SizedBox(width: 10),
                      _buildMetricBadge('Key Takeaways', '${keyTakeaways.length}', amberColor),
                      pw.SizedBox(width: 10),
                      _buildMetricBadge('Student Notes', '${studentNotes.length}', emeraldColor),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            // Executive Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderSubtle),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 4,
                        height: 14,
                        decoration: pw.BoxDecoration(
                          color: accentColor,
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        'EXECUTIVE SUMMARY & CORE THESIS',
                        style: pw.TextStyle(
                          color: textDark,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    customSummary ??
                        (session.nodes.isNotEmpty ? session.nodes.first.summary : '') +
                            (session.nodes.length > 1
                                ? ' This session systematically unpacked ${session.nodes.length} core concepts, synthesizing practical implementations, theoretical parameters, and exam priorities.'
                                : ' Comprehensive overview of active lecture concepts.'),
                    style: const pw.TextStyle(
                      color: textDark,
                      fontSize: 9.5,
                      lineSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Section: Structured Concept Notes
            pw.Row(
              children: [
                pw.Container(
                  width: 4,
                  height: 14,
                  decoration: pw.BoxDecoration(
                    color: emeraldColor,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text(
                  'STRUCTURED CONCEPT BREAKDOWN',
                  style: pw.TextStyle(
                    color: textDark,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 10),

            // Concept Cards
            ...session.nodes.map((node) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: bgLight,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(
                    color: node.isKeyTakeaway ? amberColor : borderSubtle,
                    width: node.isKeyTakeaway ? 1.2 : 1,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Row(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: _getCategoryPdfColor(node.category),
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.Text(
                                node.category.displayName.toUpperCase(),
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 7.5,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Text(
                              node.label,
                              style: pw.TextStyle(
                                color: textDark,
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (node.isKeyTakeaway)
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: const PdfColor.fromInt(0xFFFEF3C7),
                              borderRadius: pw.BorderRadius.circular(3),
                              border: pw.Border.all(color: amberColor, width: 0.5),
                            ),
                            child: pw.Text(
                              '[EXAM TAKEAWAY]',
                              style: pw.TextStyle(
                                color: amberColor,
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      node.summary,
                      style: const pw.TextStyle(
                        color: textDark,
                        fontSize: 9,
                        lineSpacing: 1.3,
                      ),
                    ),
                    if (node.keyPoints.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      ...node.keyPoints.map(
                        (pt) => pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('- ', style: pw.TextStyle(color: accentColor, fontWeight: pw.FontWeight.bold)),
                              pw.Expanded(
                                child: pw.Text(
                                  pt,
                                  style: const pw.TextStyle(color: textDark, fontSize: 8.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (node.studentNote != null && node.studentNote!.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFEFF6FF),
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFFBFDBFE)),
                        ),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Student Note: ',
                              style: pw.TextStyle(
                                color: accentColor,
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                node.studentNote!,
                                style: const pw.TextStyle(
                                  color: textDark,
                                  fontSize: 8,
                                  fontStyle: pw.FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 16),

            // Active Recall Flashcards Section
            pw.Row(
              children: [
                pw.Container(
                  width: 4,
                  height: 14,
                  decoration: pw.BoxDecoration(
                    color: amberColor,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text(
                  'ACTIVE RECALL FLASHCARDS & EXAM PREP',
                  style: pw.TextStyle(
                    color: textDark,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 10),

            ...session.nodes.take(5).map((node) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderSubtle),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Q: ',
                          style: pw.TextStyle(
                            color: accentColor,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9.5,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'How does "${node.label}" function, and why is it critical?',
                            style: pw.TextStyle(
                              color: textDark,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'A: ',
                          style: pw.TextStyle(
                            color: emeraldColor,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9.5,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            node.summary.isNotEmpty
                                ? node.summary
                                : 'Core architectural principle established during the lecture.',
                            style: const pw.TextStyle(color: textDark, fontSize: 8.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            // Transcript Excerpt section if available
            if (session.transcriptHistory.trim().isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Row(
                children: [
                  pw.Container(
                    width: 4,
                    height: 14,
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    'LECTURE TRANSCRIPT DIGEST',
                    style: pw.TextStyle(
                      color: textDark,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: bgLight,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderSubtle),
                ),
                child: pw.Text(
                  session.transcriptHistory.length > 800
                      ? '${session.transcriptHistory.substring(0, 800)}... [Condensed for Review]'
                      : session.transcriptHistory,
                  style: const pw.TextStyle(
                    color: textMuted,
                    fontSize: 8,
                    lineSpacing: 1.3,
                  ),
                ),
              ),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Direct one-click print or system PDF export sheet
  Future<void> printOrExportPdf(LectureSession session, [String? customSummary]) async {
    final bytes = await generateLectureNotesPdf(
      session: session,
      customSummary: customSummary,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: '${session.title.replaceAll(' ', '_')}_Thinkly_Notes.pdf',
    );
  }

  /// One-click share or direct download
  Future<void> sharePdf(LectureSession session, [String? customSummary]) async {
    final bytes = await generateLectureNotesPdf(
      session: session,
      customSummary: customSummary,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: '${session.title.replaceAll(' ', '_')}_Thinkly_Notes.pdf',
    );
  }

  pw.Widget _buildMetricBadge(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            label,
            style: const pw.TextStyle(
              color: PdfColor.fromInt(0xFF64748B),
              fontSize: 7.5,
            ),
          ),
        ],
      ),
    );
  }

  PdfColor _getCategoryPdfColor(NodeCategory cat) {
    switch (cat) {
      case NodeCategory.root:
        return const PdfColor.fromInt(0xFF1E293B); // Dark Slate
      case NodeCategory.coreConcept:
        return const PdfColor.fromInt(0xFF2563EB); // Blue
      case NodeCategory.definition:
        return const PdfColor.fromInt(0xFF0D9488); // Teal
      case NodeCategory.example:
        return const PdfColor.fromInt(0xFF7C3AED); // Purple
      case NodeCategory.question:
        return const PdfColor.fromInt(0xFFE11D48); // Rose
      case NodeCategory.studentNote:
        return const PdfColor.fromInt(0xFF0284C7); // Light Blue
    }
  }
}
