import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/env/env_config.dart';
import 'core/theme/app_theme.dart';
import 'core/services/speech_service.dart';
import 'features/mindmap/providers/mind_map_provider.dart';
import 'features/mindmap/screens/mind_map_screen.dart';
import 'features/mindmap/screens/pdf_notes_screen.dart';
import 'features/mindmap/screens/lecture_library_screen.dart';
import 'features/mindmap/screens/settings_screen.dart';
import 'widgets/top_navigation_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Environment (.env and SharedPreferences)
  final envConfig = EnvConfig();
  await envConfig.initialize();

  // Initialize Speech Services & Web Interop
  final speechService = SpeechService();
  speechService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: envConfig),
        ChangeNotifierProvider.value(value: speechService),
        ChangeNotifierProvider(create: (_) => MindMapProvider()),
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
      title: 'Thinkly | AI Live Class Mind Map & PDF Notes',
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

  @override
  Widget build(BuildContext context) {
    Widget activeScreen;
    switch (_currentIndex) {
      case 0:
        activeScreen = const Column(
          children: [
            TopNavigationBar(),
            Expanded(
              child: MindMapScreen(),
            ),
          ],
        );
        break;
      case 1:
        activeScreen = const PdfNotesScreen();
        break;
      case 2:
        activeScreen = LectureLibraryScreen(
          onSelectLecture: () {
            setState(() => _currentIndex = 0);
          },
        );
        break;
      case 3:
        activeScreen = const SettingsScreen();
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
          border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.cardElevated,
          height: 60,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.hub_rounded, size: 20, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.hub_rounded, size: 20, color: AppColors.accentIndigo),
              label: 'Mind Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_rounded, size: 20, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.description_rounded, size: 20, color: AppColors.accentRose),
              label: 'Notes',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_special_rounded, size: 20, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.folder_special_rounded, size: 20, color: AppColors.accentAmber),
              label: 'Library',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_rounded, size: 20, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.tune_rounded, size: 20, color: AppColors.accentViolet),
              label: 'Config',
            ),
          ],
        ),
      ),
    );
  }
}
