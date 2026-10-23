import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/env/env_config.dart';
import 'core/theme/app_theme.dart';
import 'core/services/speech_service.dart';
import 'features/mindmap/providers/mind_map_provider.dart';
import 'features/mindmap/screens/mind_map_screen.dart';
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

class ThinklyShell extends StatelessWidget {
  const ThinklyShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Sleek 56px Top Header Bar
          TopNavigationBar(),

          // Full Workspace Mind Map Canvas & Controls
          Expanded(
            child: MindMapScreen(),
          ),
        ],
      ),
    );
  }
}
