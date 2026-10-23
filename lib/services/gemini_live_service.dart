import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/config/app_config.dart';
import '../features/mascot/models/mascot_emotion.dart';

enum GeminiConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class GeminiLiveService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  GeminiConnectionStatus _status = GeminiConnectionStatus.disconnected;
  GeminiConnectionStatus get status => _status;

  // Callbacks
  void Function(GeminiConnectionStatus status)? onStatusChanged;
  void Function(Uint8List audioPcmChunk)? onAudioReceived;
  void Function(String text)? onTranscriptReceived;
  void Function(MascotEmotion emotion)? onEmotionReceived;
  void Function()? onInterrupted;
  void Function(bool turnComplete)? onTurnCompleted;
  void Function(String errorMessage)? onError;

  bool _isSessionActive = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;

  String _lastSystemPrompt = '';
  String _lastVoiceName = 'Puck';
  bool _isUserActivityOpen = false;
  String? _sessionResumeHandle;

  bool get isUserActivityOpen => _isUserActivityOpen;
  bool get isSessionActive => _isSessionActive;

  /// Start a Live Gemini session
  Future<void> startSession({
    required String systemPrompt,
    String? voiceName,
  }) async {
    _lastSystemPrompt = systemPrompt;
    _lastVoiceName = voiceName ?? AppConfig.selectedVoice;
    _isSessionActive = true;
    _reconnectAttempts = 0;
    _isUserActivityOpen = false;
    _sessionResumeHandle = null;

    await _connect();
  }

  Future<void> _connect() async {
    _updateStatus(_reconnectAttempts > 0
        ? GeminiConnectionStatus.reconnecting
        : GeminiConnectionStatus.connecting);

    final apiKey = AppConfig.apiKey.trim();
    if (apiKey.isEmpty) {
      _handleError('Missing Gemini API Key. Please configure your key in settings.');
      return;
    }

    final uri = Uri.parse('${AppConfig.geminiLiveEndpoint}?key=$apiKey');

    try {
      debugPrint('[GeminiLive] Connecting to: $uri');
      _channel = WebSocketChannel.connect(uri);
      await _channel?.ready;

      _updateStatus(GeminiConnectionStatus.connected);
      _reconnectAttempts = 0;
      _isUserActivityOpen = false;

      // Listen to incoming messages
      _subscription = _channel?.stream.listen(
        _handleIncomingMessage,
        onError: (err) {
          debugPrint('[GeminiLive] Stream error: $err');
          _handleConnectionDrop('Stream error: $err');
        },
        onDone: () {
          final code = _channel?.closeCode;
          final reason = _channel?.closeReason;
          debugPrint('[GeminiLive] Connection closed by server. Code: $code, Reason: $reason');
          if (_isSessionActive) {
            if (code == 1008) {
              _isSessionActive = false;
              _handleError('Gemini rejected connection ($code): ${reason?.isNotEmpty == true ? reason : "Model '${AppConfig.selectedModel}' not found or unsupported."}');
            } else {
              _handleConnectionDrop('Connection closed ($code): ${reason ?? ""}');
            }
          } else {
            _updateStatus(GeminiConnectionStatus.disconnected);
          }
        },
      );

      // Send setup handshake
      _sendSetupHandshake();
    } catch (e) {
      debugPrint('[GeminiLive] Connection failed: $e');
      _handleConnectionDrop('Failed to connect: $e');
    }
  }

  /// Sends the initial configuration handshake with thinkingBudget: 0 for instant spoken turns
  void _sendSetupHandshake() {
    final setupPayload = <String, dynamic>{
      'setup': {
        'model': AppConfig.selectedModel,
        'generationConfig': {
          'responseModalities': ['AUDIO'],
          'speechConfig': {
            'voiceConfig': {
              'prebuiltVoiceConfig': {
                'voiceName': _lastVoiceName,
              },
            },
          },
          'thinkingConfig': {
            'thinkingBudget': 0, // Minimize thinking latency for instant speech response
          },
        },
        'systemInstruction': {
          'parts': [
            {'text': _lastSystemPrompt},
          ],
        },
        'realtimeInputConfig': {
          'automaticActivityDetection': {
            'disabled': true, // Managed by client continuous speech VAD
          },
        },
        'tools': [
          {
            'functionDeclarations': [
              {
                'name': 'set_emotion',
                'description':
                    'Report your emotional expression/state as the debate opponent each turn.',
                'parameters': {
                  'type': 'OBJECT',
                  'properties': {
                    'emotion': {
                      'type': 'STRING',
                      'enum': [
                        'happy',
                        'angry',
                        'sad',
                        'surprised',
                        'confused',
                        'thinking',
                        'excited',
                        'neutral',
                        'laughing',
                        'annoyed'
                      ],
                      'description': 'The current emotion to display on your mascot face'
                    }
                  },
                  'required': ['emotion']
                }
              }
            ]
          }
        ]
      }
    };

    if (_sessionResumeHandle != null) {
      setupPayload['setup']['sessionResumption'] = {
        'handle': _sessionResumeHandle,
      };
    }

    _sendMessage(setupPayload);
    debugPrint('[GeminiLive] Setup handshake sent with model: ${AppConfig.selectedModel}, voice: $_lastVoiceName, thinkingBudget: 0');
  }

  /// Sends the opening kickoff turn so the AI debate opponent presents its opening argument
  void _sendOpeningKickoff() {
    final kickoffPayload = {
      'clientContent': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {
                'text':
                    'The debate has begun. Introduce yourself as my sharp debate opponent and deliver your opening counter-argument!'
              }
            ]
          }
        ],
        'turnComplete': true
      }
    };
    _sendMessage(kickoffPayload);
    debugPrint('[GeminiLive] Opening kickoff sent to initiate debate speaking turn.');
  }

  /// Signals that the user has started speaking (or barged in)
  void sendActivityStart() {
    if (_status != GeminiConnectionStatus.connected || _channel == null) return;
    if (_isUserActivityOpen) return;

    _isUserActivityOpen = true;
    final payload = {
      'realtimeInput': {
        'activityStart': {},
      }
    };
    _sendMessage(payload);
    debugPrint('[GeminiLive] activityStart signal sent.');
  }

  /// Signals that the user has stopped speaking and the AI should reply immediately
  void sendActivityEnd() {
    if (_status != GeminiConnectionStatus.connected || _channel == null) return;
    if (!_isUserActivityOpen) {
      _sendMessage({
        'realtimeInput': {
          'activityStart': {},
        }
      });
    }

    _isUserActivityOpen = false;
    final payload = {
      'realtimeInput': {
        'activityEnd': {},
      }
    };
    _sendMessage(payload);
    debugPrint('[GeminiLive] activityEnd signal sent -> triggering AI response.');
  }

  /// Sends raw PCM audio chunk (16kHz 16-bit mono) from user microphone
  void sendAudioChunk(Uint8List pcmChunk) {
    if (_status != GeminiConnectionStatus.connected || _channel == null) return;

    final base64Audio = base64Encode(pcmChunk);
    final payload = {
      'realtimeInput': {
        'mediaChunks': [
          {
            'mimeType': 'audio/pcm;rate=${AppConfig.inputSampleRate}',
            'data': base64Audio,
          }
        ]
      }
    };

    _sendMessage(payload);
  }

  /// Parses incoming JSON messages from Gemini WebSocket
  void _handleIncomingMessage(dynamic rawMessage) {
    try {
      final jsonString = rawMessage is String ? rawMessage : utf8.decode(rawMessage as List<int>);
      final map = jsonDecode(jsonString) as Map<String, dynamic>;

      // 1. Handle Setup Complete Handshake Confirmation
      if (map.containsKey('setupComplete')) {
        debugPrint('[GeminiLive] Setup completed by server. Starting debate opening...');
        _sendOpeningKickoff();
      }

      // 2. Handle Session Resumption Update
      if (map.containsKey('sessionResumptionUpdate')) {
        final update = map['sessionResumptionUpdate'] as Map<String, dynamic>;
        _sessionResumeHandle = update['handle'] as String? ?? update['token'] as String?;
        debugPrint('[GeminiLive] Session resumption handle updated.');
      }

      // 3. Handle Server Content (Audio / Text / Interruption)
      if (map.containsKey('serverContent')) {
        final serverContent = map['serverContent'] as Map<String, dynamic>;

        // Interruption / Barge-in detection
        if (serverContent['interrupted'] == true) {
          debugPrint('[GeminiLive] User barged-in! Interrupted received from server.');
          onInterrupted?.call();
        }

        // Model audio & text parts
        if (serverContent.containsKey('modelTurn')) {
          final modelTurn = serverContent['modelTurn'] as Map<String, dynamic>;
          final parts = modelTurn['parts'] as List<dynamic>? ?? [];

          for (final part in parts) {
            // Audio chunk
            if (part is Map<String, dynamic> && part.containsKey('inlineData')) {
              final inlineData = part['inlineData'] as Map<String, dynamic>;
              final base64Data = inlineData['data'] as String?;
              if (base64Data != null) {
                final audioBytes = base64Decode(base64Data);
                onAudioReceived?.call(audioBytes);
              }
            }

            // Transcript text
            if (part is Map<String, dynamic> && part.containsKey('text')) {
              final text = part['text'] as String?;
              if (text != null && text.isNotEmpty) {
                onTranscriptReceived?.call(text);
              }
            }
          }
        }

        // Turn complete
        if (serverContent['turnComplete'] == true) {
          _isUserActivityOpen = false;
          onTurnCompleted?.call(true);
        }
      }

      // 4. Handle Function Calling (set_emotion)
      if (map.containsKey('toolCall')) {
        final toolCall = map['toolCall'] as Map<String, dynamic>;
        final functionCalls = toolCall['functionCalls'] as List<dynamic>? ?? [];

        final functionResponses = <Map<String, dynamic>>[];

        for (final call in functionCalls) {
          if (call is Map<String, dynamic>) {
            final name = call['name'] as String?;
            final id = call['id'] as String?;
            final args = call['args'] as Map<String, dynamic>? ?? {};

            if (name == 'set_emotion') {
              final emotionStr = args['emotion'] as String?;
              final emotion = MascotEmotion.fromString(emotionStr);
              debugPrint('[GeminiLive] Tool call set_emotion -> $emotion');
              onEmotionReceived?.call(emotion);

              functionResponses.add({
                'id': id,
                'name': name,
                'response': {
                  'output': {'status': 'ok'}
                }
              });
            }
          }
        }

        // Send toolResponse back to server
        if (functionResponses.isNotEmpty) {
          final toolResponsePayload = {
            'toolResponse': {
              'functionResponses': functionResponses,
            }
          };
          _sendMessage(toolResponsePayload);
        }
      }

      // 5. Error reporting from server
      if (map.containsKey('error')) {
        final err = map['error'];
        final msg = err is Map ? err['message'] ?? err.toString() : err.toString();
        debugPrint('[GeminiLive] Server reported error: $msg');
        _handleError(msg.toString());
      }
    } catch (e) {
      debugPrint('[GeminiLive] Error parsing incoming message: $e');
    }
  }

  void _sendMessage(Map<String, dynamic> data) {
    if (_channel == null || _status != GeminiConnectionStatus.connected) return;
    try {
      final jsonStr = jsonEncode(data);
      _channel?.sink.add(jsonStr);
    } catch (e) {
      debugPrint('[GeminiLive] Error sending message: $e');
    }
  }

  void _handleConnectionDrop(String reason) {
    if (!_isSessionActive) {
      _updateStatus(GeminiConnectionStatus.disconnected);
      return;
    }

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      debugPrint('[GeminiLive] Auto-reconnecting silently ($_reconnectAttempts/$_maxReconnectAttempts) in 2 seconds...');
      _updateStatus(GeminiConnectionStatus.reconnecting);
      Future.delayed(const Duration(seconds: 2), () {
        if (_isSessionActive) _connect();
      });
    } else {
      _updateStatus(GeminiConnectionStatus.error);
      _handleError('Live connection dropped: $reason. Tap to reconnect.');
    }
  }

  /// Manually retry connection after drops
  Future<void> retryConnection() async {
    _reconnectAttempts = 0;
    await _connect();
  }

  void _handleError(String msg) {
    _updateStatus(GeminiConnectionStatus.error);
    onError?.call(msg);
  }

  void _updateStatus(GeminiConnectionStatus newStatus) {
    _status = newStatus;
    onStatusChanged?.call(_status);
  }

  /// Cleanly closes the active live session
  Future<void> endSession() async {
    _isSessionActive = false;
    _reconnectAttempts = 0;
    _isUserActivityOpen = false;
    _sessionResumeHandle = null;
    try {
      await _subscription?.cancel();
      _subscription = null;
      await _channel?.sink.close();
      _channel = null;
    } catch (e) {
      debugPrint('[GeminiLive] Error ending session: $e');
    }
    _updateStatus(GeminiConnectionStatus.disconnected);
  }

  void dispose() {
    endSession();
  }
}
