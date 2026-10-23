import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/env/env_config.dart';
import '../core/services/background_capture_service.dart';
import '../core/services/gemini_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_badge.dart';
import '../features/mindmap/providers/mind_map_provider.dart';

class DeveloperDebugDialog extends StatelessWidget {
  const DeveloperDebugDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MindMapProvider>();
    final env = context.watch<EnvConfig>();
    final session = provider.currentSession;
    final bgService = BackgroundCaptureService();

    final transcriptWords = session.transcriptHistory
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        side: const BorderSide(color: AppColors.hairlineBorder, width: 1.0),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bug_report_rounded,
                          color: AppColors.accent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'DIAGNOSTICS & SYSTEM STATE',
                        style: AppTypography.label,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.secondaryText, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.hairlineBorder, height: 20),

              // Scrollable metrics
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 1. Background Foreground Service
                    const Text('BACKGROUND CAPTURE SERVICE',
                        style: AppTypography.labelSmall),
                    const SizedBox(height: 8),
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _buildMetricRow(
                              'Service Status',
                              bgService.isServiceRunning
                                  ? 'RUNNING (Foreground)'
                                  : 'IDLE (Stopped)',
                              badgeColor: bgService.isServiceRunning
                                  ? AppColors.statusLive
                                  : AppColors.secondaryText,
                            ),
                            const SizedBox(height: 8),
                            _buildMetricRow(
                              'Platform Target',
                              kIsWeb
                                  ? 'Web (Interop Audio)'
                                  : Platform.operatingSystem.toUpperCase(),
                            ),
                            const SizedBox(height: 8),
                            _buildMetricRow(
                              'Autosave Interval',
                              'Every 20 seconds to SharedPreferences',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Transcript & Current Session Telemetry
                    const Text('ACTIVE LECTURE TELEMETRY',
                        style: AppTypography.labelSmall),
                    const SizedBox(height: 8),
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _buildMetricRow('Session ID', session.id),
                            const SizedBox(height: 8),
                            _buildMetricRow('Session Title', session.title),
                            const SizedBox(height: 8),
                            _buildMetricRow('Nodes / Concepts',
                                '${session.nodes.length} nodes'),
                            const SizedBox(height: 8),
                            _buildMetricRow('Transcript Length',
                                '${session.transcriptHistory.length} chars ($transcriptWords words)'),
                            const SizedBox(height: 8),
                            _buildMetricRow('Saved Lectures In Storage',
                                '${provider.savedLectures.length} saved sessions'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. AI Analysis Pipeline
                    const Text('GEMINI AI STRUCTURED ANALYSIS',
                        style: AppTypography.labelSmall),
                    const SizedBox(height: 8),
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _buildMetricRow(
                              'Analysis Cached',
                              session.analysis != null
                                  ? 'YES (Structured JSON)'
                                  : 'NO (Not yet analyzed)',
                              badgeColor: session.analysis != null
                                  ? AppColors.statusLive
                                  : AppColors.statusAmber,
                            ),
                            const SizedBox(height: 8),
                            _buildMetricRow(
                              'Gemini Fast Model',
                              GeminiAiService.fastModel,
                            ),
                            const SizedBox(height: 8),
                            _buildMetricRow(
                              'Gemini Pro Model',
                              GeminiAiService.proModel,
                            ),
                            const SizedBox(height: 8),
                            _buildMetricRow(
                              'API Key Configured',
                              env.isConfigured ? 'VALID KEY PRESENT' : 'MISSING',
                              badgeColor: env.isConfigured
                                  ? AppColors.statusLive
                                  : AppColors.destructive,
                            ),
                            if (session.analysis != null) ...[
                              const SizedBox(height: 8),
                              _buildMetricRow(
                                'Topics / Key Points',
                                '${session.analysis!.topics.length} topics • ${session.analysis!.keyPoints.length} key points',
                              ),
                              const SizedBox(height: 8),
                              _buildMetricRow(
                                'Timeline Segments',
                                '${session.analysis!.timeline.length} time points',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    AppButton(
                      label: 'Force Run AI Analysis',
                      icon: Icons.auto_awesome_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: () {
                        Navigator.pop(context);
                        provider.runFullAnalysis();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {Color? badgeColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: badgeColor != null
              ? AppBadge(text: value)
              : Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ],
    );
  }
}
