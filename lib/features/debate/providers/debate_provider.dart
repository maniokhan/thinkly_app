import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/config/app_config.dart';
import '../../../services/audio_service.dart';
import '../../../services/gemini_live_service.dart';
import '../../mascot/controllers/mascot_controller.dart';
import '../../mascot/models/character_model.dart';
import '../../mascot/models/mascot_emotion.dart';
import '../../mascot/models/mascot_state.dart';
import '../models/debate_difficulty.dart';
import '../models/debate_round.dart';
import '../models/debate_score.dart';
import '../models/debate_side.dart';
import '../models/debate_topic.dart';
import '../models/debate_turn.dart';

enum DebatePhase {
  idle,
  connecting,
  listening,
  thinking,
  speaking,
  interrupted,
  ended,
}

class DebateProvider extends ChangeNotifier {
  final AudioService audioService;
  final GeminiLiveService geminiService;
  final MascotController mascotController;

  DebateProvider({
    required this.audioService,
    required this.geminiService,
    required this.mascotController,
  }) {
    _initListeners();
  }

  // Setup state
  DebateTopic _selectedTopic = DebateTopic.presets.first;
  String _customTopicText = '';
  DebateSide _userSide = DebateSide.forStance;
  DebateDifficulty _difficulty = DebateDifficulty.medium;
  CharacterModel _selectedCharacter = CharacterModel.allCharacters.first;
  String _selectedVoice = 'Puck';
  DebateMode _debateMode = AppConfig.debateMode;

  // Live session state
  DebatePhase _phase = DebatePhase.idle;
  String _statusText = 'Ready to start';
  String? _errorMessage;
  double _liveAudioLevel = 0.0;
  bool _isMicMuted = false;
  bool _speakerTimeoutOccurred = false;

  // Structured Debate Rounds & Turn Timer
  DebateRound _currentRound = DebateRound.opening;
  int _roundRemainingSeconds = DebateRound.opening.durationSeconds;
  Timer? _roundCountdownTimer;

  // Adaptive noise floor & continuous speech gating
  bool _isCalibratingNoiseFloor = false;
  double _ambientNoiseFloor = 0.015;
  final List<double> _calibrationSamples = [];
  DateTime? _speechCandidateStart;
  bool _isUserSpeaking = false;
  Timer? _silenceTimer;
  static const Duration _silenceWaitDuration = Duration(milliseconds: 900);

  // Latency & performance tracking
  DateTime? _turnSubmittedTime;
  int? _lastTtfAudioMs;

  // Session stats & analytics
  final List<DebateTurn> _transcript = [];
  DebateScore? _lastScore;
  DateTime? _sessionStartTime;
  Timer? _sessionDurationTimer;
  Duration _sessionDuration = Duration.zero;
  int _interruptionCount = 0;
  int _turnsCount = 0;
  Timer? _inactivityTimer;
  Timer? _speakerCheckTimer;

  // Subscriptions
  StreamSubscription<double>? _inputAmpSub;
  StreamSubscription<double>? _outputAmpSub;

  // Getters
  DebateTopic get selectedTopic => _selectedTopic;
  String get customTopicText => _customTopicText;
  String get activeTopicTitle =>
      _customTopicText.trim().isNotEmpty ? _customTopicText.trim() : _selectedTopic.title;
  DebateSide get userSide => _userSide;
  DebateDifficulty get difficulty => _difficulty;
  CharacterModel get selectedCharacter => _selectedCharacter;
  String get selectedVoice => _selectedVoice;
  DebateMode get debateMode => _debateMode;

  DebatePhase get phase => _phase;
  String get statusText => _statusText;
  String? get errorMessage => _errorMessage;
  double get liveAudioLevel => _liveAudioLevel;
  bool get isMicMuted => _isMicMuted;
  bool get isUserSpeaking => _isUserSpeaking;
  bool get speakerTimeoutOccurred => _speakerTimeoutOccurred;

  DebateRound get currentRound => _currentRound;
  int get roundRemainingSeconds => _roundRemainingSeconds;
  int? get lastTtfAudioMs => _lastTtfAudioMs;
  double get ambientNoiseFloor => _ambientNoiseFloor;

  List<DebateTurn> get transcript => List.unmodifiable(_transcript);
  DebateScore? get lastScore => _lastScore;
  Duration get sessionDuration => _sessionDuration;
  int get interruptionCount => _interruptionCount;
  int get turnsCount => _turnsCount;

  void setSelectedTopic(DebateTopic topic) {
    _selectedTopic = topic;
    _customTopicText = '';
    notifyListeners();
  }

  void setCustomTopic(String text) {
    _customTopicText = text;
    notifyListeners();
  }

  void setUserSide(DebateSide side) {
    _userSide = side;
    notifyListeners();
  }

  void setDifficulty(DebateDifficulty diff) {
    _difficulty = diff;
    notifyListeners();
  }

  void setDebateMode(DebateMode mode) {
    _debateMode = mode;
    AppConfig.debateMode = mode;
    notifyListeners();
  }

  void setSelectedCharacter(CharacterModel char) {
    _selectedCharacter = char;
    _selectedVoice = char.defaultVoice;
    mascotController.setCharacter(char.name);
    notifyListeners();
  }

  void setSelectedVoice(String voice) {
    _selectedVoice = voice;
    notifyListeners();
  }

  void _initListeners() {
    // Microphone audio chunk forwarder
    audioService.onMicData = (chunk) {
      // In live debate, stream mic when user is speaking or listening
      if (_phase == DebatePhase.listening && !_isMicMuted) {
        geminiService.sendAudioChunk(chunk);
      }
    };

    // Incoming model audio chunk
    geminiService.onAudioReceived = (pcmChunk) async {
      _speakerCheckTimer?.cancel();
      _speakerCheckTimer = null;
      _speakerTimeoutOccurred = false;
      _resetInactivityTimer();
      _silenceTimer?.cancel();
      _silenceTimer = null;
      _isUserSpeaking = false;
      _speechCandidateStart = null;

      // Track TTFA (Time To First Audio)
      if (_turnSubmittedTime != null) {
        _lastTtfAudioMs = DateTime.now().difference(_turnSubmittedTime!).inMilliseconds;
        debugPrint('[Latency] Time-to-first-audio-byte: ${_lastTtfAudioMs}ms');
        _turnSubmittedTime = null;
      }

      if (_phase != DebatePhase.speaking) {
        _setPhase(DebatePhase.speaking, 'Opponent is countering...');
        mascotController.setState(MascotState.speaking);
      }
      await audioService.feedModelAudio(pcmChunk);
    };

    // Incoming model text transcript
    geminiService.onTranscriptReceived = (text) {
      _speakerCheckTimer?.cancel();
      _speakerCheckTimer = null;
      _speakerTimeoutOccurred = false;
      _resetInactivityTimer();
      _appendTranscriptChunk(Speaker.ai, text);
    };

    // Tool call: set_emotion
    geminiService.onEmotionReceived = (emotion) {
      _resetInactivityTimer();
      debugPrint('[DebateProvider] Opponent set emotion: $emotion');
      mascotController.setEmotion(emotion);
    };

    // Interrupted callback from server
    geminiService.onInterrupted = () {
      debugPrint('[DebateProvider] Server reported interruption signal.');
    };

    // Turn completed
    geminiService.onTurnCompleted = (complete) async {
      await audioService.flushJitterBuffer();
      audioService.prepareForNextTurn();

      _resetInactivityTimer();
      _silenceTimer?.cancel();
      _silenceTimer = null;
      _isUserSpeaking = false;
      _speechCandidateStart = null;
      _turnsCount++;
      debugPrint('[DebateProvider] AI Turn complete. Turn count: $_turnsCount');

      mascotController.setMouthLevel(0.0);
      _setPhase(DebatePhase.listening, 'Your turn · Speak or tap "Pass to AI"');
      mascotController.setState(MascotState.listening);

      // Check if we should advance the debate round
      _checkRoundProgression();
    };

    // Status changes
    geminiService.onStatusChanged = (status) {
      if (status == GeminiConnectionStatus.connecting) {
        _setPhase(DebatePhase.connecting, 'Warming up connection...');
        mascotController.setState(MascotState.waking);
      } else if (status == GeminiConnectionStatus.connected) {
        _setPhase(DebatePhase.speaking, 'Opponent is delivering opening argument...');
        mascotController.setState(MascotState.speaking);
        _startSpeakerCheckTimer();
      } else if (status == GeminiConnectionStatus.reconnecting) {
        _setPhase(DebatePhase.connecting, 'Reconnecting live stream...');
        mascotController.setState(MascotState.confused);
      }
    };

    // Error handling
    geminiService.onError = (msg) {
      _speakerCheckTimer?.cancel();
      _errorMessage = msg;
      _setPhase(DebatePhase.idle, msg);
      mascotController.setState(MascotState.confused);
      notifyListeners();
    };

    // Volume amplitude monitoring & intelligent turn-taking
    _inputAmpSub = audioService.inputAmplitudeStream.listen((amp) {
      _liveAudioLevel = amp;

      // Calibration phase: compute ambient noise floor over first ~1.5s
      if (_isCalibratingNoiseFloor) {
        _calibrationSamples.add(amp);
        return;
      }

      final dynamicThreshold = (_ambientNoiseFloor + AppConfig.interruptionSensitivity.thresholdDelta)
          .clamp(0.035, 0.25);

      if (_phase == DebatePhase.listening) {
        if (amp >= dynamicThreshold) {
          _resetInactivityTimer();
          _speechCandidateStart ??= DateTime.now();

          // Continuous speech gate: require sustained speech duration before triggering
          final sustainedMs = DateTime.now().difference(_speechCandidateStart!).inMilliseconds;
          if (sustainedMs >= AppConfig.interruptionSensitivity.requiredSpeechMs && !_isUserSpeaking) {
            _isUserSpeaking = true;
            geminiService.sendActivityStart();
            _statusText = 'You have the floor · Opponent is listening';
          }
          _silenceTimer?.cancel();
          _silenceTimer = null;
        } else {
          // Reset speech candidate if sound drops before required duration
          if (!_isUserSpeaking) {
            _speechCandidateStart = null;
          } else {
            // User had the floor and paused speaking -> wait for silence threshold in Live Mode
            if (_debateMode == DebateMode.live && !AppConfig.noisyEnvironmentMode) {
              _silenceTimer ??= Timer(_silenceWaitDuration, () {
                if (_isUserSpeaking && _phase == DebatePhase.listening) {
                  debugPrint('[DebateProvider] Silence detected -> passing turn to AI');
                  passToAI();
                }
                _silenceTimer = null;
              });
            }
          }
        }
        notifyListeners();
      } else if (_phase == DebatePhase.speaking && _debateMode == DebateMode.live && !AppConfig.noisyEnvironmentMode) {
        // In AI speaking phase, allow voice barge-in only with strict sustained threshold
        final bargeInThreshold = (dynamicThreshold * 1.8).clamp(0.08, 0.35);
        if (amp >= bargeInThreshold) {
          _speechCandidateStart ??= DateTime.now();
          final sustainedMs = DateTime.now().difference(_speechCandidateStart!).inMilliseconds;
          if (sustainedMs >= (AppConfig.interruptionSensitivity.requiredSpeechMs + 100)) {
            debugPrint('[DebateProvider] Voice barge-in detected! Interrupting opponent.');
            interruptAI();
          }
        } else {
          _speechCandidateStart = null;
        }
      }
    });

    _outputAmpSub = audioService.outputAmplitudeStream.listen((amp) {
      if (_phase == DebatePhase.speaking) {
        _liveAudioLevel = amp;
        mascotController.setMouthLevel(amp);
        notifyListeners();
      }
    });
  }

  void _startSpeakerCheckTimer() {
    _speakerCheckTimer?.cancel();
    _speakerTimeoutOccurred = false;
    _speakerCheckTimer = Timer(Duration(seconds: AppConfig.speakerCheckTimeoutSeconds), () {
      if (_phase == DebatePhase.speaking && audioService.totalChunksReceived == 0) {
        debugPrint('[DebateProvider] Speaker timeout: No audio received from opponent.');
        _speakerTimeoutOccurred = true;
        _statusText = 'No audio detected from opponent. Check speaker or retry.';
        notifyListeners();
      }
    });
  }

  void retrySpeakerCheck() {
    _speakerTimeoutOccurred = false;
    audioService.stopPlaybackAndClear();
    geminiService.retryConnection();
    _startSpeakerCheckTimer();
    notifyListeners();
  }

  /// Build sharp, tailored debate prompt with strict brevity rules
  String _buildSystemPrompt() {
    final opponentStance = _userSide.opposite.label;
    final userStance = _userSide.label;
    final topic = activeTopicTitle;
    final difficultyDesc = _difficulty.description;

    return '''
You are "${_selectedCharacter.name}", an elite, sharp, and fair debate opponent in a live voice-to-voice debate championship.
Your persona: ${_selectedCharacter.description}

DEBATE SPECIFICATIONS:
- Topic: "$topic"
- User Stance: $userStance
- Your Assigned Stance: $opponentStance (Argue strictly $opponentStance. Never concede core premises).
- Difficulty: ${_difficulty.label} ($difficultyDesc)
- Current Structure: 4 Rounds (Opening Arguments -> Rebuttal -> Cross-Examination -> Closing Statements).

CRITICAL SPOKEN VOICE RULES:
1. MAX 2 TO 3 SHORT SENTENCES PER TURN. Spoken responses must be instant, punchy, and concise. Never monologue.
2. Jump directly into your counter-argument. Do NOT repeat or summarize the user's point. Do NOT start with conversational filler (e.g. "I understand your point", "Well,", "Indeed").
3. Attack logical fallacies, ungrounded claims, or missing evidence with sharp rhetorical scrutiny.
4. Ignore any background noise, ambient speech, or mumbling. Respond only to direct debate speech directed at you.
5. Never end with assistant-style pleasantries like "How can I help you?" or "What do you think?". End on a sharp challenging counter-point.

EMOTION FUNCTION CALLING (MANDATORY):
Call `set_emotion(emotion)` on EVERY turn with one of:
["happy", "angry", "sad", "surprised", "confused", "thinking", "excited", "neutral", "laughing", "annoyed"].

Begin immediately with a sharp 1-to-2 sentence opening thesis defending $opponentStance!
''';
  }

  /// Start live debate session
  Future<void> startDebate() async {
    _errorMessage = null;
    _transcript.clear();
    _lastScore = null;
    _interruptionCount = 0;
    _turnsCount = 0;
    _isUserSpeaking = false;
    _speechCandidateStart = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _speakerTimeoutOccurred = false;
    _sessionDuration = Duration.zero;
    _sessionStartTime = DateTime.now();
    _currentRound = DebateRound.opening;
    _roundRemainingSeconds = _currentRound.durationSeconds;
    audioService.resetMetrics();

    _setPhase(DebatePhase.connecting, 'Waking up opponent...');
    mascotController.setCharacter(_selectedCharacter.name);
    mascotController.setState(MascotState.waking);
    mascotController.setEmotion(MascotEmotion.neutral);

    // 1. Initialize audio player
    await audioService.initAudioPlayer();

    // 2. Start mic recording
    final micReady = await audioService.startRecording();
    if (!micReady) {
      _errorMessage = 'Microphone permission denied or audio device unavailable.';
      _setPhase(DebatePhase.idle, 'Permission error');
      mascotController.setState(MascotState.confused);
      notifyListeners();
      return;
    }

    // 3. Calibrate ambient noise floor for 1.5 seconds
    _isCalibratingNoiseFloor = true;
    _calibrationSamples.clear();
    Timer(const Duration(milliseconds: 1500), () {
      _isCalibratingNoiseFloor = false;
      if (_calibrationSamples.isNotEmpty) {
        final avg = _calibrationSamples.reduce((a, b) => a + b) / _calibrationSamples.length;
        _ambientNoiseFloor = avg.clamp(0.01, 0.12);
        debugPrint('[DebateProvider] Ambient noise floor calibrated: ${_ambientNoiseFloor.toStringAsFixed(4)}');
      }
    });

    // 4. Connect to Gemini Live API
    final systemPrompt = _buildSystemPrompt();
    await geminiService.startSession(
      systemPrompt: systemPrompt,
      voiceName: _selectedVoice,
    );

    // 5. Start duration timer & round timer
    _sessionDurationTimer?.cancel();
    _sessionDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sessionStartTime != null) {
        _sessionDuration = DateTime.now().difference(_sessionStartTime!);
        notifyListeners();
      }
    });

    _startRoundTimer();
    _resetInactivityTimer();
  }

  void _startRoundTimer() {
    _roundCountdownTimer?.cancel();
    _roundCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_roundRemainingSeconds > 0) {
        _roundRemainingSeconds--;
        notifyListeners();
      } else {
        // Move to next round when time expires
        advanceRound();
      }
    });
  }

  void advanceRound() {
    final nextRound = _currentRound.next;
    if (nextRound != null) {
      _currentRound = nextRound;
      _roundRemainingSeconds = nextRound.durationSeconds;
      debugPrint('[DebateProvider] Advanced to: ${_currentRound.label}');
      notifyListeners();
    } else {
      // Reached end of 4 rounds
      endDebate();
    }
  }

  void _checkRoundProgression() {
    // When turn count passes thresholds, advance round
    if (_currentRound == DebateRound.opening && _turnsCount >= 2) {
      advanceRound();
    } else if (_currentRound == DebateRound.rebuttal && _turnsCount >= 4) {
      advanceRound();
    } else if (_currentRound == DebateRound.crossExamination && _turnsCount >= 7) {
      advanceRound();
    }
  }

  /// Passes conversational turn to AI opponent (manual turn handoff)
  void passToAI() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _isUserSpeaking = false;
    _speechCandidateStart = null;
    _turnSubmittedTime = DateTime.now();

    geminiService.sendActivityEnd();
    _setPhase(DebatePhase.thinking, 'Opponent is formulating rebuttal...');
    mascotController.setState(MascotState.idle);
    mascotController.setEmotion(MascotEmotion.thinking);
  }

  /// Explicit user interruption: allows user to intentionally interrupt the AI opponent
  Future<void> interruptAI() async {
    if (_phase == DebatePhase.speaking) {
      _interruptionCount++;
      debugPrint('[DebateProvider] User explicitly interrupted AI!');
      await audioService.stopPlaybackAndClear();
      geminiService.sendActivityStart();
      _isUserSpeaking = true;
      _speechCandidateStart = DateTime.now();

      _setPhase(DebatePhase.interrupted, 'Point of Order! Make your counter-point...');
      mascotController.setMouthLevel(0.0);
      mascotController.setState(MascotState.listening);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_phase == DebatePhase.interrupted) {
          _setPhase(DebatePhase.listening, 'Your turn · Make your point');
        }
      });
      notifyListeners();
    }
  }

  /// Toggle microphone mute
  void toggleMicMute() {
    if (_phase == DebatePhase.speaking) {
      interruptAI();
      return;
    }

    _isMicMuted = !_isMicMuted;
    audioService.setMuted(_isMicMuted);
    if (_isMicMuted && _isUserSpeaking) {
      passToAI();
    }
    notifyListeners();
  }

  /// Conclude debate and compute evaluation score
  Future<void> endDebate() async {
    _sessionDurationTimer?.cancel();
    _roundCountdownTimer?.cancel();
    _inactivityTimer?.cancel();
    _speakerCheckTimer?.cancel();
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _isUserSpeaking = false;
    _speechCandidateStart = null;

    _setPhase(DebatePhase.ended, 'Debate concluded');
    mascotController.setState(MascotState.idle);
    mascotController.setMouthLevel(0.0);

    await audioService.stopRecording();
    await audioService.stopPlaybackAndClear();
    await geminiService.endSession();

    // Calculate score
    _lastScore = DebateScore.calculateFromSession(
      duration: _sessionDuration,
      turnsCount: _turnsCount,
      interruptionCount: _interruptionCount,
      topic: activeTopicTitle,
      userStance: _userSide.label,
    );

    notifyListeners();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_phase == DebatePhase.idle || _phase == DebatePhase.ended) return;

    _inactivityTimer = Timer(const Duration(seconds: 25), () {
      if (_phase == DebatePhase.listening) {
        debugPrint('[DebateProvider] Inactivity detected -> drowsy state');
        mascotController.setState(MascotState.drowsy);
      }
    });
  }

  void _appendTranscriptChunk(Speaker speaker, String text) {
    if (_transcript.isNotEmpty && _transcript.last.speaker == speaker) {
      final last = _transcript.last;
      _transcript[_transcript.length - 1] = DebateTurn(
        speaker: speaker,
        text: '${last.text} $text'.trim(),
        timestamp: last.timestamp,
        emotion: mascotController.currentEmotion,
      );
    } else {
      _transcript.add(DebateTurn(
        speaker: speaker,
        text: text.trim(),
        timestamp: DateTime.now(),
        emotion: mascotController.currentEmotion,
      ));
    }
    notifyListeners();
  }

  void _setPhase(DebatePhase newPhase, String status) {
    _phase = newPhase;
    _statusText = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionDurationTimer?.cancel();
    _roundCountdownTimer?.cancel();
    _inactivityTimer?.cancel();
    _speakerCheckTimer?.cancel();
    _silenceTimer?.cancel();
    _inputAmpSub?.cancel();
    _outputAmpSub?.cancel();
    audioService.dispose();
    geminiService.dispose();
    super.dispose();
  }
}
