import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/wonderous_animations.dart';
import '../../mascot/widgets/mascot_view.dart';
import '../providers/debate_provider.dart';
import '../widgets/sound_wave_visualizer.dart';
import '../widgets/transcript_sheet.dart';
import 'debate_result_screen.dart';

class LiveDebateScreen extends StatefulWidget {
  const LiveDebateScreen({super.key});

  @override
  State<LiveDebateScreen> createState() => _LiveDebateScreenState();
}

class _LiveDebateScreenState extends State<LiveDebateScreen> {
  bool _showTranscript = false;
  bool _showDebugOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DebateProvider>().startDebate();
    });
  }

  Future<void> _handleEndDebate(DebateProvider provider) async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            'Conclude Debate?',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you ready to finish and receive your official adjudication score and round breakdown?',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Keep Debating',
                style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'End & Adjudicate',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (shouldEnd == true) {
      await provider.endDebate();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        WonderousAnimations.pageRoute(const DebateResultScreen()),
      );
    }
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DebateProvider>();
    final mascot = provider.mascotController;

    final isListening = provider.phase == DebatePhase.listening;
    final isSpeaking = provider.phase == DebatePhase.speaking;
    final isThinking = provider.phase == DebatePhase.thinking;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _handleEndDebate(provider);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // Top Bar: Round indicator, Monospace Timer, End Debate
                    Row(
                      children: [
                        // Round Indicator (Long press reveals secret debug HUD)
                        Expanded(
                          child: GestureDetector(
                          onLongPress: () {
                            setState(() {
                              _showDebugOverlay = !_showDebugOverlay;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isSpeaking ? AppColors.cyan : AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    provider.currentRound.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ),
                        const SizedBox(width: 8),

                        // Turn Countdown Timer (Monospace)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            _formatTimer(provider.roundRemainingSeconds),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: provider.roundRemainingSeconds <= 10
                                  ? AppColors.error
                                  : AppColors.accent,
                            ),
                          ),
                        ),

                        // End Debate Button
                        IconButton(
                          onPressed: () => _handleEndDebate(provider),
                          icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textSecondary),
                          tooltip: 'Conclude Debate',
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Topic Title Banner (Compact, Matte, 1px border)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        provider.activeTopicTitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    // Speaker check failure banner if audio dropped
                    if (provider.speakerTimeoutOccurred)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.volume_off_rounded, size: 16, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No audio received from opponent.',
                                style: GoogleFonts.ibmPlexSans(fontSize: 12, color: AppColors.error),
                              ),
                            ),
                            TextButton(
                              onPressed: provider.retrySpeakerCheck,
                              child: Text(
                                'Retry',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Spacer(flex: 1),

                    // Center Mascot
                    MascotView(
                      controller: mascot,
                      size: 260,
                    ),

                    const SizedBox(height: 12),

                    // Subtle Emotion Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        mascot.currentEmotion.label.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSpeaking
                                  ? AppColors.cyan
                                  : (isListening ? AppColors.accent : AppColors.warning),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            provider.statusText,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Audio Waveform
                    SoundWaveVisualizer(
                      level: provider.liveAudioLevel,
                      isActive: isListening || isSpeaking,
                      color: isSpeaking ? AppColors.cyan : AppColors.accent,
                      height: 38,
                    ),

                    const SizedBox(height: 16),

                    // Primary Debate Control: ONE large state-adaptive button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: isListening
                          ? ElevatedButton.icon(
                              onPressed: provider.passToAI,
                              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                              label: Text(
                                provider.isUserSpeaking ? 'Pass Turn to AI' : 'Pass to AI',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          : (isSpeaking
                              ? OutlinedButton.icon(
                                  onPressed: provider.interruptAI,
                                  icon: const Icon(Icons.front_hand_rounded, size: 16, color: AppColors.warning),
                                  label: Text(
                                    'Point of Order (Interrupt)',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.warning),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                )
                              : (isThinking
                                  ? Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Opponent formulating counter...',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink())),
                    ),

                    const SizedBox(height: 12),

                    // Secondary Action Controls: Mute, Transcript
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mute Mic Button
                        IconButton.outlined(
                          onPressed: provider.toggleMicMute,
                          icon: Icon(
                            provider.isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                            size: 20,
                            color: provider.isMicMuted ? AppColors.error : AppColors.textPrimary,
                          ),
                          style: IconButton.styleFrom(
                            side: BorderSide(
                              color: provider.isMicMuted ? AppColors.error : AppColors.border,
                            ),
                          ),
                          tooltip: provider.isMicMuted ? 'Unmute Mic' : 'Mute Mic',
                        ),
                        const SizedBox(width: 16),

                        // View Transcript Toggle
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _showTranscript = !_showTranscript),
                          icon: Badge(
                            label: Text(provider.transcript.length.toString()),
                            isLabelVisible: provider.transcript.isNotEmpty,
                            backgroundColor: AppColors.accent,
                            textColor: Colors.black,
                            child: const Icon(Icons.subtitles_outlined, size: 18),
                          ),
                          label: const Text('Transcript'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Secret Debug Overlay HUD (Toggled by long pressing round label)
              if (_showDebugOverlay)
                Positioned(
                  top: 60,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xEE121214),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DEBUG METRICS',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _showDebugOverlay = false),
                              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'WS Status: ${provider.geminiService.status.name.toUpperCase()}',
                          style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.textPrimary),
                        ),
                        Text(
                          'TTFA Latency: ${provider.lastTtfAudioMs != null ? "${provider.lastTtfAudioMs}ms" : "measuring..."}',
                          style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.accent),
                        ),
                        Text(
                          'Audio Queue: ${provider.audioService.queuedAudioMs}ms | Underruns: ${provider.audioService.bufferUnderruns}',
                          style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          'Mic RMS: ${provider.liveAudioLevel.toStringAsFixed(3)} (Floor: ${provider.ambientNoiseFloor.toStringAsFixed(3)})',
                          style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          'VAD: ${provider.isUserSpeaking ? "SPEAKING" : "IDLE"} | Mode: ${provider.debateMode.name}',
                          style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          'Model: ${AppConfig.selectedModel}',
                          style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),

              // Collapsible Transcript Sheet
              if (_showTranscript) ...[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _showTranscript = false),
                    child: Container(color: Colors.black54),
                  ),
                ),
                Positioned.fill(
                  top: MediaQuery.of(context).size.height * 0.35,
                  child: TranscriptSheet(
                    turns: provider.transcript,
                    onClose: () => setState(() => _showTranscript = false),
                  ).animateCardEntrance(index: 0),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
