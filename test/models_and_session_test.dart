import 'package:flutter_test/flutter_test.dart';
import 'package:thinkly_app/features/mindmap/models/mind_map_node.dart';
import 'package:thinkly_app/features/mindmap/models/mind_map_edge.dart';
import 'package:thinkly_app/features/mindmap/models/lecture_session.dart';

void main() {
  group('MindMapNode Tests', () {
    test('creates node and parses categories correctly', () {
      final node = MindMapNode(
        id: 'node_1',
        label: 'Zero Trust Security',
        summary: 'Never trust, always verify.',
        category: NodeCategory.coreConcept,
        keyPoints: ['Principle of Least Privilege', 'Continuous Authentication'],
        isKeyTakeaway: true,
        importance: 5,
        studentNote: 'Crucial for final exam!',
      );

      expect(node.id, 'node_1');
      expect(node.label, 'Zero Trust Security');
      expect(node.category, NodeCategory.coreConcept);
      expect(node.category.displayName, 'Core Concept');
      expect(node.isKeyTakeaway, isTrue);
      expect(node.importance, 5);
      expect(node.studentNote, 'Crucial for final exam!');

      // Test category string parsing
      expect(NodeCategory.fromString('root'), NodeCategory.root);
      expect(NodeCategory.fromString('definition'), NodeCategory.definition);
      expect(NodeCategory.fromString('example'), NodeCategory.example);
      expect(NodeCategory.fromString('question'), NodeCategory.question);
      expect(NodeCategory.fromString('student_note'), NodeCategory.studentNote);
      expect(NodeCategory.fromString('unknown_category'), NodeCategory.coreConcept);
    });

    test('serializes and deserializes node to/from JSON accurately', () {
      final original = MindMapNode(
        id: 'test_node_42',
        label: 'Quantum Superposition',
        summary: 'Linear combination of states.',
        category: NodeCategory.definition,
        parentId: 'root_001',
        childIds: ['child_01', 'child_02'],
        keyPoints: ['Qubit alpha and beta', 'Measurement collapses wave function'],
        isKeyTakeaway: true,
        importance: 4,
        studentNote: 'Remember equation |ψ⟩ = α|0⟩ + β|1⟩',
        x: 150.0,
        y: -80.0,
        isCollapsed: false,
      );

      final json = original.toJson();
      final restored = MindMapNode.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.label, original.label);
      expect(restored.summary, original.summary);
      expect(restored.category, original.category);
      expect(restored.parentId, original.parentId);
      expect(restored.childIds, original.childIds);
      expect(restored.keyPoints, original.keyPoints);
      expect(restored.isKeyTakeaway, original.isKeyTakeaway);
      expect(restored.importance, original.importance);
      expect(restored.studentNote, original.studentNote);
      expect(restored.x, original.x);
      expect(restored.y, original.y);
    });
  });

  group('LectureSession & MindMapEdge Tests', () {
    test('serializes and deserializes lecture session with graph edges', () {
      final rootNode = MindMapNode(
        id: 'root_1',
        label: 'Network Security',
        summary: 'Central architectural thesis',
        category: NodeCategory.root,
        childIds: ['sub_1'],
      );

      final childNode = MindMapNode(
        id: 'sub_1',
        parentId: 'root_1',
        label: 'Microsegmentation',
        summary: 'Choking off lateral traversal',
        category: NodeCategory.coreConcept,
        keyPoints: ['Granular firewall rules', 'Workload isolation'],
        isKeyTakeaway: true,
      );

      final edge = const MindMapEdge(fromId: 'root_1', toId: 'sub_1');

      final session = LectureSession(
        id: 'lec_test_123',
        title: 'Advanced Computer Security',
        nodes: [rootNode, childNode],
        edges: [edge],
        transcriptHistory: 'Welcome to class today we discuss network security and microsegmentation.',
      );

      final jsonStr = session.toJsonString();
      final restored = LectureSession.fromJsonString(jsonStr);

      expect(restored.id, session.id);
      expect(restored.title, session.title);
      expect(restored.nodes.length, 2);
      expect(restored.edges.length, 1);
      expect(restored.edges.first.fromId, 'root_1');
      expect(restored.edges.first.toId, 'sub_1');
      expect(restored.transcriptHistory, contains('microsegmentation'));
    });
  });
}
