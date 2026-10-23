import 'package:flutter_test/flutter_test.dart';
import 'package:thinkly_app/core/services/pdf_notes_service.dart';
import 'package:thinkly_app/features/mindmap/models/mind_map_node.dart';
import 'package:thinkly_app/features/mindmap/models/mind_map_edge.dart';
import 'package:thinkly_app/features/mindmap/models/lecture_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfNotesService Tests', () {
    test('generates valid non-empty PDF document bytes with all sections', () async {
      final service = PdfNotesService();

      final rootNode = MindMapNode(
        id: 'root_zero_trust',
        label: 'Zero Trust Architecture & Enterprise Defense',
        summary: 'Primary security paradigm replacing perimeter-only castle-and-moat models.',
        category: NodeCategory.root,
        keyPoints: [
          'Foundational philosophy: Never trust, always verify',
          'Applies to internal and external network transactions',
        ],
        isKeyTakeaway: true,
        importance: 5,
      );

      final concept1 = MindMapNode(
        id: 'node_identity',
        parentId: 'root_zero_trust',
        label: 'Identity as the Primary Perimeter',
        summary: 'Authentication and authorization using MFA and mTLS rather than IP boundaries.',
        category: NodeCategory.coreConcept,
        keyPoints: [
          'Multi-Factor Authentication (MFA) enforcement',
          'Mutual TLS certificate verification',
          'Device health telemetry assessment',
        ],
        isKeyTakeaway: true,
        importance: 5,
        studentNote: 'Professor emphasized mTLS certificate renewal as a frequent exam question!',
      );

      final concept2 = MindMapNode(
        id: 'node_polp',
        parentId: 'root_zero_trust',
        label: 'Principle of Least Privilege (PoLP)',
        summary: 'Workloads and users receive only the absolute minimal permissions required.',
        category: NodeCategory.definition,
        keyPoints: [
          'Just-In-Time (JIT) access tokens',
          'Time-bounded authorization grants',
        ],
        importance: 4,
      );

      final session = LectureSession(
        id: 'lec_zero_trust_001',
        title: 'Zero Trust Architecture & Enterprise Defense',
        nodes: [rootNode, concept1, concept2],
        edges: [
          const MindMapEdge(fromId: 'root_zero_trust', toId: 'node_identity'),
          const MindMapEdge(fromId: 'root_zero_trust', toId: 'node_polp'),
        ],
        transcriptHistory:
            'Welcome class. Today we dismantle castle-and-moat security. Never trust, always verify.',
      );

      final pdfBytes = await service.generateLectureNotesPdf(session: session);

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);

      // A genuine PDF starts with %PDF- header magic bytes (0x25, 0x50, 0x44, 0x46, 0x2D)
      expect(pdfBytes[0], 0x25); // '%'
      expect(pdfBytes[1], 0x50); // 'P'
      expect(pdfBytes[2], 0x44); // 'D'
      expect(pdfBytes[3], 0x46); // 'F'
      expect(pdfBytes[4], 0x2D); // '-'

      // Ensure the generated document has substantial size containing styling and typography
      expect(pdfBytes.length, greaterThan(3000));
    });
  });
}
