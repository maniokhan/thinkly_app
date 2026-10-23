import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thinkly_app/core/env/env_config.dart';
import 'package:thinkly_app/core/services/speech_service.dart';
import 'package:thinkly_app/features/mindmap/providers/mind_map_provider.dart';
import 'package:thinkly_app/main.dart';
import 'package:thinkly_app/features/mindmap/screens/settings_screen.dart';
import 'package:thinkly_app/features/mindmap/screens/lecture_library_screen.dart';
import 'package:thinkly_app/features/mindmap/screens/pdf_notes_screen.dart';
import 'package:thinkly_app/features/mindmap/screens/mind_map_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Mobile Bottom Navigation Tabs - Switch between Mind Map, Notes, Library, and Config', (WidgetTester tester) async {
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

    // 1. Initial tab: Mind Map Canvas
    expect(find.byType(MindMapScreen), findsOneWidget);
    expect(find.text('Thinkly'), findsOneWidget);
    expect(find.text('Mind Map'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Config'), findsOneWidget);

    // 2. Tap "Library" tab
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(LectureLibraryScreen), findsOneWidget);
    expect(find.text('Lecture Library'), findsOneWidget);
    expect(find.text('Start New Lecture'), findsOneWidget);

    // Search lectures
    await tester.enterText(find.byType(TextField).first, 'Operating Systems');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 3. Tap "Config" tab
    await tester.tap(find.text('Config'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Gemini AI Engine'), findsOneWidget);
    expect(find.text('Live Classroom Audio'), findsOneWidget);
    expect(find.text('PDF & Notes Engine'), findsOneWidget);

    // 4. Tap "Mind Map" tab to return
    await tester.tap(find.text('Mind Map'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(MindMapScreen), findsOneWidget);

    // 5. Tap "Notes" tab
    await tester.tap(find.text('Notes'));
    // Pump frames to let view build
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.byType(PdfNotesScreen), findsOneWidget);
    expect(find.text('Academic PDF Notes'), findsOneWidget);
    expect(find.text('Academic Document'), findsOneWidget);
    expect(find.text('Flashcards & Guide'), findsOneWidget);

    // Switch view inside Notes to "Flashcards & Guide"
    await tester.tap(find.text('Flashcards & Guide'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Markdown), findsOneWidget);

    // Return to Mind Map
    await tester.tap(find.text('Mind Map'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(MindMapScreen), findsOneWidget);
  });
}
