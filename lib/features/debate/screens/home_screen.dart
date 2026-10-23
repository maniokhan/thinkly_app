import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/wonderous_animations.dart';
import '../../mascot/widgets/character_picker.dart';
import '../../settings/settings_sheet.dart';
import '../models/debate_difficulty.dart';
import '../models/debate_side.dart';
import '../models/debate_topic.dart';
import '../providers/debate_provider.dart';
import 'live_debate_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _customTopicController = TextEditingController();
  bool _isCustomTopic = false;

  @override
  void dispose() {
    _customTopicController.dispose();
    super.dispose();
  }

  void _startDebate(DebateProvider provider) {
    if (!AppConfig.isConfigured) {
      SettingsSheet.show(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Gemini API Key in settings to start.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isCustomTopic && _customTopicController.text.trim().isNotEmpty) {
      provider.setCustomTopic(_customTopicController.text.trim());
    }

    Navigator.of(context).push(
      WonderousAnimations.pageRoute(const LiveDebateScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DebateProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'AI DEBATE ARENA',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => SettingsSheet.show(context),
            icon: const Icon(Icons.tune_rounded, size: 20, color: AppColors.textSecondary),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Headline
              Text(
                'Live Spoken AI Debate Championship',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ).animateHeaderEntrance(delayMs: 0),
              const SizedBox(height: 6),
              Text(
                'Continuous full-duplex conversational voice debate powered by Gemini Live API.',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ).animateHeaderEntrance(delayMs: 40),

              const SizedBox(height: 20),

              // Mode Toggle (Live Debate vs Turn-Based)
              _buildModeToggle(provider).animateCardEntrance(index: 0),

              const SizedBox(height: 16),

              // Compact Topic Card with FOR / AGAINST Segmented Switch
              _buildTopicCard(provider).animateCardEntrance(index: 1),

              const SizedBox(height: 16),

              // Opponent Character Picker
              CharacterPicker(
                selectedCharacter: provider.selectedCharacter.name,
                onCharacterSelected: (char) => provider.setSelectedCharacter(char),
              ),

              const SizedBox(height: 16),

              // Difficulty Intensity Pills
              _buildDifficultySection(provider).animateCardEntrance(index: 2),

              const SizedBox(height: 28),

              // Big Confident "START DEBATE" Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _startDebate(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mic_rounded, size: 20, color: Colors.black),
                      const SizedBox(width: 10),
                      Text(
                        'START DEBATE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animateCardEntrance(index: 3),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle(DebateProvider provider) {
    final isLive = provider.debateMode == DebateMode.live;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => provider.setDebateMode(DebateMode.live),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isLive ? AppColors.surfaceElevated : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isLive ? AppColors.accent : Colors.transparent,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 14,
                          color: isLive ? AppColors.accent : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Live Debate',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isLive ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Full-duplex VAD',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => provider.setDebateMode(DebateMode.turnBased),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isLive ? AppColors.surfaceElevated : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: !isLive ? AppColors.accent : Colors.transparent,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 14,
                          color: !isLive ? AppColors.accent : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Turn-Based',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: !isLive ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to handoff',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(DebateProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  provider.selectedTopic.category.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isCustomTopic = !_isCustomTopic;
                  });
                },
                child: Text(
                  _isCustomTopic ? 'Presets' : '+ Custom Topic',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_isCustomTopic)
            TextField(
              controller: _customTopicController,
              maxLines: 2,
              style: GoogleFonts.ibmPlexSans(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter motion, e.g. Space exploration should be prioritized...',
                hintStyle: GoogleFonts.ibmPlexSans(fontSize: 13, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            )
          else ...[
            Text(
              provider.selectedTopic.title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              provider.selectedTopic.contextDescription,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            // Preset pills
            SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: DebateTopic.presets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final topic = DebateTopic.presets[index];
                  final isSelected = topic == provider.selectedTopic;

                  return GestureDetector(
                    onTap: () => provider.setSelectedTopic(topic),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.border,
                        ),
                      ),
                      child: Text(
                        topic.category,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.black : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Stance Segmented Switch (FOR vs AGAINST)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => provider.setUserSide(DebateSide.forStance),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: provider.userSide == DebateSide.forStance
                          ? AppColors.surfaceElevated
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: provider.userSide == DebateSide.forStance
                            ? AppColors.accent
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'FOR (PRO)',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: provider.userSide == DebateSide.forStance
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => provider.setUserSide(DebateSide.againstStance),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: provider.userSide == DebateSide.againstStance
                          ? AppColors.surfaceElevated
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: provider.userSide == DebateSide.againstStance
                            ? AppColors.error
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'AGAINST (CON)',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: provider.userSide == DebateSide.againstStance
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySection(DebateProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DIFFICULTY RATING',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: DebateDifficulty.values.map((diff) {
            final isSelected = diff == provider.difficulty;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => provider.setDifficulty(diff),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        diff.label.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isSelected ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
