import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/wonderous_animations.dart';
import '../models/debate_score.dart';
import '../providers/debate_provider.dart';
import '../widgets/transcript_sheet.dart';
import 'live_debate_screen.dart';

class DebateResultScreen extends StatefulWidget {
  const DebateResultScreen({super.key});

  @override
  State<DebateResultScreen> createState() => _DebateResultScreenState();
}

class _DebateResultScreenState extends State<DebateResultScreen> {
  bool _showTranscript = false;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DebateProvider>();
    final score = provider.lastScore ??
        DebateScore.calculateFromSession(
          duration: provider.sessionDuration,
          turnsCount: provider.turnsCount,
          interruptionCount: provider.interruptionCount,
          topic: provider.activeTopicTitle,
          userStance: provider.userSide.label,
        );

    final isVictory = score.winnerVerdict.contains('User');
    final isDraw = score.winnerVerdict.contains('Split');
    final verdictBanner = isVictory ? 'VICTORY' : (isDraw ? 'DRAW' : 'DEFEAT');
    final verdictColor = isVictory ? AppColors.accent : (isDraw ? AppColors.warning : AppColors.error);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'OFFICIAL ADJUDICATION',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Verdict Banner (#121214 surface, 1px border)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: verdictColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: verdictColor.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                verdictBanner,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: verdictColor,
                                ),
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${score.overallScore}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accent,
                                  ),
                                ),
                                Text(
                                  ' / 100',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          score.winnerVerdict,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          score.judgeCommentary,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            height: 1.45,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ).animateCardEntrance(index: 0),

                  const SizedBox(height: 16),

                  // Rubric Category Breakdown: 4 Horizontal Progress Bars
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RUBRIC BREAKDOWN (0-25 PTS)',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRubricBar('Logic & Evidence', score.logicScore, 25),
                        const SizedBox(height: 12),
                        _buildRubricBar('Rhetoric & Style', score.rhetoricScore, 25),
                        const SizedBox(height: 12),
                        _buildRubricBar('Responsiveness', score.responsivenessScore, 25),
                        const SizedBox(height: 12),
                        _buildRubricBar('Time & Composure', score.timeManagementScore, 25),
                      ],
                    ),
                  ).animateCardEntrance(index: 1),

                  const SizedBox(height: 16),

                  // Round-by-Round Breakdown
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROUND-BY-ROUND ADJUDICATION',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...score.roundScores.map((roundScore) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        roundScore.round.title,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        roundScore.critique,
                                        style: GoogleFonts.ibmPlexSans(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${roundScore.userScore} vs ${roundScore.aiScore}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: roundScore.userScore >= roundScore.aiScore
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ).animateCardEntrance(index: 2),

                  const SizedBox(height: 16),

                  // Session Metrics Row (Duration, Turns, Interruptions)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'DURATION',
                          _formatDuration(score.debateDuration),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          'SPOKEN TURNS',
                          '${score.turnsCount}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          'INTERRUPTIONS',
                          '${score.interruptionCount}',
                        ),
                      ),
                    ],
                  ).animateCardEntrance(index: 3),

                  const SizedBox(height: 24),

                  // Actions: Review Transcript, Debate Again, Exit
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _showTranscript = true);
                          },
                          child: const Text('Transcript'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              WonderousAnimations.pageRoute(const LiveDebateScreen()),
                            );
                          },
                          child: const Text('Debate Again'),
                        ),
                      ),
                    ],
                  ).animateCardEntrance(index: 4),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: Text(
                        'Return to Arena Setup',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Transcript Sheet Modal overlay
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
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRubricBar(String label, int value, int max) {
    final ratio = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$value / $max',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
