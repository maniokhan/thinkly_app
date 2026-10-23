import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/lecture_data.dart';
import 'web_interop.dart';

enum SpeechMode {
  tabAudio,        // Google Meet / Class / YouTube Tab Audio
  liveMicrophone,  // In-person Classroom Microphone
  simulation,      // Simulated Live Class Demo
}

class SpeechService extends ChangeNotifier {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final WebInteropService _webInterop = WebInteropService();

  SpeechMode _currentMode = SpeechMode.simulation; // Default to simulation for instant demoability
  bool _isListening = false;
  String _currentInterimText = '';
  String _lastFinalText = '';
  String _activeTickerText = 'Ready to capture lecture audio...';

  // Simulation state
  SimulatedLecture _selectedLecture = kSimulatedLectures.first;
  int _simulationChunkIndex = 0;
  Timer? _simulationTimer;
  bool _autoSimulation = true;

  // Streams
  final _chunkStreamController = StreamController<String>.broadcast();
  Stream<String> get onTranscriptChunk => _chunkStreamController.stream;

  final _tabAudioChunkController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onTabAudioChunk => _tabAudioChunkController.stream;

  final _tickerStreamController = StreamController<String>.broadcast();
  Stream<String> get onLiveTicker => _tickerStreamController.stream;

  SpeechMode get currentMode => _currentMode;
  bool get isListening => _isListening;
  String get activeTickerText => _activeTickerText;
  String get currentInterimText => _currentInterimText;
  String get lastFinalText => _lastFinalText;
  SimulatedLecture get selectedLecture => _selectedLecture;
  int get simulationChunkIndex => _simulationChunkIndex;
  bool get isAutoSimulating => _autoSimulation;

  double _audioVolume = 0.0;
  double get audioVolume => _audioVolume;

  int _captureElapsedSeconds = 0;
  int get captureElapsedSeconds => _captureElapsedSeconds;
  Timer? _elapsedTickerTimer;

  String get activeSharingSourceTitle {
    if (!_isListening) return 'Audio Inactive';
    switch (_currentMode) {
      case SpeechMode.tabAudio:
        return 'YouTube / Google Meet Tab Audio';
      case SpeechMode.liveMicrophone:
        return 'Classroom Live Microphone';
      case SpeechMode.simulation:
        return '${_selectedLecture.topic} (Demo)';
    }
  }

  void initialize() {
    _webInterop.initialize();

    _webInterop.onSpeechResult.listen((data) {
      final interim = data['interim']?.toString() ?? '';
      final finalText = data['final']?.toString() ?? '';
      final isFinal = data['isFinal'] == true;

      if (interim.isNotEmpty) {
        _currentInterimText = interim;
        _activeTickerText = interim;
        _tickerStreamController.add(interim);
        notifyListeners();
      }

      if (isFinal && finalText.trim().isNotEmpty) {
        _lastFinalText = finalText.trim();
        _activeTickerText = _lastFinalText;
        _chunkStreamController.add(_lastFinalText);
        _tickerStreamController.add(_lastFinalText);
        _currentInterimText = '';
        notifyListeners();
      }
    });

    _webInterop.onSpeechError.listen((errMsg) {
      debugPrint('[SpeechService] Speech error: $errMsg');
      _activeTickerText = 'Speech note: $errMsg';
      notifyListeners();
    });

    _webInterop.onTabAudioChunk.listen((chunkData) {
      _tabAudioChunkController.add(chunkData);
    });

    _webInterop.onTabAudioStatus.listen((isRecording) {
      if (isRecording) {
        _activeTickerText = 'Capturing YouTube / Meet / Class Audio...';
      } else {
        _activeTickerText = 'Tab audio stream inactive.';
      }
      notifyListeners();
    });

    _webInterop.onAudioVolume.listen((vol) {
      _audioVolume = vol;
      notifyListeners();
    });

    _webInterop.onPipPauseResume.listen((_) {
      toggleListening();
    });
  }

  void updateTicker(String text) {
    if (text.trim().isNotEmpty) {
      _activeTickerText = text.trim();
      _tickerStreamController.add(_activeTickerText);
      notifyListeners();
    }
  }

  void setMode(SpeechMode mode) {
    if (_currentMode == mode) return;
    stopListening();
    _currentMode = mode;
    if (_currentMode == SpeechMode.simulation) {
      _activeTickerText = 'Simulated Mode: ${_selectedLecture.topic}';
    } else if (_currentMode == SpeechMode.tabAudio) {
      _activeTickerText = 'YouTube / Meet Audio: Click Start and share tab audio';
    } else {
      _activeTickerText = 'Live Mic Mode: Click Start to capture classroom audio';
    }
    notifyListeners();
  }

  void selectSimulatedLecture(SimulatedLecture lecture) {
    _selectedLecture = lecture;
    _simulationChunkIndex = 0;
    _activeTickerText = 'Selected Lecture: ${lecture.topic}';
    notifyListeners();
  }

  void startListening() {
    if (_isListening) return;
    _isListening = true;

    _captureElapsedSeconds = 0;
    _elapsedTickerTimer?.cancel();
    _elapsedTickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }
      _captureElapsedSeconds++;
      notifyListeners();
    });

    if (_currentMode == SpeechMode.tabAudio) {
      _activeTickerText = 'Prompting for YouTube / Google Meet tab audio stream...';
      _webInterop.startTabAudioCapture();
    } else if (_currentMode == SpeechMode.liveMicrophone) {
      _activeTickerText = 'Capturing live meeting / microphone speech...';
      _webInterop.startSpeechRecognition();
    } else {
      _activeTickerText = 'Simulating lecture stream (${_selectedLecture.course})...';
      if (_autoSimulation) {
        _startSimulationTimer();
      }
    }

    notifyListeners();
  }

  void stopListening() {
    if (!_isListening) return;
    _isListening = false;
    _elapsedTickerTimer?.cancel();
    _elapsedTickerTimer = null;
    _captureElapsedSeconds = 0;
    _audioVolume = 0.0;
    _simulationTimer?.cancel();
    _simulationTimer = null;

    if (_currentMode == SpeechMode.tabAudio) {
      _webInterop.stopTabAudioCapture();
    } else if (_currentMode == SpeechMode.liveMicrophone) {
      _webInterop.stopSpeechRecognition();
    }

    _isPaused = false;
    notifyListeners();
  }

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  void pauseListening() {
    if (!_isListening || _isPaused) return;
    _isPaused = true;
    _elapsedTickerTimer?.cancel();
    if (_currentMode == SpeechMode.tabAudio) {
      _webInterop.pauseTabAudioCapture();
    } else if (_currentMode == SpeechMode.liveMicrophone) {
      _webInterop.pauseSpeechRecognition();
    } else {
      _simulationTimer?.cancel();
    }
    _activeTickerText = 'Paused — Audio stream preserved';
    notifyListeners();
  }

  void resumeListening() {
    if (!_isListening || !_isPaused) return;
    _isPaused = false;
    _elapsedTickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isListening || _isPaused) {
        timer.cancel();
        return;
      }
      _captureElapsedSeconds++;
      notifyListeners();
    });

    if (_currentMode == SpeechMode.tabAudio) {
      _webInterop.resumeTabAudioCapture();
      _activeTickerText = 'Resumed live tab audio stream...';
    } else if (_currentMode == SpeechMode.liveMicrophone) {
      _webInterop.resumeSpeechRecognition();
      _activeTickerText = 'Resumed live microphone stream...';
    } else {
      _activeTickerText = 'Resumed simulation stream...';
      if (_autoSimulation) {
        _startSimulationTimer();
      }
    }
    notifyListeners();
  }

  void togglePauseResume() {
    if (_isPaused) {
      resumeListening();
    } else {
      pauseListening();
    }
  }

  void toggleListening() {
    if (_isListening) {
      stopListening();
    } else {
      startListening();
    }
  }

  void toggleAutoSimulation(bool enable) {
    _autoSimulation = enable;
    if (_autoSimulation && _isListening && _currentMode == SpeechMode.simulation) {
      _startSimulationTimer();
    } else {
      _simulationTimer?.cancel();
      _simulationTimer = null;
    }
    notifyListeners();
  }

  void _startSimulationTimer() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!_isListening || _currentMode != SpeechMode.simulation) {
        timer.cancel();
        return;
      }
      triggerNextSimulatedChunk();
    });
  }

  /// Manually or timer-driven trigger of the next chunk in the simulation
  void triggerNextSimulatedChunk() {
    if (_simulationChunkIndex >= _selectedLecture.transcriptChunks.length) {
      _simulationChunkIndex = 0;
    }

    final chunk = _selectedLecture.transcriptChunks[_simulationChunkIndex];
    _simulationChunkIndex++;

    _activeTickerText = chunk;
    _tickerStreamController.add(chunk);
    _chunkStreamController.add(chunk);

    notifyListeners();
  }

  void resetSimulation() {
    _simulationChunkIndex = 0;
    _activeTickerText = 'Simulation reset to beginning.';
    notifyListeners();
  }

  @override
  void dispose() {
    _elapsedTickerTimer?.cancel();
    _simulationTimer?.cancel();
    _chunkStreamController.close();
    _tabAudioChunkController.close();
    _tickerStreamController.close();
    super.dispose();
  }
}
