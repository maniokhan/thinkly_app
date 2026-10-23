import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/lecture_analysis.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_badge.dart';

class LectureVisualAnalyticsView extends StatefulWidget {
  final LectureAnalysis analysis;
  final VoidCallback? onRefresh;

  const LectureVisualAnalyticsView({
    super.key,
    required this.analysis,
    this.onRefresh,
  });

  /// Captures a RepaintBoundary as PNG bytes
  static Future<Uint8List?> capturePng(GlobalKey repaintKey) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[LectureVisualAnalyticsView] Error capturing PNG: $e');
      return null;
    }
  }

  @override
  State<LectureVisualAnalyticsView> createState() =>
      _LectureVisualAnalyticsViewState();
}

class _LectureVisualAnalyticsViewState
    extends State<LectureVisualAnalyticsView> {
  final GlobalKey _chartsBoundaryKey = GlobalKey();
  bool _isExportingImage = false;
  int _selectedTab = 0; // 0: All, 1: Importance, 2: Timeline, 3: Topic Share

  Future<void> _shareChartsImage() async {
    setState(() => _isExportingImage = true);
    try {
      final bytes =
          await LectureVisualAnalyticsView.capturePng(_chartsBoundaryKey);
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not capture graph snapshot.')),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final sanitizedTitle = widget.analysis.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      final file = File(
          '${tempDir.path}/thinkly_charts_${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: 'Class Visual Analytics: ${widget.analysis.title}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingImage = false);
    }
  }

  Future<void> _saveChartsImage() async {
    setState(() => _isExportingImage = true);
    try {
      final bytes =
          await LectureVisualAnalyticsView.capturePng(_chartsBoundaryKey);
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not capture graph snapshot.')),
          );
        }
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final sanitizedTitle = widget.analysis.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      final path =
          '${appDir.path}/thinkly_graph_${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Graph saved successfully: ${file.path.split('/').last}'),
            backgroundColor: AppColors.raisedSurface,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Tabs & Export Actions Bar
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Overview', 0),
                      const SizedBox(width: 8),
                      _buildFilterChip('Importance', 1),
                      const SizedBox(width: 8),
                      _buildFilterChip('Timeline', 2),
                      const SizedBox(width: 8),
                      _buildFilterChip('Share', 3),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppButton(
                label: 'Share',
                icon: Icons.share_rounded,
                variant: AppButtonVariant.ghost,
                isLoading: _isExportingImage,
                onPressed: _shareChartsImage,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // RepaintBoundary containing charts to export as PNG
          RepaintBoundary(
            key: _chartsBoundaryKey,
            child: Container(
              color: AppColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_selectedTab == 0 || _selectedTab == 1) ...[
                    TopicImportanceBarChart(topics: widget.analysis.topics),
                    const SizedBox(height: 16),
                  ],
                  if (_selectedTab == 0 || _selectedTab == 2) ...[
                    TimelineFlowLineChart(timeline: widget.analysis.timeline),
                    const SizedBox(height: 16),
                  ],
                  if (_selectedTab == 0 || _selectedTab == 3) ...[
                    TopicShareDonutChart(topics: widget.analysis.topics),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bottom quick actions
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Save graph image',
                  icon: Icons.download_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: _saveChartsImage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Share graph image',
                  icon: Icons.send_rounded,
                  variant: AppButtonVariant.primary,
                  onPressed: _shareChartsImage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.raisedSurface,
          borderRadius: BorderRadius.circular(AppRadius.s),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.hairlineBorder,
            width: 1,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.background : AppColors.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 1. TOPIC IMPORTANCE BAR CHART
// ============================================================================
class TopicImportanceBarChart extends StatelessWidget {
  final List<AnalysisTopic> topics;

  const TopicImportanceBarChart({super.key, required this.topics});

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return const AppCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Icon(Icons.bar_chart_rounded,
                  color: AppColors.secondaryText, size: 36),
              SizedBox(height: 8),
              Text('Topic Importance Chart', style: AppTypography.titleMedium),
              SizedBox(height: 4),
              Text(
                'No topic data available to plot yet.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Limit display to top 7 topics for clean mobile rendering
    final displayTopics = topics.take(7).toList();

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'TOPIC IMPORTANCE',
                    style: AppTypography.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                AppBadge(text: '${displayTopics.length} TOPICS'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Relative conceptual weight assigned during lecture',
              style: AppTypography.bodySmall.copyWith(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  minY: 0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.raisedSurface,
                      tooltipBorder:
                          const BorderSide(color: AppColors.hairlineBorder),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final topic = displayTopics[group.x.toInt()];
                        return BarTooltipItem(
                          '${topic.name}\n',
                          AppTypography.labelSmall.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  'Weight: ${topic.importance}% • ${topic.mentions} mentions',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 25,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondaryText,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= displayTopics.length) {
                            return const SizedBox.shrink();
                          }
                          final name = displayTopics[idx].name;
                          final shortName = name.length > 7
                              ? '${name.substring(0, 6)}…'
                              : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              shortName,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.secondaryText,
                                fontSize: 9.5,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: AppColors.hairlineBorder,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: displayTopics.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final topic = entry.value;
                    final isTop = topic.importance >= 80;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: topic.importance.toDouble(),
                          color: isTop
                              ? AppColors.accent
                              : const Color(0xFF6366F1),
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100,
                            color: AppColors.raisedSurface,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. TIMELINE CONCEPTUAL FLOW & DEPTH LINE CHART
// ============================================================================
class TimelineFlowLineChart extends StatelessWidget {
  final List<AnalysisTimelinePoint> timeline;

  const TimelineFlowLineChart({super.key, required this.timeline});

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return const AppCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Icon(Icons.show_chart_rounded,
                  color: AppColors.secondaryText, size: 36),
              SizedBox(height: 8),
              Text('Timeline Flow Chart', style: AppTypography.titleMedium),
              SizedBox(height: 4),
              Text(
                'No timeline progression recorded for this lecture.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final spots = timeline.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'TIMELINE & CONCEPT DEPTH',
                    style: AppTypography.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                AppBadge(text: '${timeline.length} SEGMENTS'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Pacing and depth progression through class duration',
              style: AppTypography.bodySmall.copyWith(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  minX: 0,
                  maxX: (timeline.length - 1).toDouble().clamp(1.0, 999.0),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.raisedSurface,
                      tooltipBorder:
                          const BorderSide(color: AppColors.hairlineBorder),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          if (idx >= 0 && idx < timeline.length) {
                            final point = timeline[idx];
                            return LineTooltipItem(
                              '${point.time} • ${point.label}\n',
                              AppTypography.labelSmall.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      'Conceptual Depth: ${point.value.toInt()}%',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primaryText,
                                  ),
                                ),
                              ],
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 25,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondaryText,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < timeline.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                timeline[idx].time,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.secondaryText,
                                  fontSize: 9.5,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: AppColors.hairlineBorder,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: AppColors.accent,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3.5,
                            color: AppColors.background,
                            strokeWidth: 2,
                            strokeColor: AppColors.accent,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.25),
                            AppColors.accent.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. TOPIC SHARE DONUT CHART
// ============================================================================
class TopicShareDonutChart extends StatelessWidget {
  final List<AnalysisTopic> topics;

  const TopicShareDonutChart({super.key, required this.topics});

  static const List<Color> _palette = [
    Color(0xFFD4FF3A), // Electric Lime
    Color(0xFF10B981), // Mint Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFF818CF8), // Indigo
    Color(0xFFF59E0B), // Amber
    Color(0xFFF43F5E), // Coral
    Color(0xFFA855F7), // Violet
  ];

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return const AppCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Icon(Icons.pie_chart_rounded,
                  color: AppColors.secondaryText, size: 36),
              SizedBox(height: 8),
              Text('Topic Share Distribution', style: AppTypography.titleMedium),
              SizedBox(height: 4),
              Text(
                'No topic share data recorded.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final displayTopics = topics.take(6).toList();
    final totalMentions = displayTopics.fold<int>(
      0,
      (sum, t) => sum + (t.mentions > 0 ? t.mentions : 1),
    );

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'TOPIC COVERAGE SHARE',
                    style: AppTypography.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                AppBadge(text: '$totalMentions MENTIONS'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Distribution of time & attention per topic',
              style: AppTypography.bodySmall.copyWith(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Donut Chart
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 44,
                          sections: displayTopics.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final topic = entry.value;
                            final color = _palette[idx % _palette.length];
                            final val =
                                (topic.mentions > 0 ? topic.mentions : 1)
                                    .toDouble();
                            return PieChartSectionData(
                              value: val,
                              color: color,
                              radius: 16,
                              showTitle: false,
                            );
                          }).toList(),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${displayTopics.length}',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'TOPICS',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondaryText,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: displayTopics.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final topic = entry.value;
                      final color = _palette[idx % _palette.length];
                      final pct = totalMentions > 0
                          ? ((topic.mentions / totalMentions) * 100).round()
                          : 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.5),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                topic.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$pct%',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
