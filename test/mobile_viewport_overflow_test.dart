import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thinkly_app/core/env/env_config.dart';
import 'package:thinkly_app/core/services/speech_service.dart';
import 'package:thinkly_app/features/mindmap/providers/mind_map_provider.dart';
import 'package:thinkly_app/main.dart';
import 'package:thinkly_app/features/mindmap/widgets/pdf_preview_dialog.dart';
import 'package:thinkly_app/widgets/api_key_settings_dialog.dart';
import 'package:thinkly_app/features/mindmap/widgets/node_inspector_sheet.dart';
import 'package:thinkly_app/features/mindmap/screens/mind_map_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('iPhone Viewport (375x812) - End-to-End Zero Overflows on all Sheets & Modals', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final envConfig = EnvConfig();
    final speechService = SpeechService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: envConfig),
          ChangeNotifierProvider.value(value: speechService),
          ChangeNotifierProvider(create: (_) => MindMapProvider()),
        ],
        child: const ThinklyApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Verify Brand & Navigation
    expect(find.text('Thinkly'), findsOneWidget);
    expect(find.text('AI CLASS NOTES'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);

    // 1. Audio Mode Picker Bottom Sheet
    await tester.tap(find.text('Start Live Class'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Select Audio Source'), findsOneWidget);
    expect(find.text('Share YouTube / Meet Tab Audio'), findsOneWidget);
    expect(find.text('Live Classroom Microphone'), findsOneWidget);

    // Close Audio Sheet
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 2. Add Manual Node Sheet
    await tester.ensureVisible(find.text('Add Node'));
    await tester.tap(find.text('Add Node'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Add Manual Concept Node'), findsOneWidget);

    // Close Node Sheet
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 3. Topic / URL Sheet
    await tester.ensureVisible(find.text('Topic / URL'));
    await tester.tap(find.text('Topic / URL'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Generate from YouTube / Topic'), findsOneWidget);

    // Close Topic Sheet
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 4. Export Menu Sheet
    await tester.ensureVisible(find.text('Export'));
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Export Class Notes as PDF Document'), findsOneWidget);

    // Close Export Sheet
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 5. Settings Dialog
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ApiKeySettingsDialog), findsOneWidget);
    expect(find.text('API Key & Settings'), findsOneWidget);
    expect(find.text('Reset to .env'), findsOneWidget);
    expect(find.text('Test Connection'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);

    // Close Settings
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 6. PDF Notes Preview Dialog
    await tester.ensureVisible(find.text('PDF Notes'));
    await tester.tap(find.text('PDF Notes'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.byType(PdfPreviewDialog), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PdfPreviewDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Compact Android Viewport (360x780) - Node Inspector & History Bottom Sheets', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
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

    // 1. History Drawer / Sheet on mobile
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Lecture History'), findsOneWidget);

    // Close history
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 2. Open Mobile Node Inspector Sheet for active node
    showModalBottomSheet(
      context: tester.element(find.byType(MindMapScreen)),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NodeInspectorSheet(
        node: mindMapProvider.nodes.first,
        isBottomSheet: true,
        onClose: () => Navigator.pop(ctx),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Concept Inspector'), findsOneWidget);
    expect(find.text('Personal Student Notes'), findsOneWidget);
    expect(find.text('Expand with AI (+Sub-Nodes)'), findsOneWidget);

    // Close Node Inspector Sheet
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Smallest Mobile Screen (320x568 iPhone SE) - Zero Overflows', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final envConfig = EnvConfig();
    final speechService = SpeechService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: envConfig),
          ChangeNotifierProvider.value(value: speechService),
          ChangeNotifierProvider(create: (_) => MindMapProvider()),
        ],
        child: const ThinklyApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Verify key elements render cleanly on 320px
    expect(find.text('Thinkly'), findsOneWidget);
    expect(find.text('Start Live Class'), findsOneWidget);
  });
}
