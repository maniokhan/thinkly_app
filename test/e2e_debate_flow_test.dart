import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinkly_app/core/config/app_config.dart';
import 'package:thinkly_app/features/debate/models/debate_difficulty.dart';
import 'package:thinkly_app/features/debate/models/debate_round.dart';
import 'package:thinkly_app/features/debate/models/debate_side.dart';
import 'package:thinkly_app/features/debate/providers/debate_provider.dart';
import 'package:thinkly_app/features/debate/screens/debate_result_screen.dart';
import 'package:thinkly_app/features/debate/screens/home_screen.dart';
import 'package:thinkly_app/features/debate/screens/live_debate_screen.dart';
import 'package:thinkly_app/features/mascot/controllers/mascot_controller.dart';
import 'package:thinkly_app/features/mascot/models/character_model.dart';
import 'package:thinkly_app/features/mascot/models/mascot_emotion.dart';
import 'package:thinkly_app/features/mascot/models/mascot_state.dart';
import 'package:thinkly_app/features/mascot/widgets/mascot_view.dart';
import 'package:thinkly_app/features/debate/widgets/transcript_sheet.dart';
import 'package:thinkly_app/features/debate/debate_app.dart';
import 'package:thinkly_app/services/audio_service.dart';
import 'package:thinkly_app/services/gemini_live_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Animate.restartOnHotReload = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.llfbandit.record/messages'), (call) async {
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_pcm_sound/methods'), (call) async {
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/webview'), (call) async {
      return null;
    });
  });

  setUp(() {
    AppConfig.apiKey = 'test-e2e-gemini-key';
  });

  group('AI Debate Arena End-to-End (E2E) Flow Tests', () {
    testWidgets('E2E Full Journey: Setup -> Live Debate -> Adjudication -> Return', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const AIDebateApp());
      await tester.pump(const Duration(seconds: 1));

      // 1. Verify Home Screen is rendered
      expect(find.text('AI DEBATE ARENA'), findsOneWidget);
      expect(find.text('Live Spoken AI Debate Championship'), findsOneWidget);

      // 2. Select Stance: Against (Con)
      final againstButton = find.text('AGAINST (CON)');
      expect(againstButton, findsOneWidget);
      await tester.ensureVisible(againstButton);
      await tester.tap(againstButton);
      await tester.pump(const Duration(milliseconds: 200));

      // 3. Select Difficulty: Hard
      final hardButton = find.text('HARD');
      expect(hardButton, findsOneWidget);
      await tester.ensureVisible(hardButton);
      await tester.tap(hardButton);
      await tester.pump(const Duration(milliseconds: 200));

      // 4. Select Mascot Character: Grok bot
      final grokBot = find.text('Grok bot');
      expect(grokBot, findsOneWidget);
      await tester.ensureVisible(grokBot);
      await tester.tap(grokBot);
      await tester.pump(const Duration(milliseconds: 200));

      // 5. Open Arena Settings Sheet
      final settingsIcon = find.byTooltip('Settings');
      expect(settingsIcon, findsOneWidget);
      await tester.tap(settingsIcon);
      await tester.pumpAndSettle();

      expect(find.text('ARENA SETTINGS'), findsOneWidget);
      expect(find.text('SAVE SETTINGS'), findsOneWidget);

      // Save settings and close sheet
      await tester.ensureVisible(find.text('SAVE SETTINGS'));
      await tester.tap(find.text('SAVE SETTINGS'));
      await tester.pumpAndSettle();
      // Dismiss the SnackBar so it doesn't block touches
      ScaffoldMessenger.of(tester.element(find.byType(HomeScreen))).clearSnackBars();
      await tester.pump(const Duration(milliseconds: 300));

      // 6. Start the Debate
      final startDebateButton = find.text('START DEBATE');
      expect(startDebateButton, findsOneWidget);
      await tester.ensureVisible(startDebateButton);
      await tester.tap(startDebateButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));

      // 7. Verify LiveDebateScreen is active
      expect(find.byType(LiveDebateScreen), findsOneWidget);
      expect(find.byType(MascotView), findsOneWidget);

      // 8. Test Transcript Sheet Toggle
      final transcriptButton = find.widgetWithText(OutlinedButton, 'Transcript');
      expect(transcriptButton, findsOneWidget);
      await tester.tap(transcriptButton);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TranscriptSheet), findsOneWidget);

      // Close transcript sheet
      final closeTranscript = find.byTooltip('Close Transcript');
      expect(closeTranscript, findsOneWidget);
      await tester.tap(closeTranscript);
      await tester.pump(const Duration(milliseconds: 300));

      // 9. End & Conclude Debate Flow
      final concludeDebateButton = find.byTooltip('Conclude Debate');
      expect(concludeDebateButton, findsOneWidget);
      await tester.tap(concludeDebateButton);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Confirmation Dialog
      expect(find.text('Conclude Debate?'), findsOneWidget);
      final confirmEnd = find.text('End & Adjudicate');
      expect(confirmEnd, findsOneWidget);
      await tester.tap(confirmEnd);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));

      // 10. Verify DebateResultScreen
      expect(find.byType(DebateResultScreen), findsOneWidget);
      expect(find.text('OFFICIAL ADJUDICATION'), findsOneWidget);

      // 11. Return to Arena Setup
      final returnButton = find.text('Return to Arena Setup');
      expect(returnButton, findsOneWidget);
      await tester.ensureVisible(returnButton);
      await tester.tap(returnButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // 12. Verify back on Home Screen
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('AI DEBATE ARENA'), findsOneWidget);

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('E2E Debate State & Audio Interruption Lifecycle', (tester) async {
      final audio = AudioService();
      final gemini = GeminiLiveService();
      final mascot = MascotController();

      final provider = DebateProvider(
        audioService: audio,
        geminiService: gemini,
        mascotController: mascot,
      );

      // Initial state
      expect(provider.phase, DebatePhase.idle);
      expect(provider.currentRound, DebateRound.opening);
      expect(provider.isMicMuted, isFalse);

      // Configure custom topic, stance, difficulty, opponent
      provider.setCustomTopic('Universal Basic Income');
      provider.setUserSide(DebateSide.forStance);
      provider.setDifficulty(DebateDifficulty.medium);
      provider.setSelectedCharacter(CharacterModel.allCharacters.firstWhere((c) => c.name == 'Nova'));

      expect(provider.activeTopicTitle, 'Universal Basic Income');
      expect(provider.userSide, DebateSide.forStance);
      expect(provider.selectedCharacter.name, 'Nova');

      // Test Mute toggle
      provider.toggleMicMute();
      expect(provider.isMicMuted, isTrue);
      provider.toggleMicMute();
      expect(provider.isMicMuted, isFalse);

      // Test manual interruption
      provider.interruptAI();
      expect(audio.isPlaying, isFalse);

      // Test Mascot Emotion switching
      await mascot.setEmotion(MascotEmotion.excited);
      expect(mascot.currentEmotion, MascotEmotion.excited);

      await mascot.setMouthLevel(0.85);
      expect(mascot.currentMouthLevel, 0.85);

      await mascot.setState(MascotState.speaking);
      expect(mascot.currentState, MascotState.speaking);

      // Cleanup
      provider.dispose();
      audio.dispose();
      gemini.dispose();
      mascot.dispose();
    });
  });
}
