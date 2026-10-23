import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/gemini_service.dart';
import '../../../core/services/speech_service.dart';
import '../../../core/services/web_interop.dart';
import '../../../core/services/pdf_notes_service.dart';
import '../models/mind_map_node.dart';
import '../models/mind_map_edge.dart';
import '../models/lecture_session.dart';

class MindMapProvider extends ChangeNotifier {
  final GeminiAiService _gemini = GeminiAiService();
  final SpeechService _speechService = SpeechService();
  final WebInteropService _webInterop = WebInteropService();
  final PdfNotesService _pdfNotesService = PdfNotesService();
  final _uuid = const Uuid();

  static const String _savedLecturesKey = 'thinkly_saved_lectures';

  late LectureSession _currentSession;
  MindMapNode? _selectedNode;
  String? _activeNodeId;
  bool _isExtracting = false;
  bool _isGeneratingStudyGuide = false;
  bool _isGeneratingPdf = false;
  bool _isPipArmed = true;
  bool _isAutoTitlingRoot = false;
  List<LectureSession> _savedLectures = [];

  StreamSubscription? _transcriptSubscription;
  StreamSubscription? _tabAudioSubscription;
  StreamSubscription? _pipQuickNoteSubscription;
  StreamSubscription? _pipFlagSubscription;
  StreamSubscription? _pipExpandSubscription;
  StreamSubscription? _pipSwitchSubscription;
  StreamSubscription? _pipPauseResumeSubscription;

  LectureSession get currentSession => _currentSession;
  List<MindMapNode> get nodes => _currentSession.nodes;
  List<MindMapEdge> get edges => _currentSession.edges;
  MindMapNode? get selectedNode => _selectedNode;
  String? get activeNodeId => _activeNodeId;
  bool get isExtracting => _isExtracting;
  bool get isGeneratingStudyGuide => _isGeneratingStudyGuide;
  bool get isGeneratingPdf => _isGeneratingPdf;
  bool get isPipArmed => _isPipArmed;
  List<LectureSession> get savedLectures => _savedLectures;

  MindMapProvider() {
    _initNewLecture('Zero Trust Architecture & Enterprise Defense');
    _loadSavedLectures();
    _bindServices();
    _webInterop.setPipArmed(true);
  }

  void _bindServices() {
    // Listen for incoming transcript chunks from SpeechService (mic / simulation)
    _transcriptSubscription = _speechService.onTranscriptChunk.listen((chunk) {
      if (chunk.trim().isNotEmpty) {
        processTranscriptChunk(chunk);
      }
    });

    // Listen for YouTube / Google Meet tab audio chunk events
    _tabAudioSubscription = _speechService.onTabAudioChunk.listen((chunkData) {
      final base64Audio = chunkData['base64Audio']?.toString() ?? '';
      final mimeType = chunkData['mimeType']?.toString() ?? 'audio/webm';
      if (base64Audio.isNotEmpty) {
        processTabAudioChunk(base64Audio, mimeType);
      }
    });

    // Listen for Quick Note sent from PiP window
    _pipQuickNoteSubscription = _webInterop.onPipQuickNote.listen((note) {
      if (note.trim().isNotEmpty) {
        addStudentNoteToLatestNode(note.trim());
      }
    });

    // Listen for Flag button clicked in PiP window
    _pipFlagSubscription = _webInterop.onPipFlag.listen((_) {
      flagLatestNodeAsImportant();
    });

    // Listen for Expand Node clicked in PiP window
    _pipExpandSubscription = _webInterop.onPipExpand.listen((_) {
      if (_currentSession.nodes.isNotEmpty) {
        final target = _selectedNode ?? _currentSession.nodes.last;
        expandNodeWithAi(target.id);
      }
    });

    // Listen for Switch Session clicked in PiP dropdown
    _pipSwitchSubscription = _webInterop.onPipSwitchSession.listen((sessionId) {
      if (sessionId.isNotEmpty) {
        switchToLectureById(sessionId);
      }
    });

    // Listen for Pause/Resume clicked in PiP window
    _pipPauseResumeSubscription = _webInterop.onPipPauseResume.listen((_) {
      _speechService.togglePauseResume();
      _syncPipState();
    });
  }

  Future<void> openExternalPip() async {
    final latest = _currentSession.nodes.isNotEmpty ? _currentSession.nodes.last.label : 'Topic';
    final importantCount = _currentSession.nodes.where((n) => n.isKeyTakeaway).length;

    String meetingBadge;
    if (_speechService.currentMode == SpeechMode.tabAudio) {
      meetingBadge = 'YouTube / Meet Tab Active';
    } else if (_speechService.currentMode == SpeechMode.liveMicrophone) {
      meetingBadge = 'Live Microphone Active';
    } else {
      meetingBadge = 'Simulated Lecture Feed';
    }

    await _webInterop.requestNativePip(
      isListening: _speechService.isListening,
      meetingBadge: meetingBadge,
      transcript: _speechService.activeTickerText,
      latestNode: latest,
      nodeCount: _currentSession.nodes.length,
      importantCount: importantCount,
    );
  }

  Future<void> generateFromYoutubeOrTopic(String urlOrTopic) async {
    final cleanTitle = urlOrTopic.replaceAll(RegExp(r'https?://[^\s]+'), '').trim();
    final topic = cleanTitle.isNotEmpty ? cleanTitle : urlOrTopic;
    _initNewLecture(topic.isEmpty ? 'Lecture Blueprint' : topic);

    _isExtracting = true;
    notifyListeners();

    try {
      final rootId = _currentSession.nodes.first.id;
      final result = await _gemini.generateDeepMindMapForTopicOrUrl(
        topicOrUrl: urlOrTopic,
        rootId: rootId,
      );
      _applyDelta(result);
    } catch (e) {
      debugPrint('[MindMapProvider] Error generating from YouTube/Topic: $e');
    } finally {
      _isExtracting = false;
      notifyListeners();
    }
  }

  void togglePipArmed() {
    _isPipArmed = !_isPipArmed;
    _webInterop.setPipArmed(_isPipArmed);
    notifyListeners();
  }

  void _initNewLecture(String topicTitle) {
    final rootId = 'root_${_uuid.v4().substring(0, 6)}';
    final isListeningTopic = topicTitle == 'Listening for Lecture Topic...';
    final rootNode = MindMapNode(
      id: rootId,
      label: topicTitle,
      summary: isListeningTopic
          ? 'Listening to live lecture audio stream to identify subject...'
          : 'Central architectural thesis and primary learning objective.',
      category: NodeCategory.root,
      keyPoints: isListeningTopic
          ? [
              'Waiting for lecturer speech...',
              'Real-time concept tree extraction active',
            ]
          : [
              'Mastering core foundations of $topicTitle',
              'Real-world implementation paradigms and architectural blueprints',
            ],
      x: 0,
      y: 0,
      importance: 5,
      isKeyTakeaway: true,
    );

    _currentSession = LectureSession(
      id: 'lec_${_uuid.v4()}',
      title: topicTitle,
      nodes: [rootNode],
      edges: [],
    );

    _selectedNode = rootNode;
    _activeNodeId = rootId;
    _recalculateLayout();
    _syncPipState();
    notifyListeners();
  }

  void startLiveLectureSession() {
    if (_currentSession.nodes.length > 1) {
      saveCurrentLecture();
    }
    _isAutoTitlingRoot = true;
    _initNewLecture('Listening for Lecture Topic...');
    _speechService.updateTicker('🎧 Initialized live lecture session • Listening for topic...');
    saveCurrentLecture();
  }

  void startNewLecture(String topicTitle) {
    if (_currentSession.nodes.length > 1) {
      saveCurrentLecture();
    }
    _isAutoTitlingRoot = false;
    _initNewLecture(topicTitle.trim().isEmpty ? 'Live Lecture Knowledge Map' : topicTitle.trim());
    saveCurrentLecture();
  }

  void createAndSwitchToNewLecture([String? title]) {
    startNewLecture(title ?? 'New Lecture Session');
  }

  void renameSession(String newTitle) {
    if (newTitle.trim().isEmpty) return;
    _currentSession.title = newTitle.trim();
    if (_currentSession.nodes.isNotEmpty && _currentSession.nodes.first.category == NodeCategory.root) {
      _currentSession.nodes.first.label = newTitle.trim();
    }
    _currentSession.lastModified = DateTime.now();
    _syncPipState();
    saveCurrentLecture();
    notifyListeners();
  }

  Future<void> processTranscriptChunk(String chunk) async {
    if (_isExtracting) return;
    _isExtracting = true;
    notifyListeners();

    _currentSession.transcriptHistory += ' $chunk';
    _currentSession.lastModified = DateTime.now();

    try {
      final delta = await _gemini.extractMindMapDelta(
        transcriptChunk: chunk,
        existingNodes: _currentSession.nodes,
        rootTopic: _currentSession.title,
      );

      // Auto-title root node and session when topic is detected
      final isRootPlaceholder = _isAutoTitlingRoot ||
          _currentSession.title == 'Listening for Lecture Topic...' ||
          (_currentSession.nodes.isNotEmpty &&
              _currentSession.nodes.first.label == 'Listening for Lecture Topic...');

      if (isRootPlaceholder &&
          delta.detectedTopic != null &&
          delta.detectedTopic!.trim().isNotEmpty &&
          delta.detectedTopic!.toLowerCase() != 'null') {
        final newTitle = delta.detectedTopic!.trim();
        final root = _currentSession.nodes.first;
        root.label = newTitle;
        if (delta.detectedTopicSummary != null &&
            delta.detectedTopicSummary!.trim().isNotEmpty &&
            delta.detectedTopicSummary!.toLowerCase() != 'null') {
          root.summary = delta.detectedTopicSummary!.trim();
        } else {
          root.summary = 'Primary lecture topic analyzed from live speech.';
        }
        root.keyPoints = [
          'Mastering core foundations of $newTitle',
          'Key concepts and principles extracted from lecture',
        ];
        _currentSession.title = newTitle;
        _isAutoTitlingRoot = false;
        saveCurrentLecture();
        _speechService.updateTicker('🎯 Identified Lecture Topic: "$newTitle"');
      }

      if (delta.actions.isEmpty) {
        _speechService.updateTicker('🎧 Transcribed: "$chunk"');
      } else {
        _applyDelta(delta);
      }
    } catch (e) {
      debugPrint('[MindMapProvider] Error processing transcript: $e');
    } finally {
      _isExtracting = false;
      notifyListeners();
    }
  }

  Future<void> processTabAudioChunk(String base64Audio, String mimeType) async {
    if (_isExtracting) return;
    _isExtracting = true;
    notifyListeners();

    try {
      final result = await _gemini.extractMindMapDeltaFromAudio(
        base64Audio: base64Audio,
        mimeType: mimeType,
        existingNodes: _currentSession.nodes,
        rootTopic: _currentSession.title,
      );

      final transcript = result.extractedTranscript ?? '';
      if (transcript.isNotEmpty) {
        _currentSession.transcriptHistory += ' $transcript';
      }

      final isRootPlaceholder = _isAutoTitlingRoot ||
          _currentSession.title == 'Listening for Lecture Topic...' ||
          (_currentSession.nodes.isNotEmpty &&
              _currentSession.nodes.first.label == 'Listening for Lecture Topic...');

      if (isRootPlaceholder &&
          result.detectedTopic != null &&
          result.detectedTopic!.trim().isNotEmpty &&
          result.detectedTopic!.toLowerCase() != 'null') {
        final newTitle = result.detectedTopic!.trim();
        final root = _currentSession.nodes.first;
        root.label = newTitle;
        if (result.detectedTopicSummary != null &&
            result.detectedTopicSummary!.trim().isNotEmpty &&
            result.detectedTopicSummary!.toLowerCase() != 'null') {
          root.summary = result.detectedTopicSummary!.trim();
        } else {
          root.summary = 'Primary lecture topic analyzed from live speech.';
        }
        root.keyPoints = [
          'Mastering core foundations of $newTitle',
          'Key concepts and principles extracted from lecture',
        ];
        _currentSession.title = newTitle;
        _isAutoTitlingRoot = false;
        saveCurrentLecture();
        _speechService.updateTicker('🎯 Identified Lecture Topic: "$newTitle"');
      }

      if (result.actions.isEmpty) {
        if (transcript.isNotEmpty) {
          _speechService.updateTicker('🎧 Transcribed: "$transcript"');
        } else {
          _speechService.updateTicker('🎧 Audio captured • Waiting for lecture speech...');
        }
      } else {
        _applyDelta(result);
      }
    } catch (e) {
      debugPrint('[MindMapProvider] Error processing tab audio: $e');
      _speechService.updateTicker('⚠️ Audio processing note: $e');
    } finally {
      _isExtracting = false;
      notifyListeners();
    }
  }

  void _applyDelta(MindMapDeltaResult delta) {
    String? latestAddedNodeId;
    String? latestNodeTitle;
    String? parentTitle;

    for (final action in delta.actions) {
      if (action.action == 'add_node' && action.node != null) {
        final newNode = action.node!;
        latestAddedNodeId = newNode.id;
        latestNodeTitle = newNode.label;

        if (!_currentSession.nodes.any((n) => n.id == newNode.id)) {
          _currentSession.nodes.add(newNode);
          if (newNode.parentId != null) {
            final parent = _currentSession.nodes.firstWhere(
              (n) => n.id == newNode.parentId,
              orElse: () => _currentSession.nodes.first,
            );
            parentTitle = parent.label;
            if (!parent.childIds.contains(newNode.id)) {
              parent.childIds.add(newNode.id);
            }
            final edgeExists = _currentSession.edges.any(
              (e) => e.fromId == parent.id && e.toId == newNode.id,
            );
            if (!edgeExists) {
              _currentSession.edges.add(MindMapEdge(fromId: parent.id, toId: newNode.id));
            }
          }
        }
      } else if (action.action == 'connect_edge' && action.edge != null) {
        final edge = action.edge!;
        if (!_currentSession.edges.contains(edge)) {
          _currentSession.edges.add(edge);
        }
      } else if (action.action == 'tag_important' && action.targetNodeId != null) {
        final target = _currentSession.nodes.where((n) => n.id == action.targetNodeId);
        if (target.isNotEmpty) {
          target.first.isKeyTakeaway = true;
          target.first.importance = 5;
        }
      }
    }

    if (latestAddedNodeId != null) {
      _activeNodeId = latestAddedNodeId;
      if (latestNodeTitle != null) {
        if (parentTitle != null) {
          _speechService.updateTicker('✨ Added "$latestNodeTitle" under "$parentTitle"');
        } else {
          _speechService.updateTicker('✨ Live Focus: "$latestNodeTitle"');
        }
      }
    }

    _recalculateLayout();
    _syncPipState();
    saveCurrentLecture();
    notifyListeners();
  }

  void addManualNode({
    required String title,
    required NodeCategory category,
    String? parentId,
    String? summary,
    List<String>? keyPoints,
    bool isKeyTakeaway = false,
  }) {
    final pId = parentId ?? (_selectedNode?.id ?? _activeNodeId ?? (_currentSession.nodes.isNotEmpty ? _currentSession.nodes.first.id : null));
    final newNode = MindMapNode(
      id: 'node_${_uuid.v4().substring(0, 8)}',
      parentId: pId,
      label: title,
      summary: summary ?? 'Custom student-added concept node.',
      category: category,
      keyPoints: keyPoints ?? [title],
      isKeyTakeaway: isKeyTakeaway,
      importance: isKeyTakeaway ? 5 : 3,
    );

    _currentSession.nodes.add(newNode);
    if (pId != null) {
      final parent = _currentSession.nodes.firstWhere(
        (n) => n.id == pId,
        orElse: () => _currentSession.nodes.first,
      );
      if (!parent.childIds.contains(newNode.id)) {
        parent.childIds.add(newNode.id);
      }
      _currentSession.edges.add(MindMapEdge(fromId: pId, toId: newNode.id));
    }

    _selectedNode = newNode;
    _activeNodeId = newNode.id;
    _recalculateLayout();
    _syncPipState();
    saveCurrentLecture();
    notifyListeners();
  }

  void selectNode(MindMapNode? node) {
    _selectedNode = node;
    if (node != null) {
      _activeNodeId = node.id;
    }
    notifyListeners();
  }

  void updateNodeStudentNote(String nodeId, String note) {
    final idx = _currentSession.nodes.indexWhere((n) => n.id == nodeId);
    if (idx != -1) {
      _currentSession.nodes[idx].studentNote = note;
      _currentSession.lastModified = DateTime.now();
      saveCurrentLecture();
      notifyListeners();
    }
  }

  void addStudentNoteToActiveNode(String note) {
    if (_currentSession.nodes.isEmpty || note.trim().isEmpty) return;
    final targetId = _selectedNode?.id ?? _activeNodeId ?? _currentSession.nodes.last.id;
    final idx = _currentSession.nodes.indexWhere((n) => n.id == targetId);
    if (idx != -1) {
      final target = _currentSession.nodes[idx];
      final existing = target.studentNote?.trim() ?? '';
      target.studentNote = existing.isEmpty ? '• ${note.trim()}' : '$existing\n• ${note.trim()}';
      _currentSession.lastModified = DateTime.now();
      _syncPipState();
      saveCurrentLecture();
      notifyListeners();
    }
  }

  void addStudentNoteToLatestNode(String note) {
    addStudentNoteToActiveNode(note);
  }

  void flagLatestNodeAsImportant() {
    if (_currentSession.nodes.isEmpty) return;
    final target = _selectedNode ?? _currentSession.nodes.firstWhere(
      (n) => n.id == _activeNodeId,
      orElse: () => _currentSession.nodes.last,
    );
    target.isKeyTakeaway = true;
    target.importance = 5;
    _syncPipState();
    saveCurrentLecture();
    notifyListeners();
  }

  void toggleNodeImportance(String nodeId) {
    final idx = _currentSession.nodes.indexWhere((n) => n.id == nodeId);
    if (idx != -1) {
      final node = _currentSession.nodes[idx];
      node.isKeyTakeaway = !node.isKeyTakeaway;
      node.importance = node.isKeyTakeaway ? 5 : 3;
      _syncPipState();
      saveCurrentLecture();
      notifyListeners();
    }
  }

  void toggleNodeCollapsed(String nodeId) {
    final idx = _currentSession.nodes.indexWhere((n) => n.id == nodeId);
    if (idx != -1) {
      _currentSession.nodes[idx].isCollapsed = !_currentSession.nodes[idx].isCollapsed;
      _recalculateLayout();
      notifyListeners();
    }
  }

  Future<void> expandNodeWithAi(String nodeId) async {
    final idx = _currentSession.nodes.indexWhere((n) => n.id == nodeId);
    if (idx == -1) return;
    final parent = _currentSession.nodes[idx];

    _isExtracting = true;
    notifyListeners();

    try {
      final subNodes = await _gemini.expandNodeWithAi(parent);

      for (final sub in subNodes) {
        _currentSession.nodes.add(sub);
        parent.childIds.add(sub.id);
        _currentSession.edges.add(MindMapEdge(fromId: parent.id, toId: sub.id));
      }

      _recalculateLayout();
      _syncPipState();
    } catch (e) {
      debugPrint('[MindMapProvider] Expand node error: $e');
    } finally {
      _isExtracting = false;
      notifyListeners();
    }
  }

  void deleteNode(String nodeId) {
    final node = _currentSession.nodes.firstWhere((n) => n.id == nodeId, orElse: () => _currentSession.nodes.first);
    if (node.category == NodeCategory.root) return;

    _currentSession.nodes.removeWhere((n) => n.id == nodeId);
    _currentSession.edges.removeWhere((e) => e.fromId == nodeId || e.toId == nodeId);

    for (final n in _currentSession.nodes) {
      n.childIds.remove(nodeId);
    }

    if (_selectedNode?.id == nodeId) {
      _selectedNode = _currentSession.nodes.isNotEmpty ? _currentSession.nodes.first : null;
    }

    _recalculateLayout();
    _syncPipState();
    notifyListeners();
  }

  Future<String> generateStudyGuide() async {
    _isGeneratingStudyGuide = true;
    notifyListeners();

    try {
      final guide = await _gemini.generateStudyGuide(
        lectureTitle: _currentSession.title,
        nodes: _currentSession.nodes,
        transcriptHistory: _currentSession.transcriptHistory,
      );
      _currentSession.aiStudyGuide = guide;
      await saveCurrentLecture();
      return guide;
    } finally {
      _isGeneratingStudyGuide = false;
      notifyListeners();
    }
  }

  /// PDF Notes Export
  Future<void> exportPdfNotes({String? customSummary}) async {
    _isGeneratingPdf = true;
    notifyListeners();
    try {
      await _pdfNotesService.printOrExportPdf(_currentSession, customSummary);
    } finally {
      _isGeneratingPdf = false;
      notifyListeners();
    }
  }

  /// Share or direct download PDF
  Future<void> sharePdfNotes({String? customSummary}) async {
    _isGeneratingPdf = true;
    notifyListeners();
    try {
      await _pdfNotesService.sharePdf(_currentSession, customSummary);
    } finally {
      _isGeneratingPdf = false;
      notifyListeners();
    }
  }

  // --- Left-to-Right Hierarchical Tree Layout Algorithm ---
  void _recalculateLayout() {
    if (_currentSession.nodes.isEmpty) return;

    final root = _currentSession.nodes.firstWhere(
      (n) => n.category == NodeCategory.root,
      orElse: () => _currentSession.nodes.first,
    );

    final childrenMap = <String, List<MindMapNode>>{};
    final visited = <String>{};

    for (final node in _currentSession.nodes) {
      if (node.id != root.id && node.parentId != null) {
        childrenMap.putIfAbsent(node.parentId!, () => []).add(node);
      }
    }

    double computeSubtreeHeight(MindMapNode node) {
      if (node.isCollapsed) return 155.0;
      final children = childrenMap[node.id] ?? [];
      if (children.isEmpty) return 155.0;

      double total = 0;
      for (final child in children) {
        total += computeSubtreeHeight(child);
      }
      return math.max(155.0, total);
    }

    void layoutNode(MindMapNode node, double x, double topY) {
      visited.add(node.id);
      node.x = x;
      final nodeHeight = computeSubtreeHeight(node);

      final children = childrenMap[node.id] ?? [];
      if (children.isEmpty || node.isCollapsed) {
        node.y = topY + (nodeHeight / 2);
        return;
      }

      double currentY = topY;
      for (final child in children) {
        final childHeight = computeSubtreeHeight(child);
        layoutNode(child, x + 310.0, currentY);
        currentY += childHeight;
      }

      if (children.isNotEmpty) {
        node.y = (children.first.y + children.last.y) / 2;
      } else {
        node.y = topY + (nodeHeight / 2);
      }
    }

    const rootX = -420.0;
    final totalTreeHeight = computeSubtreeHeight(root);
    layoutNode(root, rootX, -totalTreeHeight / 2);

    var orphanY = (totalTreeHeight / 2) + 120.0;
    for (final node in _currentSession.nodes) {
      if (!visited.contains(node.id)) {
        node.x = 0.0;
        node.y = orphanY;
        orphanY += 155.0;
      }
    }
  }

  // --- PiP Sync ---
  void _syncPipState() {
    final latest = _currentSession.nodes.isNotEmpty ? _currentSession.nodes.last.label : 'Topic';
    final importantCount = _currentSession.nodes.where((n) => n.isKeyTakeaway).length;

    String meetingBadge;
    if (_speechService.currentMode == SpeechMode.tabAudio) {
      meetingBadge = 'Google Meet Audio Active';
    } else if (_speechService.currentMode == SpeechMode.liveMicrophone) {
      meetingBadge = 'Live Microphone Active';
    } else {
      meetingBadge = 'Simulated Lecture Feed';
    }

    _webInterop.updatePipState(
      isListening: _speechService.isListening,
      meetingBadge: meetingBadge,
      transcript: _speechService.activeTickerText,
      latestNode: latest,
      nodeCount: _currentSession.nodes.length,
      importantCount: importantCount,
    );

    final allLectures = <Map<String, dynamic>>[
      {
        'id': _currentSession.id,
        'title': _currentSession.title.isNotEmpty ? _currentSession.title : 'Current Lecture Map',
        'active': true,
      },
      ..._savedLectures
          .where((s) => s.id != _currentSession.id)
          .map((s) => {
                'id': s.id,
                'title': s.title.isNotEmpty ? s.title : 'Saved Lecture',
                'active': false,
              }),
    ];
    _webInterop.updatePipLectures(allLectures, _currentSession.id);
  }

  void moveNode(String nodeId, Offset delta) {
    final idx = _currentSession.nodes.indexWhere((n) => n.id == nodeId);
    if (idx != -1) {
      final node = _currentSession.nodes[idx];
      node.x = (node.x + delta.dx).clamp(-1900.0, 1900.0);
      node.y = (node.y + delta.dy).clamp(-1900.0, 1900.0);
      notifyListeners();
    }
  }

  void switchToLectureById(String sessionId) {
    if (sessionId == _currentSession.id) return;
    final target = _savedLectures.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => _currentSession,
    );
    if (target.id != _currentSession.id) {
      loadLecture(target);
    }
  }

  Future<void> _loadSavedLectures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_savedLecturesKey) ?? [];
      _savedLectures = list.map((jsonStr) => LectureSession.fromJsonString(jsonStr)).toList();
      notifyListeners();
      _syncPipState();
    } catch (e) {
      debugPrint('[MindMapProvider] Error loading saved lectures: $e');
    }
  }

  Future<void> saveCurrentLecture() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentSession.lastModified = DateTime.now();

      final existingIdx = _savedLectures.indexWhere((s) => s.id == _currentSession.id);
      if (existingIdx != -1) {
        _savedLectures[existingIdx] = _currentSession;
      } else {
        _savedLectures.insert(0, _currentSession);
      }

      final jsonList = _savedLectures.map((s) => s.toJsonString()).toList();
      await prefs.setStringList(_savedLecturesKey, jsonList);
      notifyListeners();
      _syncPipState();
    } catch (e) {
      debugPrint('[MindMapProvider] Error saving lecture: $e');
    }
  }

  void loadLecture(LectureSession session) {
    _currentSession = session;
    _selectedNode = session.nodes.isNotEmpty ? session.nodes.first : null;
    _activeNodeId = _selectedNode?.id;
    _recalculateLayout();
    _syncPipState();
    notifyListeners();
  }

  Future<void> deleteSavedLecture(String id) async {
    try {
      _savedLectures.removeWhere((s) => s.id == id);
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _savedLectures.map((s) => s.toJsonString()).toList();
      await prefs.setStringList(_savedLecturesKey, jsonList);
      notifyListeners();
      _syncPipState();
    } catch (e) {
      debugPrint('[MindMapProvider] Error deleting lecture: $e');
    }
  }

  @override
  void dispose() {
    _transcriptSubscription?.cancel();
    _tabAudioSubscription?.cancel();
    _pipQuickNoteSubscription?.cancel();
    _pipFlagSubscription?.cancel();
    _pipExpandSubscription?.cancel();
    _pipSwitchSubscription?.cancel();
    _pipPauseResumeSubscription?.cancel();
    super.dispose();
  }
}
