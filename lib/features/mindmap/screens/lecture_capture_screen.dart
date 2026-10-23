import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/speech_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loader.dart';
import '../providers/mind_map_provider.dart';
import '../../debate/screens/home_screen.dart';
import '../../../core/theme/wonderous_animations.dart';
import '../../../widgets/api_key_settings_dialog.dart';
import '../../../widgets/developer_debug_dialog.dart';

class LectureCaptureScreen extends StatefulWidget {
  final void Function([int segment]) onNavigateToResults;

  const LectureCaptureScreen({
    super.key,
    required this.onNavigateToResults,
  });

  @override
  State<LectureCaptureScreen> createState() => _LectureCaptureScreenState();
}

class _LectureCaptureScreenState extends State<LectureCaptureScreen> {
  int _debugTapCount = 0;
  DateTime _lastTapTime = DateTime.now();

  void _handleTitleTap() {
    final now = DateTime.now();
    if (now.difference(_lastTapTime).inSeconds > 2) {
      _debugTapCount = 0;
    }
    _lastTapTime = now;
    _debugTapCount++;

    if (_debugTapCount >= 5) {
      _debugTapCount = 0;
      showDialog(
        context: context,
        builder: (_) => const DeveloperDebugDialog(),
      );
    }
  }

  void _showYouTubeDialog(BuildContext context) {
    final urlController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
            border: Border(
              top: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
              left: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
              right: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Analyze YouTube lecture',
                      style: AppTypography.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.secondaryText, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Paste any YouTube class link. Thinkly will extract captions and create your notes, graphs and PDF instantly.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                autofocus: true,
                style: AppTypography.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'https://www.youtube.com/watch?v=...',
                  prefixIcon: Icon(Icons.link_rounded, color: AppColors.secondaryText),
                ),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Analyze lecture',
                icon: Icons.auto_awesome_rounded,
                variant: AppButtonVariant.primary,
                onPressed: () {
                  final url = urlController.text.trim();
                  if (url.isNotEmpty) {
                    Navigator.pop(ctx);
                    context.read<MindMapProvider>().importAndAnalyzeYouTube(url);
                    widget.onNavigateToResults();
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, MindMapProvider provider) {
    final titleController =
        TextEditingController(text: provider.currentSession.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: const BorderSide(color: AppColors.hairlineBorder),
        ),
        title: const Text('Class Title', style: AppTypography.titleMedium),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: AppTypography.bodyLarge,
          decoration: const InputDecoration(
            hintText: 'e.g. Distributed Systems & Consensus',
          ),
        ),
        actions: [
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            label: 'Save',
            variant: AppButtonVariant.primary,
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                provider.renameSession(titleController.text.trim());
              }
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MindMapProvider>();
    final speech = context.watch<SpeechService>();
    final session = provider.currentSession;
    final isListening = speech.isListening;
    final isAnalyzing = provider.isAnalyzing;

    // Format MM:SS for recording timer
    final elapsedSec = speech.captureElapsedSeconds;
    final mins = (elapsedSec ~/ 60).toString().padLeft(2, '0');
    final secs = (elapsedSec % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: GestureDetector(
          onTap: _handleTitleTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.raisedSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.hairlineBorder),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'T',
                  style: TextStyle(
                    fontFamily: AppTypography.fontHeading,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Thinkly', style: AppTypography.titleLarge),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.secondaryText, size: 22),
            tooltip: 'Settings',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ApiKeySettingsDialog(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Current Class Topic Header Card
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CURRENT CLASS',
                                style: AppTypography.labelSmall),
                            const SizedBox(height: 4),
                            Text(
                              session.title,
                              style: AppTypography.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.secondaryText),
                        tooltip: 'Rename class',
                        onPressed: () => _showRenameDialog(context, provider),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Central Live Audio / Recording Status Visualizer
              Container(
                constraints: const BoxConstraints(minHeight: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.l),
                  border: Border.all(
                    color: isListening
                        ? AppColors.accent.withValues(alpha: 0.5)
                        : AppColors.hairlineBorder,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isAnalyzing) ...[
                      const AppLoader(message: 'Analyzing class content...'),
                      const SizedBox(height: 12),
                      Text(
                        provider.analysisStatusMessage.isNotEmpty
                            ? provider.analysisStatusMessage
                            : 'Merging key points & generating visual graphs...',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ] else if (isListening) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.destructive,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'RECORDING $mins:$secs',
                            style: AppTypography.label.copyWith(
                              color: AppColors.primaryText,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        speech.activeTickerText,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.secondaryText,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Background service running. You can switch to Google Meet, YouTube or any other app.',
                        style: TextStyle(
                          fontFamily: AppTypography.fontBody,
                          fontSize: 11,
                          color: AppColors.statusLive,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      const Icon(Icons.mic_none_rounded,
                          size: 44, color: AppColors.secondaryText),
                      const SizedBox(height: 10),
                      const Text('Ready to record',
                          style: AppTypography.titleMedium),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap start recording to capture classroom speech',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. ONE PRIMARY ACTION BUTTON (Large min 52px tap target)
              if (isAnalyzing) ...[
                AppButton(
                  label: 'View Results',
                  icon: Icons.check_circle_outline_rounded,
                  variant: AppButtonVariant.primary,
                  onPressed: widget.onNavigateToResults,
                ),
              ] else if (isListening) ...[
                AppButton(
                  label: 'Stop & analyze',
                  icon: Icons.stop_circle_rounded,
                  variant: AppButtonVariant.destructive,
                  onPressed: () async {
                    speech.stopListening();
                    await provider.runFullAnalysis();
                    widget.onNavigateToResults();
                  },
                ),
              ] else ...[
                AppButton(
                  label: 'Start recording',
                  icon: Icons.mic_rounded,
                  variant: AppButtonVariant.primary,
                  onPressed: () {
                    provider.startLiveLectureSession();
                    speech.startListening();
                  },
                ),
              ],
              const SizedBox(height: 16),

              // 4. Mode Selection Chips (Classroom Mic vs Meeting vs Demo)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildModeChip(
                    'Microphone',
                    SpeechMode.liveMicrophone,
                    speech.currentMode == SpeechMode.liveMicrophone,
                    () => speech.setMode(SpeechMode.liveMicrophone),
                  ),
                  _buildModeChip(
                    'YouTube / Meet',
                    SpeechMode.tabAudio,
                    speech.currentMode == SpeechMode.tabAudio,
                    () => speech.setMode(SpeechMode.tabAudio),
                  ),
                  _buildModeChip(
                    'Demo',
                    SpeechMode.simulation,
                    speech.currentMode == SpeechMode.simulation,
                    () => speech.setMode(SpeechMode.simulation),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. YouTube Link Shortcut
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.raisedSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.hairlineBorder),
                        ),
                        child: const Icon(Icons.ondemand_video_rounded,
                            size: 20, color: AppColors.accent),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('YouTube class shortcut',
                                style: AppTypography.titleSmall),
                            SizedBox(height: 2),
                            Text(
                              'Paste video link to generate notes without recording',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppButton(
                        label: 'Paste',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _showYouTubeDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 6. AI Debate Arena Entry Card
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.raisedSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.hairlineBorder),
                        ),
                        child: const Icon(Icons.record_voice_over_rounded,
                            size: 20, color: AppColors.accent),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI Debate Arena',
                                style: AppTypography.titleSmall),
                            SizedBox(height: 2),
                            Text(
                              'Voice-to-voice debate championship with animated AI mascot',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppButton(
                        label: 'Debate',
                        variant: AppButtonVariant.primary,
                        onPressed: () {
                          Navigator.of(context).push(
                            WonderousAnimations.pageRoute(const HomeScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 6. View Mind Map & Results Shortcuts
              if (provider.nodes.length > 1) ...[
                AppButton(
                  label: 'View concept mind map (${provider.nodes.length} nodes)',
                  icon: Icons.hub_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => widget.onNavigateToResults(3),
                ),
                const SizedBox(height: 10),
              ],
              if (session.analysis != null) ...[
                AppButton(
                  label: 'View class results & summary',
                  icon: Icons.arrow_forward_rounded,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => widget.onNavigateToResults(0),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip(
      String label, SpeechMode mode, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.raisedSurface,
          borderRadius: BorderRadius.circular(AppRadius.s),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.hairlineBorder,
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
