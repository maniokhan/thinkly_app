import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thinkly_app/core/env/env_config.dart';
import 'package:thinkly_app/core/services/speech_service.dart';
import 'package:thinkly_app/features/mindmap/providers/mind_map_provider.dart';
import 'package:thinkly_app/main.dart';
import 'package:thinkly_app/features/mindmap/screens/lecture_capture_screen.dart';
import 'package:thinkly_app/features/mindmap/screens/lecture_results_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Thinkly 3-Tap Core Flow: Record -> Stop & Analyze -> Results',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final envConfig = EnvConfig();
    final speechService = SpeechService();
    final mindMapProvider = MindMapProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: envConfig),
          ChangeNotifierProvider.value(value: speechService),
          ChangeNotifierProvider.value(value: mindMapProvider),
        ],
        child: const ThinklyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Capture Screen branding and primary action
    expect(find.byType(LectureCaptureScreen), findsOneWidget);
    expect(find.text('Thinkly'), findsOneWidget);
    expect(find.text('Start recording'), findsOneWidget);

    // Tap 1: Start recording
    await tester.tap(find.text('Start recording'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify recording active state & primary action switches to "Stop & analyze"
    expect(find.text('Stop & analyze'), findsOneWidget);

    // Tap 2: Stop & analyze
    await tester.tap(find.text('Stop & analyze'));
    await tester.pumpAndSettle();

    // Tap 3: Land on Results screen with Summary & Graphs & PDF
    expect(find.byType(LectureResultsScreen), findsOneWidget);
    expect(find.text('Make PDF'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Graphs'), findsOneWidget);

    // Switch to Graphs segment
    await tester.tap(find.text('Graphs'));
    await tester.pumpAndSettle();

    expect(find.text('TOPIC IMPORTANCE'), findsOneWidget);
    expect(find.text('TIMELINE & CONCEPT DEPTH'), findsOneWidget);
  });
}
