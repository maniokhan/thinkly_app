import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../env/env_config.dart';
import '../../features/mindmap/models/mind_map_node.dart';
import '../../features/mindmap/models/mind_map_edge.dart';

class MindMapDeltaAction {
  final String action; // 'add_node', 'update_node', 'connect_edge', 'tag_important'
  final MindMapNode? node;
  final MindMapEdge? edge;
  final String? targetNodeId;
  final String? additionalNotes;
  final int? importance;

  MindMapDeltaAction({
    required this.action,
    this.node,
    this.edge,
    this.targetNodeId,
    this.additionalNotes,
    this.importance,
  });
}

class MindMapDeltaResult {
  final List<MindMapDeltaAction> actions;
  final String rawResponse;
  final String? extractedTranscript;
  final String? detectedTopic;
  final String? detectedTopicSummary;

  MindMapDeltaResult({
    required this.actions,
    required this.rawResponse,
    this.extractedTranscript,
    this.detectedTopic,
    this.detectedTopicSummary,
  });
}

class GeminiAiService {
  final EnvConfig _envConfig = EnvConfig();
  final _uuid = const Uuid();

  String get _apiKey => _envConfig.apiKey;
  String get _model => _envConfig.model;

  /// Ordered list of supported Gemini models for automatic fallback
  List<String> _getModelCandidates() {
    const validFallbackChain = [
      'gemini-3.8-flash',
      'gemini-3.5-flash-lite',
      'gemini-3.5-flash',
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
      'gemini-2.0-flash',
    ];
    final list = <String>[];
    final active = _model.trim();
    if (active == 'gemini-3.8-flash' || active == 'gemini-3.5-flash-lite') {
      list.add(active);
    } else if (active == 'gemini-3.5-flash' || active == 'gemini-2.5-flash' || active == 'gemini-2.0-flash') {
      list.add('gemini-3.8-flash');
      list.add('gemini-3.5-flash-lite');
      list.add(active);
    } else if (active.isNotEmpty) {
      list.add(active);
    }
    for (final m in validFallbackChain) {
      if (!list.contains(m)) list.add(m);
    }
    return list;
  }

  /// Helper to call Gemini v1beta endpoint with JSON output format and sequential fallback
  Future<String> _callGeminiApi({
    required String systemInstruction,
    required String userPrompt,
    double temperature = 0.4,
  }) async {
    if (!_envConfig.isConfigured) {
      throw Exception('Gemini API key is not configured.');
    }

    final candidateModels = _getModelCandidates();
    String? lastError;

    for (final model in candidateModels) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
        );

        final payload = {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': '$systemInstruction\n\n$userPrompt'}
              ]
            }
          ],
          'generationConfig': {
            'temperature': temperature,
            'responseMimeType': 'application/json',
          }
        };

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          debugPrint('[GeminiAiService] Successfully called Gemini using model: $model');
          final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = bodyJson['candidates'] as List<dynamic>?;
          if (candidates == null || candidates.isEmpty) {
            throw Exception('Empty candidates received from Gemini');
          }

          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts == null || parts.isEmpty) {
            throw Exception('Empty parts received from Gemini');
          }

          final text = parts[0]['text'] as String;
          return text.trim();
        } else {
          debugPrint('[GeminiAiService] HTTP ${response.statusCode} on model $model: ${response.body}');
          lastError = 'HTTP ${response.statusCode}: ${response.body}';
          continue;
        }
      } catch (e) {
        debugPrint('[GeminiAiService] Exception on model $model: $e. Retrying fallback...');
        lastError = e.toString();
        continue;
      }
    }

    throw Exception('All Gemini fallback models exhausted. Last error: $lastError');
  }

  /// Helper to call Gemini v1beta endpoint with multimodal Audio input and sequential fallback
  Future<String> _callGeminiMultimodalAudio({
    required String systemInstruction,
    required String userPrompt,
    required String base64Audio,
    required String mimeType,
    double temperature = 0.2,
  }) async {
    if (!_envConfig.isConfigured) {
      throw Exception('Gemini API key is not configured.');
    }

    final cleanMime = mimeType.split(';').first.trim();
    final effectiveMime = cleanMime.isNotEmpty ? cleanMime : 'audio/webm';

    final candidateModels = _getModelCandidates();
    String? lastError;

    for (final model in candidateModels) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
        );

        final payload = {
          'contents': [
            {
              'parts': [
                {
                  'inline_data': {
                    'mime_type': effectiveMime,
                    'data': base64Audio,
                  }
                },
                {
                  'text': '$systemInstruction\n\n$userPrompt',
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': temperature,
            'responseMimeType': 'application/json',
          }
        };

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          debugPrint('[GeminiAiService] Audio successfully processed using model: $model');
          final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = bodyJson['candidates'] as List<dynamic>?;
          if (candidates == null || candidates.isEmpty) {
            throw Exception('Empty candidates received from Gemini');
          }

          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts == null || parts.isEmpty) {
            throw Exception('Empty parts received from Gemini');
          }

          final text = parts[0]['text'] as String;
          return text.trim();
        } else {
          lastError = 'Audio HTTP ${response.statusCode} on $model: ${response.body}';
          continue;
        }
      } catch (e) {
        lastError = e.toString();
        continue;
      }
    }

    throw Exception('All Gemini audio fallback models exhausted. Last error: $lastError');
  }

  /// 1A. Incremental Mind Map Extractor from Direct Audio Chunks (YouTube Video & Google Meet Tab Audio)
  Future<MindMapDeltaResult> extractMindMapDeltaFromAudio({
    required String base64Audio,
    required String mimeType,
    required List<MindMapNode> existingNodes,
    required String rootTopic,
  }) async {
    final existingNodesSummary = existingNodes
        .take(20)
        .map((n) => '- [${n.id}] "${n.label}" (${n.category.name}): ${n.summary}')
        .join('\n');

    final isInitialTopic = rootTopic.trim().isEmpty ||
        rootTopic.toLowerCase().contains('listening for') ||
        rootTopic.toLowerCase().contains('zero trust');

    final systemInstruction = '''
You are Thinkly's Academic Audio Transcriber and Knowledge Graph Architect.
Listen to the incoming lecture audio from YouTube video or Google Meet / Online Class.
Your job is to:
1. Accurately transcribe what was spoken into the "transcript" field.
2. ${isInitialTopic ? 'Determine the overall lecture subject from the audio and return it in "detectedTopic" along with a 1-sentence summary in "detectedTopicSummary".' : 'If a new overarching topic is introduced, provide it in "detectedTopic".'}
3. Extract new educational concepts, definitions, formulas, examples, and teacher emphasis points from the audio into Mind Map nodes in real time.
4. HIERARCHICAL TREE RULE: When details, mechanisms, implementations, or examples of an existing topic are discussed, attach them directly to that specific concept's node ID using "parentId"—DO NOT attach everything to root! Only set "parentId" to root for brand-new high-level topics.
5. STRICT RULE: If the audio segment is silent, contains background music, sponsor ads, greetings, or contains NO new educational insights, return "actions": [] and transcribe the audio without adding unnecessary dummy nodes. NEVER invent generic filler nodes.
6. Emit structured JSON matching this schema:
{
  "detectedTopic": "Specific Subject (or null if already known)",
  "detectedTopicSummary": "1-sentence central thesis (or null)",
  "transcript": "Exact transcription of lecturer's speech...",
  "actions": [
    {
      "action": "add_node",
      "id": "slug_or_id",
      "title": "Clear Punchy Title (2-5 words)",
      "category": "core_concept" | "definition" | "example" | "question",
      "parentId": "existing_node_id_or_root",
      "summary": "1-2 sentence core mechanism or explanation",
      "keyPoints": [
        "Essential rule or formula",
        "Empirical detail or proof",
        "Teacher emphasis point"
      ],
      "importance": 1 to 5,
      "isImportant": true or false
    },
    {
      "action": "connect_edge",
      "fromId": "node_id_1",
      "toId": "node_id_2"
    }
  ]
}
''';

    final userPrompt = '''
Current Lecture Topic: "$rootTopic"
Existing Graph Nodes:
$existingNodesSummary

Listen to this audio chunk from YouTube video or Google Meet class, transcribe it, and extract the knowledge graph updates in JSON now:
''';

    try {
      final jsonText = await _callGeminiMultimodalAudio(
        systemInstruction: systemInstruction,
        userPrompt: userPrompt,
        base64Audio: base64Audio,
        mimeType: mimeType,
        temperature: 0.2,
      );

      return _parseDeltaJson(jsonText, existingNodes);
    } catch (e) {
      debugPrint('[GeminiAiService] Audio extraction error: $e');
      return MindMapDeltaResult(
        actions: [],
        rawResponse: '{}',
        extractedTranscript: null,
      );
    }
  }

  /// 1B. Incremental Mind Map Graph Extractor from Text Transcripts (Microphone & Simulation)
  Future<MindMapDeltaResult> extractMindMapDelta({
    required String transcriptChunk,
    required List<MindMapNode> existingNodes,
    required String rootTopic,
  }) async {
    final existingNodesSummary = existingNodes
        .take(15)
        .map((n) => '- [${n.id}] "${n.label}" (${n.category.name}): ${n.summary}')
        .join('\n');

    final isInitialTopic = rootTopic.trim().isEmpty ||
        rootTopic.toLowerCase().contains('listening for') ||
        rootTopic.toLowerCase().contains('zero trust');

    final systemInstruction = '''
You are Thinkly's Academic Knowledge Graph Architect.
Analyze incoming live lecture speech and construct structured mind map nodes without missing ANY point.
Output ONLY valid JSON adhering strictly to:
{
  "detectedTopic": ${isInitialTopic ? '"Specific Subject extracted from speech"' : 'null'},
  "detectedTopicSummary": ${isInitialTopic ? '"1-sentence core thesis statement"' : 'null'},
  "transcript": "$transcriptChunk",
  "actions": [
    {
      "action": "add_node",
      "id": "unique_id",
      "title": "Concise Title (2-5 words)",
      "category": "core_concept" | "definition" | "example" | "question",
      "parentId": "existing_node_id_or_root",
      "summary": "1-2 sentence summary of what the professor explained",
      "keyPoints": [
        "Direct bullet point 1",
        "Underlying formula or rule",
        "Class application"
      ],
      "importance": 1 to 5,
      "isImportant": true or false
    },
    {
      "action": "connect_edge",
      "fromId": "parent_id",
      "toId": "child_id"
    }
  ]
}
Rules:
- Capture EVERY key concept, definition, formula, example, and teacher emphasis.
- HIERARCHICAL TREE RULE: If the lecturer discusses details, mechanisms, implementations, or examples of an existing concept node, attach it directly to that specific concept's node ID using "parentId"—DO NOT attach everything to root! Only set "parentId" to root when introducing a brand-new high-level topic.
- Connect new nodes to their specific parent node.
- STRICT RULE: If the speech segment contains no new educational insight, greetings, filler, or silence, return "actions": []. NEVER invent generic or dummy nodes.
''';

    final userPrompt = '''
Current Lecture Topic: "$rootTopic"
Existing Nodes:
$existingNodesSummary

New incoming transcript chunk from teacher:
"$transcriptChunk"

Extract the knowledge graph JSON now:
''';

    try {
      final jsonText = await _callGeminiApi(
        systemInstruction: systemInstruction,
        userPrompt: userPrompt,
        temperature: 0.3,
      );

      return _parseDeltaJson(jsonText, existingNodes);
    } catch (e) {
      debugPrint('[GeminiAiService] Extraction error: $e');
      return MindMapDeltaResult(
        actions: [],
        rawResponse: '{}',
        extractedTranscript: transcriptChunk,
      );
    }
  }

  /// 1C. Comprehensive Mind Map Generator for YouTube URL or Topic Input
  Future<MindMapDeltaResult> generateDeepMindMapForTopicOrUrl({
    required String topicOrUrl,
    required String rootId,
  }) async {
    final cleanTopic = topicOrUrl.replaceAll(RegExp(r'https?://[^\s]+'), '').trim();
    final topic = cleanTopic.isNotEmpty ? cleanTopic : topicOrUrl;

    final systemInstruction = '''
You are Thinkly's Academic Knowledge Graph Architect.
The student has provided a YouTube video or lecture topic: "$topic".
Generate a deep, comprehensive, structured Mind Map for this topic.
Cover core theoretical principles, key definitions, practical examples, architecture/mechanisms, common pitfalls, and high-yield exam takeaways.
Output ONLY valid JSON adhering strictly to:
{
  "transcript": "Deep knowledge blueprint synthesized for $topic",
  "actions": [
    {
      "action": "add_node",
      "id": "node_1",
      "title": "Clear Punchy Title (2-5 words)",
      "category": "core_concept" | "definition" | "example" | "question",
      "parentId": "$rootId",
      "summary": "1-2 sentence core mechanism or concept explanation",
      "keyPoints": [
        "Key foundational point",
        "Crucial technical nuance",
        "Exam-relevant takeaway"
      ],
      "importance": 1 to 5,
      "isImportant": true or false
    },
    {
      "action": "connect_edge",
      "fromId": "$rootId",
      "toId": "node_1"
    }
  ]
}
Generate between 5 to 7 interconnected, high-quality academic nodes branching from $rootId.
''';

    final userPrompt = 'Generate the complete mind map for "$topic" now:';

    try {
      final jsonText = await _callGeminiApi(
        systemInstruction: systemInstruction,
        userPrompt: userPrompt,
        temperature: 0.3,
      );
      return _parseDeltaJson(jsonText, []);
    } catch (e) {
      debugPrint('[GeminiAiService] Topic generation fallback for "$topic": $e');
      return _generateRichFallbackForTopic(topic, rootId);
    }
  }

  MindMapDeltaResult _generateRichFallbackForTopic(String topic, String rootId) {
    final actions = <MindMapDeltaAction>[];
    final id1 = 'topic_sub_${_uuid.v4().substring(0, 6)}';
    final id2 = 'topic_sub_${_uuid.v4().substring(0, 6)}';
    final id3 = 'topic_sub_${_uuid.v4().substring(0, 6)}';
    final id4 = 'topic_sub_${_uuid.v4().substring(0, 6)}';
    final id5 = 'topic_sub_${_uuid.v4().substring(0, 6)}';

    actions.add(MindMapDeltaAction(
      action: 'add_node',
      node: MindMapNode(
        id: id1,
        parentId: rootId,
        label: 'Core Theoretical Foundations',
        summary: 'Primary axioms, mathematical/architectural models, and governance rules underpinning $topic.',
        category: NodeCategory.coreConcept,
        keyPoints: [
          'First-principles taxonomy and abstraction layers',
          'Invariant constraints and system properties',
          'Standard collegiate exam formulation',
        ],
        importance: 5,
        isKeyTakeaway: true,
      ),
    ));
    actions.add(MindMapDeltaAction(action: 'connect_edge', edge: MindMapEdge(fromId: rootId, toId: id1)));

    actions.add(MindMapDeltaAction(
      action: 'add_node',
      node: MindMapNode(
        id: id2,
        parentId: rootId,
        label: 'Formal Definitions & Syntax',
        summary: 'Rigorous definitions, standard RFC/IEEE specifications, and domain terminology for $topic.',
        category: NodeCategory.definition,
        keyPoints: [
          'Precise operational definition and scope',
          'Disambiguation against legacy or adjacent paradigms',
        ],
        importance: 4,
      ),
    ));
    actions.add(MindMapDeltaAction(action: 'connect_edge', edge: MindMapEdge(fromId: rootId, toId: id2)));

    actions.add(MindMapDeltaAction(
      action: 'add_node',
      node: MindMapNode(
        id: id3,
        parentId: id1,
        label: 'Production Case Study & Telemetry',
        summary: 'Real-world deployment benchmark, latency trade-offs, and empirical edge cases in $topic.',
        category: NodeCategory.example,
        keyPoints: [
          'Measured throughput and scalability limits',
          'Observed failure modes under adversarial stress',
        ],
        importance: 3,
      ),
    ));
    actions.add(MindMapDeltaAction(action: 'connect_edge', edge: MindMapEdge(fromId: id1, toId: id3)));

    actions.add(MindMapDeltaAction(
      action: 'add_node',
      node: MindMapNode(
        id: id4,
        parentId: rootId,
        label: 'Diagnostic Questions & Edge Cases',
        summary: 'Complex theoretical edge cases, interview puzzles, and common architectural anti-patterns.',
        category: NodeCategory.question,
        keyPoints: [
          'What happens when network partition or state drift occurs?',
          'How does asymptotic complexity change at scale?',
        ],
        importance: 4,
      ),
    ));
    actions.add(MindMapDeltaAction(action: 'connect_edge', edge: MindMapEdge(fromId: rootId, toId: id4)));

    actions.add(MindMapDeltaAction(
      action: 'add_node',
      node: MindMapNode(
        id: id5,
        parentId: id2,
        label: 'High-Yield Exam Takeaway',
        summary: 'Essential formulas, proof outlines, and synthesis points guaranteed on exams.',
        category: NodeCategory.coreConcept,
        keyPoints: [
          'Critical trade-off matrix: consistency vs performance',
          'Professor high-frequency exam focus',
        ],
        importance: 5,
        isKeyTakeaway: true,
      ),
    ));
    actions.add(MindMapDeltaAction(action: 'connect_edge', edge: MindMapEdge(fromId: id2, toId: id5)));

    return MindMapDeltaResult(
      actions: actions,
      rawResponse: 'Fallback knowledge blueprint generated for $topic',
      extractedTranscript: 'Synthesized deep conceptual breakdown for $topic',
    );
  }

  /// 1D. Expand a Specific Node with Sub-Concepts
  Future<List<MindMapNode>> expandNodeWithAi(MindMapNode parentNode) async {
    const systemInstruction = '''
You are Thinkly's Academic Knowledge Graph Architect.
The student has selected a specific concept node to drill down deeper into:
Generate 2-3 high-value child nodes that reveal the underlying mechanics, concrete examples, or advanced edge cases.
Output ONLY valid JSON:
{
  "children": [
    {
      "title": "Sub-concept title (2-4 words)",
      "category": "core_concept" | "definition" | "example" | "question",
      "summary": "1-2 sentence precise technical explanation",
      "keyPoints": [
        "Key implementation mechanism",
        "Mathematical or practical proof point"
      ],
      "importance": 1 to 5
    }
  ]
}
''';

    final userPrompt = '''
Parent Node: "${parentNode.label}" (${parentNode.category.displayName})
Summary: "${parentNode.summary}"
Key Points: ${parentNode.keyPoints.join(", ")}
''';

    try {
      final jsonText = await _callGeminiApi(
        systemInstruction: systemInstruction,
        userPrompt: userPrompt,
        temperature: 0.4,
      );

      var cleaned = jsonText.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);

      final parsed = jsonDecode(cleaned.trim()) as Map<String, dynamic>;
      final items = parsed['children'] as List<dynamic>? ?? [];

      return items.map((item) {
        final map = item as Map<String, dynamic>;
        final pts = (map['keyPoints'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        return MindMapNode(
          id: 'exp_${_uuid.v4().substring(0, 8)}',
          label: (map['title'] ?? map['label'])?.toString() ?? 'Sub-concept',
          summary: map['summary']?.toString() ?? '',
          category: NodeCategory.fromString(map['category']?.toString()),
          parentId: parentNode.id,
          keyPoints: pts,
          importance: (map['importance'] as num?)?.toInt() ?? 3,
        );
      }).toList();
    } catch (e) {
      debugPrint('[GeminiAiService] Fallback node expansion: $e');
      return [
        MindMapNode(
          id: 'exp_${_uuid.v4().substring(0, 8)}',
          label: 'Core Mechanism',
          summary: 'Detailed internal functioning of ${parentNode.label} in production systems.',
          category: NodeCategory.definition,
          parentId: parentNode.id,
          keyPoints: [
            'Underlying protocol state machine',
            'Latency & verification overhead guarantees'
          ],
          importance: 4,
        ),
        MindMapNode(
          id: 'exp_${_uuid.v4().substring(0, 8)}',
          label: 'Industrial Implementation',
          summary: 'How top technology teams apply ${parentNode.label} at scale.',
          category: NodeCategory.example,
          parentId: parentNode.id,
          keyPoints: [
            'Empirical case study deployment',
            'Failure-mode recovery strategy'
          ],
          importance: 4,
        ),
      ];
    }
  }

  /// 2. Comprehensive AI Lecture Study Guide Generator
  Future<String> generateStudyGuide({
    required String lectureTitle,
    required List<MindMapNode> nodes,
    required String transcriptHistory,
  }) async {
    final nodesDigest = nodes.map((n) {
      final noteStr = n.studentNote != null && n.studentNote!.isNotEmpty
          ? ' [Student Note: "${n.studentNote}"]'
          : '';
      final ptsStr = n.keyPoints.isNotEmpty
          ? '\n  Key points: ${n.keyPoints.join("; ")}'
          : '';
      return '- **${n.label}** (${n.category.displayName}): ${n.summary}$ptsStr$noteStr';
    }).join('\n');

    const systemInstruction = '''
You are Thinkly's world-class Academic Coach & Study Guide Generator.
Transform the provided mind map nodes, captured bullet points, and personal student notes into a rigorous, beautiful Markdown study guide.
Use this markdown structure:
# [Lecture Title] Master Study Guide

## 🎯 Executive Summary & Core Thesis
(3-4 sentences synthesizing the lecture's core proposition)

## 🧠 Key Concept Breakdown
(Bulleted list with bold terms, formulas, and precise explanations)

## 📇 Active Recall Flashcards
Format each card clearly:
**Q:** [Question]
**A:** [Answer]

## 📝 Integrated Student Field Notes & Insights
(Synthesizing the student's personal notes attached to nodes)

## ⚡ High-Yield Exam Questions
1. [Deep conceptual question]
2. [Applied scenario question]
''';

    final userPrompt = '''
Lecture Title: $lectureTitle

Extracted Knowledge Graph Nodes & Notes:
$nodesDigest

Transcript Excerpt:
${transcriptHistory.length > 1200 ? transcriptHistory.substring(0, 1200) : transcriptHistory}
''';

    try {
      final markdownResult = await _callGeminiApi(
        systemInstruction: systemInstruction,
        userPrompt: userPrompt,
        temperature: 0.3,
      );

      var text = markdownResult.trim();
      if (text.startsWith('```markdown')) text = text.substring(11);
      if (text.startsWith('```')) text = text.substring(3);
      if (text.endsWith('```')) text = text.substring(0, text.length - 3);
      return text.trim();
    } catch (e) {
      debugPrint('[GeminiAiService] Fallback study guide generator: $e');
      return _fallbackStudyGuide(lectureTitle, nodes);
    }
  }

  String _fallbackStudyGuide(String title, List<MindMapNode> nodes) {
    final buffer = StringBuffer();
    buffer.writeln('# $title — Comprehensive AI Study Guide\n');
    buffer.writeln('## 🎯 Executive Summary & Core Thesis');
    buffer.writeln(
      'This study session synthesizes foundational paradigms and key operational architectures covered in class. '
      'Understanding these principles provides the mental scaffolding required for upcoming examinations and real-world system design.\n',
    );

    buffer.writeln('## 🧠 Key Concept Breakdown');
    for (final node in nodes) {
      buffer.writeln('- **${node.label}** (`${node.category.displayName}`)');
      buffer.writeln('  ${node.summary}');
      for (final pt in node.keyPoints) {
        buffer.writeln('  - $pt');
      }
      if (node.studentNote != null && node.studentNote!.isNotEmpty) {
        buffer.writeln('  > 💡 *Student Reflection:* ${node.studentNote}');
      }
    }
    buffer.writeln('');

    buffer.writeln('## 📇 Active Recall Flashcards');
    for (var i = 0; i < nodes.take(4).length; i++) {
      final n = nodes[i];
      buffer.writeln('**Q${i + 1}:** What constitutes the core operational logic of **${n.label}**?');
      buffer.writeln('**A:** ${n.summary}\n');
    }

    buffer.writeln('## ⚡ High-Yield Exam Questions');
    buffer.writeln('1. How does modern architecture diverge from legacy assumptions when scaling this model?');
    buffer.writeln('2. Identify two failure modes under adversarial or unexpected systemic strain.');

    return buffer.toString();
  }

  MindMapDeltaResult _parseDeltaJson(String rawJson, List<MindMapNode> existingNodes) {
    try {
      var cleaned = rawJson.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      final actionsList = parsed['actions'] as List<dynamic>? ?? [];
      final extractedTranscript = parsed['transcript']?.toString();
      final rawTopic = parsed['detectedTopic']?.toString();
      final rawSummary = parsed['detectedTopicSummary']?.toString();
      final detectedTopic = (rawTopic != null && rawTopic.trim().isNotEmpty && rawTopic.toLowerCase() != 'null')
          ? rawTopic.trim()
          : null;
      final detectedTopicSummary = (rawSummary != null && rawSummary.trim().isNotEmpty && rawSummary.toLowerCase() != 'null')
          ? rawSummary.trim()
          : null;

      final existingNodeIds = {for (var n in existingNodes) n.id};
      final actions = <MindMapDeltaAction>[];

      for (final rawAction in actionsList) {
        final map = rawAction as Map<String, dynamic>;
        final actionType = map['action']?.toString() ?? 'add_node';

        if (actionType == 'add_node') {
          var rawId = map['id']?.toString() ?? '';
          if (rawId.isEmpty || existingNodeIds.contains(rawId)) {
            rawId = 'node_${_uuid.v4().substring(0, 8)}';
          }
          existingNodeIds.add(rawId);

          final label = (map['title'] ?? map['label'])?.toString() ?? 'Concept';
          final summary = map['summary']?.toString() ?? '';
          final categoryStr = map['category']?.toString();
          final category = NodeCategory.fromString(categoryStr);
          final parentId = map['parentId']?.toString();
          final keyPoints = (map['keyPoints'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          final importance = (map['importance'] as num?)?.toInt() ?? 3;
          final isImportant = (map['isImportant'] ?? map['isKeyTakeaway']) as bool? ?? (importance >= 4);

          final node = MindMapNode(
            id: rawId,
            label: label,
            summary: summary,
            category: category,
            parentId: parentId,
            keyPoints: keyPoints,
            importance: importance,
            isKeyTakeaway: isImportant,
          );

          actions.add(MindMapDeltaAction(
            action: 'add_node',
            node: node,
            targetNodeId: rawId,
          ));
        } else if (actionType == 'connect_edge') {
          final fromId = map['fromId']?.toString();
          final toId = map['toId']?.toString();
          if (fromId != null && toId != null && fromId != toId) {
            actions.add(MindMapDeltaAction(
              action: 'connect_edge',
              edge: MindMapEdge(fromId: fromId, toId: toId),
            ));
          }
        } else if (actionType == 'tag_important') {
          final targetId = map['targetNodeId']?.toString() ?? map['id']?.toString();
          if (targetId != null) {
            actions.add(MindMapDeltaAction(
              action: 'tag_important',
              targetNodeId: targetId,
            ));
          }
        }
      }

      return MindMapDeltaResult(
        actions: actions,
        rawResponse: rawJson,
        extractedTranscript: extractedTranscript,
        detectedTopic: detectedTopic,
        detectedTopicSummary: detectedTopicSummary,
      );
    } catch (e) {
      debugPrint('[GeminiAiService] Error parsing delta JSON: $e');
      return MindMapDeltaResult(
        actions: [],
        rawResponse: rawJson,
      );
    }
  }
}
