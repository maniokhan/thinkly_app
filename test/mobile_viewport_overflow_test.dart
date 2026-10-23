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

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: EnvConfig()),
        ChangeNotifierProvider.value(value: SpeechService()),
        ChangeNotifierProvider(create: (_) => MindMapProvider()),
      ],
      child: const ThinklyApp(),
    );
  }

  testWidgets(
    'iPhone Viewport (375x812) - End-to-End Zero Overflows across screens and sheets',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Verify Capture Screen
      expect(find.byType(LectureCaptureScreen), findsOneWidget);
      expect(find.text('Start recording'), findsOneWidget);

      // Open YouTube Shortcut Sheet
      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Analyze YouTube lecture'), findsOneWidget);

      // Close Sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to Results Tab
      await tester.tap(find.text('Results'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(LectureResultsScreen), findsOneWidget);
      expect(find.text('Make PDF'), findsOneWidget);

      // Switch to Graphs
      await tester.tap(find.text('Graphs'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to Classes
      await tester.tap(find.text('Classes'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Compact Android Viewport (360x780) - Zero Overflows on Capture & Results',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.text('Start recording'), findsOneWidget);

      // Switch to Results
      await tester.tap(find.text('Results'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to Graphs
      await tester.tap(find.text('Graphs'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Smallest Mobile Screen (320x568 iPhone SE) - Zero Overflows',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.text('Start recording'), findsOneWidget);

      // Switch to Results
      await tester.tap(find.text('Results'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to Classes
      await tester.tap(find.text('Classes'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
