import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/mindmap/models/lecture_session.dart';

// Top-level clean academic print styling constants
const _kPdfPrimaryColor = PdfColor.fromInt(0xFF1E293B); // Slate 800
const _kPdfAccentColor = PdfColor.fromInt(0xFF2563EB); // Royal Blue
const _kPdfEmeraldColor = PdfColor.fromInt(0xFF059669); // Emerald 600
const _kPdfAmberColor = PdfColor.fromInt(0xFFD97706); // Amber 600
const _kPdfTextDark = PdfColor.fromInt(0xFF0F172A); // Slate 900
const _kPdfTextMuted = PdfColor.fromInt(0xFF64748B); // Slate 500
const _kPdfBgLight = PdfColor.fromInt(0xFFF8FAFC); // Slate 50
const _kPdfBorderSubtle = PdfColor.fromInt(0xFFE2E8F0); // Slate 200

class _PdfBuildParams {
  final Map<String, dynamic> sessionJson;
  final Uint8List fontBytes;
  final Uint8List? chartImageBytes;
  final String? customSummary;

  _PdfBuildParams({
    required this.sessionJson,
    required this.fontBytes,
    this.chartImageBytes,
    this.customSummary,
  });
}

class PdfNotesService {
  static final PdfNotesService _instance = PdfNotesService._internal();
  factory PdfNotesService() => _instance;
  PdfNotesService._internal();

  Uint8List? _cachedFontBytes;

  Future<Uint8List> _loadUnicodeFontBytes() async {
    if (_cachedFontBytes != null) return _cachedFontBytes!;
    final byteData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    _cachedFontBytes = byteData.buffer.asUint8List();
    return _cachedFontBytes!;
  }

  /// Generates production-ready PDF bytes on a background isolate
  Future<Uint8List> generateLectureNotesPdf({
    required LectureSession session,
    Uint8List? chartImageBytes,
    String? customSummary,
  }) async {
    final fontBytes = await _loadUnicodeFontBytes();

    final params = _PdfBuildParams(
      sessionJson: session.toJson(),
      fontBytes: fontBytes,
      chartImageBytes: chartImageBytes,
      customSummary: customSummary,
    );

    // Run PDF document generation on a background isolate so UI never stutters
    return await compute(_generatePdfDocumentIsolate, params);
  }

  /// Saves the generated PDF to local scoped app storage and returns the file path
  Future<String> savePdfToLocalFile({
    required LectureSession session,
    Uint8List? chartImageBytes,
    String? customSummary,
  }) async {
    final bytes = await generateLectureNotesPdf(
      session: session,
      chartImageBytes: chartImageBytes,
      customSummary: customSummary,
    );

    final sanitizedTitle = session.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_');
    final filename =
        'Thinkly_Notes_${sanitizedTitle}_${session.id.substring(0, 8)}.pdf';

    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: filename);
      return filename;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/$filename');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      await Printing.sharePdf(bytes: bytes, filename: filename);
      return filename;
    }
  }

  /// One-click share or direct download using SharePlus with Printing fallback
  Future<void> sharePdf(
    LectureSession session, [
    String? customSummary,
    Uint8List? chartImageBytes,
  ]) async {
    final bytes = await generateLectureNotesPdf(
      session: session,
      chartImageBytes: chartImageBytes,
      customSummary: customSummary,
    );

    final sanitizedTitle = session.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_');
    final filename = 'Thinkly_Notes_$sanitizedTitle.pdf';

    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: filename);
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          text: 'Lecture Notes: ${session.title}',
        ),
      );
    } catch (e) {
      debugPrint('[PdfNotesService] Native share exception: $e. Falling back to Printing.sharePdf');
      await Printing.sharePdf(bytes: bytes, filename: filename);
    }
  }

  /// Interactive Print or System PDF Viewer
  Future<void> printOrExportPdf(
    LectureSession session, [
    String? customSummary,
    Uint8List? chartImageBytes,
  ]) async {
    final bytes = await generateLectureNotesPdf(
      session: session,
      chartImageBytes: chartImageBytes,
      customSummary: customSummary,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: '${session.title.replaceAll(' ', '_')}_Notes',
    );
  }
}

/// Top-level isolate function for compiling the full PDF document
Future<Uint8List> _generatePdfDocumentIsolate(_PdfBuildParams params) async {
  final session = LectureSession.fromJson(params.sessionJson);
  final analysis = session.analysis;
  final font = pw.Font.ttf(ByteData.view(params.fontBytes.buffer));

  final pdf = pw.Document(
    title: '${session.title} - Thinkly Study Notes',
    author: 'Thinkly AI Academic Assistant',
    creator: 'Thinkly App',
    subject: 'Class Notes, Graphs & Study Blueprint',
    theme: pw.ThemeData.withFont(
      base: font,
      bold: font,
      italic: font,
      boldItalic: font,
    ),
  );

  // Clean academic print styling
  const primaryColor = _kPdfPrimaryColor;
  const accentColor = _kPdfAccentColor;
  const emeraldColor = _kPdfEmeraldColor;
  const amberColor = _kPdfAmberColor;
  const textDark = _kPdfTextDark;
  const textMuted = _kPdfTextMuted;
  const bgLight = _kPdfBgLight;
  const borderSubtle = _kPdfBorderSubtle;

  final dateFormat = DateFormat('MMMM dd, yyyy - hh:mm a');
  final formattedDate = dateFormat.format(session.createdAt);

  final keyTakeaways = session.nodes.where((n) => n.isKeyTakeaway).toList();
  final studentNotes = session.nodes
      .where((n) => n.studentNote != null && n.studentNote!.isNotEmpty)
      .toList();

  pw.MemoryImage? chartImage;
  if (params.chartImageBytes != null && params.chartImageBytes!.isNotEmpty) {
    try {
      chartImage = pw.MemoryImage(params.chartImageBytes!);
    } catch (_) {}
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      header: (pw.Context context) {
        if (context.pageNumber == 1) {
          // First page branding banner
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 18),
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: borderSubtle, width: 1.5)),
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
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          // Running header on subsequent pages
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: borderSubtle, width: 0.75)),
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
          margin: const pw.EdgeInsets.only(top: 16),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                top: pw.BorderSide(color: borderSubtle, width: 0.75)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated automatically by Thinkly AI • Production Academic Notes',
                style: const pw.TextStyle(color: textMuted, fontSize: 8),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(
                  color: textDark,
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
          // 1. Lecture Title & Meta Box
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
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
                    letterSpacing: -0.5,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Text('Recorded: ',
                        style: const pw.TextStyle(
                            color: textMuted, fontSize: 9)),
                    pw.Text(formattedDate,
                        style: pw.TextStyle(
                            color: textDark,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 14),
                    pw.Text('Concepts: ',
                        style: const pw.TextStyle(
                            color: textMuted, fontSize: 9)),
                    pw.Text('${session.nodes.length} nodes',
                        style: pw.TextStyle(
                            color: textDark,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold)),
                    if (keyTakeaways.isNotEmpty) ...[
                      pw.SizedBox(width: 14),
                      pw.Text('Exam Priority: ',
                          style: const pw.TextStyle(
                              color: textMuted, fontSize: 9)),
                      pw.Text('${keyTakeaways.length} key points',
                          style: pw.TextStyle(
                              color: amberColor,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // 2. Executive Summary Callout
          pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 14,
                color: accentColor,
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'EXECUTIVE SUMMARY',
                style: pw.TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            params.customSummary ??
                analysis?.summary ??
                (session.nodes.isNotEmpty &&
                        session.nodes.first.summary.isNotEmpty
                    ? session.nodes.first.summary
                    : 'Comprehensive architectural concepts extracted from live class audio.'),
            style: pw.TextStyle(
              color: textDark,
              fontSize: 9.5,
              lineSpacing: 2.2,
            ),
          ),
          pw.SizedBox(height: 18),

          // 3. Embedded Visual Analytics Graph (If Available)
          if (chartImage != null) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: borderSubtle),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'VISUAL ANALYTICS & TOPIC DISTRIBUTION',
                    style: pw.TextStyle(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Center(
                    child: pw.Image(
                      chartImage,
                      height: 180,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
          ],

          // 4. Structured Topic Weight Breakdown
          if (analysis != null && analysis.topics.isNotEmpty) ...[
            pw.Row(
              children: [
                pw.Container(width: 4, height: 14, color: emeraldColor),
                pw.SizedBox(width: 8),
                pw.Text(
                  'TOPIC COMPETENCIES & WEIGHTS',
                  style: pw.TextStyle(
                    color: emeraldColor,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: borderSubtle, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: bgLight),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Topic Name',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Importance',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Mentions',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ...analysis.topics.map((t) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(t.name,
                            style: const pw.TextStyle(fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('${t.importance}%',
                            style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: emeraldColor)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('${t.mentions}',
                            style: const pw.TextStyle(fontSize: 8.5)),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 18),
          ],

          // 5. Chronological Key Takeaways with Timestamps
          if (analysis != null && analysis.keyPoints.isNotEmpty) ...[
            pw.Row(
              children: [
                pw.Container(width: 4, height: 14, color: amberColor),
                pw.SizedBox(width: 8),
                pw.Text(
                  'CHRONOLOGICAL KEY TAKEAWAYS',
                  style: pw.TextStyle(
                    color: amberColor,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            ...analysis.keyPoints.map((kp) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: borderSubtle),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: bgLight,
                        borderRadius: pw.BorderRadius.circular(3),
                        border: pw.Border.all(color: borderSubtle),
                      ),
                      child: pw.Text(
                        kp.timestamp,
                        style: pw.TextStyle(
                          color: textMuted,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                        kp.text,
                        style: const pw.TextStyle(
                            color: textDark, fontSize: 8.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 18),
          ],

          // 6. Definitions & Essential Terminology
          if (analysis != null && analysis.definitions.isNotEmpty) ...[
            pw.Row(
              children: [
                pw.Container(width: 4, height: 14, color: accentColor),
                pw.SizedBox(width: 8),
                pw.Text(
                  'DEFINITIONS & CORE TERMINOLOGY',
                  style: pw.TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            ...analysis.definitions.map((def) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: bgLight,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: borderSubtle),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ',
                        style: pw.TextStyle(
                            color: accentColor,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10)),
                    pw.Expanded(
                      child: pw.Text(
                        def,
                        style: const pw.TextStyle(
                            color: textDark, fontSize: 8.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 18),
          ],

          // 7. Active Recall & Exam Practice Questions
          if (analysis != null && analysis.questions.isNotEmpty) ...[
            pw.Row(
              children: [
                pw.Container(
                    width: 4,
                    height: 14,
                    color: const PdfColor.fromInt(0xFF7C3AED)),
                pw.SizedBox(width: 8),
                pw.Text(
                  'ACTIVE RECALL PRACTICE QUESTIONS',
                  style: pw.TextStyle(
                    color: const PdfColor.fromInt(0xFF7C3AED),
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            ...analysis.questions.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final q = entry.value;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: borderSubtle),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Q$idx. ',
                        style: pw.TextStyle(
                            color: const PdfColor.fromInt(0xFF7C3AED),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9)),
                    pw.Expanded(
                      child: pw.Text(
                        q,
                        style: const pw.TextStyle(
                            color: textDark, fontSize: 8.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 18),
          ],

          // 8. Action Items & Study Directives
          if (analysis != null && analysis.actionItems.isNotEmpty) ...[
            pw.Row(
              children: [
                pw.Container(width: 4, height: 14, color: emeraldColor),
                pw.SizedBox(width: 8),
                pw.Text(
                  'ACTION ITEMS & LAB DIRECTIVES',
                  style: pw.TextStyle(
                    color: emeraldColor,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            ...analysis.actionItems.map((act) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: bgLight,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: borderSubtle),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 10,
                      height: 10,
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(2),
                        border: pw.Border.all(color: emeraldColor, width: 1),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                        act,
                        style: const pw.TextStyle(
                            color: textDark, fontSize: 8.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 18),
          ],

          // 9. Student Field Notes & Annotations (If Any)
          if (studentNotes.isNotEmpty) ...[
            pw.Row(
              children: [
                pw.Container(
                    width: 4,
                    height: 14,
                    color: const PdfColor.fromInt(0xFF0284C7)),
                pw.SizedBox(width: 8),
                pw.Text(
                  'STUDENT FIELD NOTES & ANNOTATIONS',
                  style: pw.TextStyle(
                    color: const PdfColor.fromInt(0xFF0284C7),
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            ...studentNotes.map((node) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: bgLight,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: borderSubtle),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Re: ${node.label}',
                      style: pw.TextStyle(
                        color: textMuted,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      node.studentNote!,
                      style: const pw.TextStyle(
                          color: textDark, fontSize: 8.5),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 18),
          ],

          // 10. Transcript Excerpt Section
          if (session.transcriptHistory.trim().isNotEmpty) ...[
            pw.Row(
              children: [
                pw.Container(width: 4, height: 14, color: textMuted),
                pw.SizedBox(width: 8),
                pw.Text(
                  'FULL LECTURE TRANSCRIPT EXCERPT',
                  style: pw.TextStyle(
                    color: _kPdfTextMuted,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            ..._buildTranscriptParagraphs(
              session.transcriptHistory.trim(),
              textDark,
            ),
          ],
        ];
      },
    ),
  );

  return pdf.save();
}

List<pw.Widget> _buildTranscriptParagraphs(
  String transcript,
  PdfColor textColor,
) {
  final lines = transcript.split('\n');
  final paragraphs = <pw.Widget>[];
  final buffer = StringBuffer();

  for (final rawLine in lines) {
    final trimmed = rawLine.trim();
    if (trimmed.isEmpty) {
      if (buffer.isNotEmpty) {
        paragraphs.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(
              buffer.toString().trim(),
              style: pw.TextStyle(
                color: textColor,
                fontSize: 8.5,
                lineSpacing: 1.8,
              ),
            ),
          ),
        );
        buffer.clear();
      }
    } else {
      if (buffer.length + trimmed.length > 450) {
        paragraphs.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(
              buffer.toString().trim(),
              style: pw.TextStyle(
                color: textColor,
                fontSize: 8.5,
                lineSpacing: 1.8,
              ),
            ),
          ),
        );
        buffer.clear();
      }
      buffer.writeln(trimmed);
    }
  }

  if (buffer.isNotEmpty) {
    paragraphs.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          buffer.toString().trim(),
          style: pw.TextStyle(
            color: textColor,
            fontSize: 8.5,
            lineSpacing: 1.8,
          ),
        ),
      ),
    );
  }

  return paragraphs;
}
