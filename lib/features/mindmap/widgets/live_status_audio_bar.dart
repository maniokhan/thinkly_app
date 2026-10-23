import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/speech_service.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/mind_map_provider.dart';

class LiveStatusAudioBar extends StatelessWidget {
  final VoidCallback onToggleHistory;
  final bool isHistoryOpen;

  const LiveStatusAudioBar({
    super.key,
    required this.onToggleHistory,
    required this.isHistoryOpen,
  });

  @override
  Widget build(BuildContext context) {
    final speech = context.watch<SpeechService>();
    final provider = context.watch<MindMapProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 700;

    return Container(
      constraints: const BoxConstraints(maxWidth: 960),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14, vertical: isCompact ? 6 : 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusM,
        border: Border.all(color: AppColors.hairlineBorder, width: 1.0),
      ),
      child: isCompact
          ? _buildCompactBar(context, speech, provider)
          : _buildFullBar(context, speech, provider),
    );
  }

  Widget _buildCompactBar(BuildContext context, SpeechService speech, MindMapProvider provider) {
    if (speech.isListening) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.emerald,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Live: ${speech.activeSharingSourceTitle}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _AudioEqualizer(volume: speech.audioVolume),
          const SizedBox(width: 6),
          Text(
            '${speech.captureElapsedSeconds}s',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => speech.stopListening(),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF261919),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF452222)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stop_circle_outlined, size: 11, color: AppColors.rose),
                  SizedBox(width: 3),
                  Text('Stop', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.rose)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (provider.isExtracting) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textPrimary),
          ),
          SizedBox(width: 8),
          Text(
            'AI Analyzing & updating mind map...',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      );
    }

    // Default compact inactive state
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.hub_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${provider.currentSession.title} • ${provider.nodes.length} nodes',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onToggleHistory,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isHistoryOpen ? AppColors.pillTag : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isHistoryOpen ? AppColors.emerald : AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded, size: 13, color: isHistoryOpen ? AppColors.emerald : AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(
                  'History',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isHistoryOpen ? AppColors.emerald : AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullBar(BuildContext context, SpeechService speech, MindMapProvider provider) {
    return Row(
      children: [
        // 1. Sharing Status Badge + Live Audio Meter
        if (!speech.isListening) ...[
          const Icon(
            Icons.radio_button_unchecked_rounded,
            size: 13,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 7),
          const Text(
            'Audio Inactive — Click Start Live Class',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ] else ...[
          const Icon(
            Icons.radio_button_checked_rounded,
            size: 13,
            color: AppColors.emerald,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              'Sharing Active: ${speech.activeSharingSourceTitle}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          _AudioEqualizer(volume: speech.audioVolume),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: AppColors.pillTag,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '${speech.captureElapsedSeconds}s',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => speech.stopListening(),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFF261919),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF452222)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stop_circle_outlined, size: 12, color: AppColors.rose),
                  SizedBox(width: 4),
                  Text(
                    'Stop Sharing',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.rose,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        Container(
          height: 18,
          width: 1,
          color: AppColors.border,
          margin: const EdgeInsets.symmetric(horizontal: 12),
        ),

        // 2. Live AI Activity Ticker
        Expanded(
          child: Row(
            children: [
              if (provider.isExtracting) ...[
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'AI Analyzing speech & extracting concept nodes...',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else if (speech.isListening) ...[
                const Icon(
                  Icons.graphic_eq_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '🎧 ${speech.activeTickerText}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    '✨ Thinkly Ready • Real-Time AI Mind Map & PDF Notes',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 8),

        // 3. Lecture History Sidebar Button
        InkWell(
          onTap: onToggleHistory,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isHistoryOpen ? AppColors.pillTag : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isHistoryOpen ? AppColors.emerald : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 14,
                  color: isHistoryOpen ? AppColors.emerald : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  'History',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isHistoryOpen ? FontWeight.w700 : FontWeight.w500,
                    color: isHistoryOpen ? AppColors.emerald : AppColors.textSecondary,
                  ),
                ),
                if (provider.savedLectures.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.pillTag,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${provider.savedLectures.length}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AudioEqualizer extends StatelessWidget {
  final double volume;

  const _AudioEqualizer({required this.volume});

  @override
  Widget build(BuildContext context) {
    final clamped = volume.clamp(0.0, 1.0);
    final multipliers = [0.8, 1.2, 1.5, 1.1, 0.7];

    return SizedBox(
      height: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(5, (index) {
          final barH = math.max(3.0, (clamped * 14.0 * multipliers[index])).clamp(3.0, 15.0);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            width: 2.5,
            height: barH,
            margin: const EdgeInsets.symmetric(horizontal: 1.2),
            decoration: BoxDecoration(
              color: clamped > 0.05 ? AppColors.alabaster : const Color(0xFF333333),
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }
}
