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
import 'package:thinkly_app/features/mindmap/screens/lecture_library_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'Mobile 3-Tab Navigation - Switch cleanly between Record, Results, and Classes',
      (WidgetTester tester) async {
    // Pixel 9 Pro viewport (412 x 915)
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
    expect(tester.takeException(), isNull);

    // 1. Initial Tab: Record Screen
    expect(find.byType(LectureCaptureScreen), findsOneWidget);
    expect(find.text('Thinkly'), findsOneWidget);
    expect(find.text('Start recording'), findsOneWidget);
    expect(find.text('Record'), findsOneWidget);
    expect(find.text('Results'), findsOneWidget);
    expect(find.text('Classes'), findsOneWidget);

    // 2. Switch to "Results" tab
    await tester.tap(find.text('Results'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(LectureResultsScreen), findsOneWidget);
    expect(find.text('Make PDF'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Graphs'), findsOneWidget);

    // Switch to Graphs sub-tab
    await tester.tap(find.text('Graphs'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 3. Switch to "Classes" (Library) tab
    await tester.tap(find.text('Classes'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(LectureLibraryScreen), findsOneWidget);
    expect(find.text('Lecture Library'), findsOneWidget);

    // 4. Return to "Record" tab
    await tester.tap(find.text('Record'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(LectureCaptureScreen), findsOneWidget);
  });
}
