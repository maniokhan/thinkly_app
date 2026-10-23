import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thinkly_app/core/env/env_config.dart';
import 'package:thinkly_app/core/services/speech_service.dart';
import 'package:thinkly_app/features/mindmap/providers/mind_map_provider.dart';
import 'package:thinkly_app/main.dart';
import 'package:thinkly_app/features/mindmap/widgets/pdf_preview_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Thinkly End-to-End User POV smoke & interaction test', (WidgetTester tester) async {
    // Set a generous screen size for desktop/web testing
    tester.view.physicalSize = const Size(1280, 900);
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

    // 1. Verify Top Navigation Bar & Branding
    expect(find.text('Thinkly'), findsOneWidget);
    expect(find.text('AI CLASS NOTES'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);

    // 2. Verify Floating Bottom Dock controls
    expect(find.text('Start Live Class'), findsOneWidget);
    expect(find.text('Topic / URL'), findsOneWidget);
    expect(find.text('Add Node'), findsOneWidget);
    expect(find.text('PDF Notes'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('Floating PiP'), findsOneWidget);

    // 3. User taps "PDF Notes" button
    await tester.tap(find.text('PDF Notes'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify PDF Preview Dialog is presented
    expect(find.byType(PdfPreviewDialog), findsOneWidget);
    expect(find.text('Thinkly AI Study Notes • PDF Document Preview'), findsOneWidget);
    expect(find.text('Share / Save'), findsOneWidget);

    // User closes the PDF dialog
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PdfPreviewDialog), findsNothing);

    // 4. User taps "Export" button to view comprehensive export options
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();

    expect(find.text('Export Class Notes as PDF Document'), findsOneWidget);
    expect(find.text('View AI Study Guide & Flashcards'), findsOneWidget);
    expect(find.text('Save Map to Local Library'), findsOneWidget);
    expect(find.text('Copy Graph JSON'), findsOneWidget);

    // Close export modal by tapping barrier or back
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // 5. User taps "+ Add Node" button
    await tester.tap(find.text('Add Node'));
    await tester.pumpAndSettle();

    expect(find.text('Add Manual Concept Node'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Quantum Teleportation');
    await tester.pumpAndSettle();

    // Tap "Add Node" submit button in dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Node'));
    await tester.pumpAndSettle();

    // Verify the new concept node is reflected
    expect(find.text('Quantum Teleportation'), findsAtLeastNWidgets(1));
  });
}
