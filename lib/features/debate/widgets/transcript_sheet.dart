import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/debate_turn.dart';

class TranscriptSheet extends StatelessWidget {
  final List<DebateTurn> turns;
  final ScrollController? scrollController;
  final VoidCallback? onClose;

  const TranscriptSheet({
    super.key,
    required this.turns,
    this.scrollController,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 180) {
          onClose?.call();
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Column(
          children: [
            // Drag handle
            GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.translucent,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LIVE TRANSCRIPT',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${turns.length} turns',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      if (onClose != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          tooltip: 'Close Transcript',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: AppColors.border),

            // Transcript turns list
            Expanded(
              child: turns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.mic_none_rounded,
                            size: 32,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Spoken debate dialogue will appear here...',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: turns.length,
                      itemBuilder: (context, index) {
                        final turn = turns[index];
                        final isUser = turn.speaker == Speaker.user;

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.80,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? AppColors.surfaceElevated
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isUser ? AppColors.accent : AppColors.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isUser ? 'YOU' : 'OPPONENT',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: isUser ? AppColors.accent : AppColors.cyan,
                                      ),
                                    ),
                                    if (turn.emotion != null && !isUser) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '· ${turn.emotion!.label}',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  turn.text,
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
