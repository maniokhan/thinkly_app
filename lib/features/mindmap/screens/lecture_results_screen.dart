import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../core/models/lecture_analysis.dart';
import '../../../core/services/pdf_notes_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../analytics/widgets/lecture_charts.dart';
import '../providers/mind_map_provider.dart';
import '../widgets/graph_canvas.dart';
import '../widgets/node_inspector_sheet.dart';

class LectureResultsScreen extends StatefulWidget {
  final VoidCallback? onBackToRecord;
  final int initialSegment;

  const LectureResultsScreen({
    super.key,
    this.onBackToRecord,
    this.initialSegment = 0,
  });

  @override
  State<LectureResultsScreen> createState() => _LectureResultsScreenState();
}

class _LectureResultsScreenState extends State<LectureResultsScreen> {
  late int _selectedSegment; // 0: Summary, 1: Graphs, 2: PDF, 3: Mind Map
  final PdfNotesService _pdfService = PdfNotesService();
  final GlobalKey _chartsExportKey = GlobalKey();
  bool _isGeneratingPdf = false;
  Uint8List? _cachedPdfBytes;

  @override
  void initState() {
    super.initState();
    _selectedSegment = widget.initialSegment;
  }

  @override
  void didUpdateWidget(covariant LectureResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSegment != oldWidget.initialSegment) {
      _selectedSegment = widget.initialSegment;
    }
  }

  Future<void> _makeOrSharePdf(MindMapProvider provider) async {
    setState(() => _isGeneratingPdf = true);
    try {
      Uint8List? chartBytes;
      if (_selectedSegment == 1) {
        chartBytes =
            await LectureVisualAnalyticsView.capturePng(_chartsExportKey);
      }
      await provider.sharePdfNotes(chartImageBytes: chartBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _openNodeInspector(BuildContext context) {
    final provider = context.read<MindMapProvider>();
    final node = provider.selectedNode;
    if (node == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.80,
        ),
        child: NodeInspectorSheet(
          node: node,
          isBottomSheet: true,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MindMapProvider>();
    final session = provider.currentSession;
    final analysis = session.analysis;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Class Results', style: AppTypography.titleMedium),
            Text(
              session.title,
              style: AppTypography.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // ONE PRIMARY ACTION: Make / Share PDF
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppButton(
              label: 'Make PDF',
              icon: Icons.picture_as_pdf_rounded,
              variant: AppButtonVariant.primary,
              isLoading: _isGeneratingPdf,
              onPressed: () => _makeOrSharePdf(provider),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSegmentTab('Summary', 0, Icons.notes_rounded),
                  const SizedBox(width: 8),
                  _buildSegmentTab('Graphs', 1, Icons.bar_chart_rounded),
                  const SizedBox(width: 8),
                  _buildSegmentTab('PDF Notes', 2, Icons.description_rounded),
                  const SizedBox(width: 8),
                  _buildSegmentTab('Concept Map', 3, Icons.hub_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildContent(provider, session, analysis),
    );
  }

  Widget _buildContent(MindMapProvider provider, dynamic session, LectureAnalysis? analysis) {
    // 1. Loading state with progress
    if (provider.isAnalyzing) {
      final pct = (provider.analysisProgress * 100).toInt();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLoader(message: 'Analyzing class notes... $pct%'),
              const SizedBox(height: 16),
              Text(
                provider.analysisStatusMessage.isNotEmpty
                    ? provider.analysisStatusMessage
                    : 'Running structured Gemini analysis pass...',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // 2. Error state
    if (provider.analysisError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.destructive, size: 48),
              const SizedBox(height: 12),
              const Text('Could not analyze lecture',
                  style: AppTypography.titleMedium),
              const SizedBox(height: 8),
              Text(
                provider.analysisError!,
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.primary,
                onPressed: () => provider.runFullAnalysis(),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Segmented Views
    switch (_selectedSegment) {
      case 0:
        return _buildSummarySegment(provider, analysis);
      case 1:
        return _buildGraphsSegment(provider, analysis);
      case 2:
        return _buildPdfSegment(provider, session);
      case 3:
        return _buildMindMapSegment();
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================================================
  // SEGMENT 0: SUMMARY & KEY POINTS
  // ==========================================================================
  Widget _buildSummarySegment(
      MindMapProvider provider, LectureAnalysis? analysis) {
    if (analysis == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppEmptyState(
            icon: Icons.notes_rounded,
            title: 'No analysis generated yet',
            description:
                'Record class audio or paste a YouTube link to generate your notes.',
            actionLabel: 'Analyze now',
            onAction: () => provider.runFullAnalysis(),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Executive Summary Card
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'EXECUTIVE SUMMARY',
                          style: AppTypography.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const AppBadge(text: 'AI SYNTHESIS', isAccent: true),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    analysis.summary,
                    style: AppTypography.bodyLarge.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Key Points with Timestamps
          if (analysis.keyPoints.isNotEmpty) ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'KEY TAKEAWAYS',
                    style: AppTypography.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                AppBadge(text: '${analysis.keyPoints.length} POINTS'),
              ],
            ),
            const SizedBox(height: 10),
            ...analysis.keyPoints.map((kp) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.raisedSurface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.hairlineBorder),
                          ),
                          child: Text(
                            kp.timestamp,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            kp.text,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 18),
          ],

          // Definitions
          if (analysis.definitions.isNotEmpty) ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'DEFINITIONS & TERMINOLOGY',
                    style: AppTypography.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                AppBadge(text: '${analysis.definitions.length} TERMS'),
              ],
            ),
            const SizedBox(height: 10),
            ...analysis.definitions.map((def) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.bookmark_outline_rounded,
                            size: 16, color: AppColors.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            def,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 18),
          ],

          // Practice Questions
          if (analysis.questions.isNotEmpty) ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'ACTIVE RECALL QUESTIONS',
                    style: AppTypography.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                AppBadge(text: '${analysis.questions.length} QUESTIONS'),
              ],
            ),
            const SizedBox(height: 10),
            ...analysis.questions.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final q = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q$idx.',
                          style: AppTypography.labelSmall.copyWith(
                            color: const Color(0xFF818CF8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            q,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 18),
          ],

          // Action Items
          if (analysis.actionItems.isNotEmpty) ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'ACTION ITEMS & NEXT STEPS',
                    style: AppTypography.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                AppBadge(text: '${analysis.actionItems.length} ITEMS'),
              ],
            ),
            const SizedBox(height: 10),
            ...analysis.actionItems.map((act) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.statusLive,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            act,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ==========================================================================
  // SEGMENT 1: INTERACTIVE GRAPHS
  // ==========================================================================
  Widget _buildGraphsSegment(
      MindMapProvider provider, LectureAnalysis? analysis) {
    if (analysis == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppEmptyState(
            icon: Icons.bar_chart_rounded,
            title: 'No graphs available yet',
            description:
                'Generate analysis first to plot topic weights and timeline flow.',
            actionLabel: 'Generate graphs',
            onAction: () => provider.runFullAnalysis(),
          ),
        ),
      );
    }

    return LectureVisualAnalyticsView(analysis: analysis);
  }

  // ==========================================================================
  // SEGMENT 2: PDF DOCUMENT VIEWER
  // ==========================================================================
  Widget _buildPdfSegment(MindMapProvider provider, dynamic session) {
    return PdfPreview(
      build: (format) async {
        _cachedPdfBytes = await _pdfService.generateLectureNotesPdf(
          session: session,
        );
        return _cachedPdfBytes!;
      },
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      allowPrinting: true,
      allowSharing: true,
      pdfFileName: '${session.title.replaceAll(' ', '_')}_Notes.pdf',
      scrollViewDecoration: const BoxDecoration(
        color: AppColors.background,
      ),
      pdfPreviewPageDecoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.hairlineBorder),
      ),
      loadingWidget: const AppLoader(message: 'Generating study PDF...'),
    );
  }

  // ==========================================================================
  // SEGMENT 3: INTERACTIVE MIND MAP CANVAS
  // ==========================================================================
  Widget _buildMindMapSegment() {
    return GraphCanvas(
      onNodeSelected: () => _openNodeInspector(context),
    );
  }

  Widget _buildSegmentTab(String label, int index, IconData icon) {
    final isSelected = _selectedSegment == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSegment = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.raisedSurface,
          borderRadius: BorderRadius.circular(AppRadius.s),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.hairlineBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.background : AppColors.secondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.background : AppColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
