import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/debate/providers/debate_provider.dart';
import 'features/debate/screens/home_screen.dart';
import 'features/mascot/controllers/mascot_controller.dart';
import 'services/audio_service.dart';
import 'services/gemini_live_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Prefer portrait orientation for optimal debate & mascot framing
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const AIDebateApp());
}

class AIDebateApp extends StatefulWidget {
  const AIDebateApp({super.key});

  @override
  State<AIDebateApp> createState() => _AIDebateAppState();
}

class _AIDebateAppState extends State<AIDebateApp> with WidgetsBindingObserver {
  late final AudioService _audioService;
  late final GeminiLiveService _geminiLiveService;
  late final MascotController _mascotController;
  late final DebateProvider _debateProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _audioService = AudioService();
    _geminiLiveService = GeminiLiveService();
    _mascotController = MascotController();

    _debateProvider = DebateProvider(
      audioService: _audioService,
      geminiService: _geminiLiveService,
      mascotController: _mascotController,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _audioService.pauseAudio();
    } else if (state == AppLifecycleState.resumed) {
      _audioService.resumeAudio();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debateProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MascotController>.value(value: _mascotController),
        ChangeNotifierProvider<DebateProvider>.value(value: _debateProvider),
      ],
      child: MaterialApp(
        title: 'AI Debate Arena',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
