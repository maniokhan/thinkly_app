import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinkly_app/features/mindmap/providers/mind_map_provider.dart';
import 'package:thinkly_app/features/mindmap/models/mind_map_node.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MindMapProvider Tests', () {
    test('initializes default lecture session with root node', () {
      final provider = MindMapProvider();

      expect(provider.nodes.isNotEmpty, isTrue);
      expect(provider.nodes.first.category, NodeCategory.root);
      expect(provider.currentSession.title, 'Zero Trust Architecture & Enterprise Defense');
      expect(provider.selectedNode, isNotNull);
    });

    test('adds manual node and connects edge to parent', () {
      final provider = MindMapProvider();
      final initialCount = provider.nodes.length;
      final rootId = provider.nodes.first.id;

      provider.addManualNode(
        title: 'Micro-segmentation',
        summary: 'Isolating workloads to eliminate lateral network movement.',
        category: NodeCategory.coreConcept,
        parentId: rootId,
        isKeyTakeaway: true,
      );

      expect(provider.nodes.length, initialCount + 1);
      final added = provider.nodes.firstWhere((n) => n.label == 'Micro-segmentation');
      expect(added.parentId, rootId);
      expect(added.isKeyTakeaway, isTrue);
      expect(added.importance, 5);

      // Verify edge was added
      final edgeExists = provider.edges.any((e) => e.fromId == rootId && e.toId == added.id);
      expect(edgeExists, isTrue);
    });

    test('adds student personal note to active node', () {
      final provider = MindMapProvider();
      final root = provider.nodes.first;

      provider.updateNodeStudentNote(root.id, 'Professor mentioned this is on Midterm 2');
      expect(provider.nodes.first.studentNote, 'Professor mentioned this is on Midterm 2');

      provider.addStudentNoteToActiveNode('Also check NIST SP 800-207');
      expect(provider.nodes.first.studentNote, contains('NIST SP 800-207'));
    });

    test('flags node as key exam takeaway and toggles collapsed state', () {
      final provider = MindMapProvider();
      final rootId = provider.nodes.first.id;

      provider.addManualNode(
        title: 'Sub-topic',
        category: NodeCategory.definition,
        parentId: rootId,
        isKeyTakeaway: false,
      );

      final child = provider.nodes.firstWhere((n) => n.label == 'Sub-topic');
      expect(child.isKeyTakeaway, isFalse);

      provider.toggleNodeImportance(child.id);
      expect(child.isKeyTakeaway, isTrue);
      expect(child.importance, 5);

      expect(child.isCollapsed, isFalse);
      provider.toggleNodeCollapsed(child.id);
      expect(child.isCollapsed, isTrue);
    });

    test('creates and switches to new lecture session and persists', () async {
      final provider = MindMapProvider();

      provider.startNewLecture('Quantum Information & Cryptography');
      expect(provider.currentSession.title, 'Quantum Information & Cryptography');
      expect(provider.nodes.first.label, 'Quantum Information & Cryptography');

      await provider.saveCurrentLecture();
      expect(provider.savedLectures.isNotEmpty, isTrue);
    });
  });
}
