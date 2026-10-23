import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/env/env_config.dart';
import 'core/theme/app_theme.dart';
import 'core/services/speech_service.dart';
import 'core/config/app_config.dart';
import 'features/mindmap/providers/mind_map_provider.dart';
import 'features/mindmap/screens/lecture_capture_screen.dart';
import 'features/mindmap/screens/lecture_results_screen.dart';
import 'features/mindmap/screens/lecture_library_screen.dart';
import 'features/debate/providers/debate_provider.dart';
import 'features/mascot/controllers/mascot_controller.dart';
import 'services/audio_service.dart';
import 'services/gemini_live_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait orientation for mobile
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Environment (.env and SharedPreferences)
  final envConfig = EnvConfig();
  await envConfig.initialize();

  // Sync Gemini API key to AppConfig for AI Debate Live WebSocket
  if (envConfig.apiKey.isNotEmpty) {
    AppConfig.apiKey = envConfig.apiKey;
  }

  // Initialize Speech Services & Web Interop
  final speechService = SpeechService();
  speechService.initialize();

  // Initialize AI Debate Services
  final audioService = AudioService();
  final geminiLiveService = GeminiLiveService();
  final mascotController = MascotController();
  final debateProvider = DebateProvider(
    audioService: audioService,
    geminiService: geminiLiveService,
    mascotController: mascotController,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: envConfig),
        ChangeNotifierProvider.value(value: speechService),
        ChangeNotifierProvider(create: (_) => MindMapProvider()),
        ChangeNotifierProvider.value(value: mascotController),
        ChangeNotifierProvider.value(value: debateProvider),
      ],
      child: const ThinklyApp(),
    ),
  );
}

class ThinklyApp extends StatelessWidget {
  const ThinklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thinkly | AI Live Class Notes & AI Debate Arena',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ThinklyShell(),
    );
  }
}

class ThinklyShell extends StatefulWidget {
  const ThinklyShell({super.key});

  @override
  State<ThinklyShell> createState() => _ThinklyShellState();
}

class _ThinklyShellState extends State<ThinklyShell> {
  int _currentIndex = 0;
  int _resultsInitialSegment = 0;

  @override
  Widget build(BuildContext context) {
    Widget activeScreen;
    switch (_currentIndex) {
      case 0:
        activeScreen = LectureCaptureScreen(
          onNavigateToResults: ([int segment = 0]) => setState(() {
            _currentIndex = 1;
            _resultsInitialSegment = segment;
          }),
        );
        break;
      case 1:
        activeScreen = LectureResultsScreen(
          initialSegment: _resultsInitialSegment,
          onBackToRecord: () => setState(() => _currentIndex = 0),
        );
        break;
      case 2:
        activeScreen = LectureLibraryScreen(
          onSelectLecture: () => setState(() {
            _currentIndex = 1;
            _resultsInitialSegment = 0;
          }),
        );
        break;
      default:
        activeScreen = const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: activeScreen,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.raisedSurface,
          height: 62,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.mic_none_rounded,
                  size: 20, color: AppColors.secondaryText),
              selectedIcon:
                  Icon(Icons.mic_rounded, size: 20, color: AppColors.accent),
              label: 'Record',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined,
                  size: 20, color: AppColors.secondaryText),
              selectedIcon: Icon(Icons.auto_awesome_rounded,
                  size: 20, color: AppColors.accent),
              label: 'Results',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined,
                  size: 20, color: AppColors.secondaryText),
              selectedIcon: Icon(Icons.folder_rounded,
                  size: 20, color: AppColors.accent),
              label: 'Classes',
            ),
          ],
        ),
      ),
    );
  }
}
