import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

class WebInteropService {
  static final WebInteropService _instance = WebInteropService._internal();
  factory WebInteropService() => _instance;
  WebInteropService._internal();

  // Streams for Speech
  final _speechResultController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onSpeechResult => _speechResultController.stream;

  final _speechErrorController = StreamController<String>.broadcast();
  Stream<String> get onSpeechError => _speechErrorController.stream;

  // Streams for Tab Audio (getDisplayMedia)
  final _tabAudioChunkController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onTabAudioChunk => _tabAudioChunkController.stream;

  final _tabAudioStatusController = StreamController<bool>.broadcast();
  Stream<bool> get onTabAudioStatus => _tabAudioStatusController.stream;

  // Real-time audio volume level (0.0 - 1.0 from Web Audio AnalyserNode)
  final _audioVolumeController = StreamController<double>.broadcast();
  Stream<double> get onAudioVolume => _audioVolumeController.stream;

  // Streams for PiP Events
  final _pipQuickNoteController = StreamController<String>.broadcast();
  Stream<String> get onPipQuickNote => _pipQuickNoteController.stream;

  final _pipFlagController = StreamController<void>.broadcast();
  Stream<void> get onPipFlag => _pipFlagController.stream;

  final _pipPauseResumeController = StreamController<void>.broadcast();
  Stream<void> get onPipPauseResume => _pipPauseResumeController.stream;

  final _pipExpandController = StreamController<void>.broadcast();
  Stream<void> get onPipExpand => _pipExpandController.stream;

  final _pipClosedController = StreamController<void>.broadcast();
  Stream<void> get onPipClosed => _pipClosedController.stream;

  final _pipSwitchSessionController = StreamController<String>.broadcast();
  Stream<String> get onPipSwitchSession => _pipSwitchSessionController.stream;

  bool _initialized = false;
  bool _isPipOpen = false;
  bool get isPipOpen => _isPipOpen;

  bool _isPipArmed = true;
  bool get isPipArmed => _isPipArmed;

  void initialize() {
    if (!kIsWeb || _initialized) return;
    _initialized = true;

    void addEventListenerCompat(String name, void Function(web.Event) listener) {
      web.window.addEventListener(name, listener.toJS);
    }

    // Helper to decode detail
    Map<String, dynamic>? getEventDetail(web.Event event) {
      try {
        final customEvent = event as web.CustomEvent;
        final detail = customEvent.detail;
        if (detail != null) {
          final jsonStr = (globalContext['JSON'] as JSObject).callMethod<JSString>(
            'stringify'.toJS,
            detail,
          ).toDart;
          return jsonDecode(jsonStr) as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('[WebInterop] Detail decode error: $e');
      }
      return null;
    }

    // Speech Result
    void handleSpeech(web.Event event) {
      final map = getEventDetail(event);
      if (map != null) _speechResultController.add(map);
    }
    addEventListenerCompat('thinkly-speech-result', handleSpeech);
    addEventListenerCompat('mindarena-speech-result', handleSpeech);

    // Speech Error
    void handleSpeechError(web.Event event) {
      final map = getEventDetail(event);
      _speechErrorController.add(map?['message']?.toString() ?? 'Microphone audio error');
    }
    addEventListenerCompat('thinkly-speech-error', handleSpeechError);
    addEventListenerCompat('mindarena-speech-error', handleSpeechError);

    // Tab Audio Chunk
    void handleAudioChunk(web.Event event) {
      final map = getEventDetail(event);
      if (map != null) _tabAudioChunkController.add(map);
    }
    addEventListenerCompat('thinkly-tab-audio-chunk', handleAudioChunk);
    addEventListenerCompat('mindarena-tab-audio-chunk', handleAudioChunk);

    // Tab Audio Status
    void handleAudioStatus(web.Event event) {
      final map = getEventDetail(event);
      final isRec = map?['isRecording'] == true;
      _tabAudioStatusController.add(isRec);
    }
    addEventListenerCompat('thinkly-tab-audio-status', handleAudioStatus);
    addEventListenerCompat('mindarena-tab-audio-status', handleAudioStatus);

    // Audio Volume
    void handleVolume(web.Event event) {
      final map = getEventDetail(event);
      if (map != null && map['volume'] != null) {
        final vol = (map['volume'] as num).toDouble();
        _audioVolumeController.add(vol);
      }
    }
    addEventListenerCompat('thinkly-audio-volume', handleVolume);
    addEventListenerCompat('mindarena-audio-volume', handleVolume);

    // PiP Events
    void handlePipNote(web.Event event) {
      final map = getEventDetail(event);
      final note = map?['note']?.toString() ?? '';
      if (note.isNotEmpty) _pipQuickNoteController.add(note);
    }
    addEventListenerCompat('thinkly-pip-quicknote', handlePipNote);
    addEventListenerCompat('mindarena-pip-quicknote', handlePipNote);

    void handlePipFlag(web.Event event) => _pipFlagController.add(null);
    addEventListenerCompat('thinkly-pip-flag', handlePipFlag);
    addEventListenerCompat('mindarena-pip-flag', handlePipFlag);

    void handlePipPause(web.Event event) => _pipPauseResumeController.add(null);
    addEventListenerCompat('thinkly-pip-pause-resume', handlePipPause);
    addEventListenerCompat('mindarena-pip-pause-resume', handlePipPause);

    void handlePipExpand(web.Event event) => _pipExpandController.add(null);
    addEventListenerCompat('thinkly-pip-expand', handlePipExpand);
    addEventListenerCompat('mindarena-pip-expand', handlePipExpand);

    void handlePipSwitch(web.Event event) {
      final map = getEventDetail(event);
      final id = map?['sessionId']?.toString() ?? '';
      if (id.isNotEmpty) _pipSwitchSessionController.add(id);
    }
    addEventListenerCompat('thinkly-pip-switch-session', handlePipSwitch);
    addEventListenerCompat('mindarena-pip-switch-session', handlePipSwitch);

    void handlePipClosed(web.Event event) {
      _isPipOpen = false;
      _pipClosedController.add(null);
    }
    addEventListenerCompat('thinkly-pip-closed', handlePipClosed);
    addEventListenerCompat('mindarena-pip-closed', handlePipClosed);

    void handlePipOpened(web.Event event) {
      _isPipOpen = true;
    }
    addEventListenerCompat('thinkly-pip-opened', handlePipOpened);
    addEventListenerCompat('mindarena-pip-opened', handlePipOpened);
  }

  bool startSpeechRecognition() {
    if (!kIsWeb) return false;
    try {
      final obj = (web.window as JSObject).getProperty<JSObject?>('thinklySpeech'.toJS) ??
          (web.window as JSObject).getProperty<JSObject?>('mindArenaSpeech'.toJS);
      if (obj != null) {
        return (obj.callMethod<JSBoolean>('startListening'.toJS)).toDart;
      }
    } catch (e) {
      debugPrint('[WebInterop] Speech recognition error: $e');
    }
    return false;
  }

  void stopSpeechRecognition() {
    if (!kIsWeb) return;
    try {
      final obj = (web.window as JSObject).getProperty<JSObject?>('thinklySpeech'.toJS) ??
          (web.window as JSObject).getProperty<JSObject?>('mindArenaSpeech'.toJS);
      if (obj != null) {
        obj.callMethod<JSAny?>('stopListening'.toJS);
      }
    } catch (e) {
      debugPrint('[WebInterop] Error stopping speech: $e');
    }
  }

  Future<bool> startTabAudioCapture() async {
    if (!kIsWeb) return false;
    try {
      final obj = (web.window as JSObject).getProperty<JSObject?>('thinklyTabAudio'.toJS) ??
          (web.window as JSObject).getProperty<JSObject?>('mindArenaTabAudio'.toJS);
      if (obj != null) {
        final promise = obj.callMethod<JSPromise<JSBoolean>>('startCapture'.toJS);
        final jsBool = await promise.toDart;
        return jsBool.toDart;
      }
    } catch (e) {
      debugPrint('[WebInterop] Error starting tab audio: $e');
    }
    return false;
  }

  void stopTabAudioCapture() {
    if (!kIsWeb) return;
    try {
      final obj = (web.window as JSObject).getProperty<JSObject?>('thinklyTabAudio'.toJS) ??
          (web.window as JSObject).getProperty<JSObject?>('mindArenaTabAudio'.toJS);
      if (obj != null) {
        obj.callMethod<JSAny?>('stopCapture'.toJS);
      }
    } catch (e) {
      debugPrint('[WebInterop] Error stopping tab audio: $e');
    }
  }

  void setPipArmed(bool armed) {
    _isPipArmed = armed;
    if (!kIsWeb) return;
    try {
      final pipObj = (web.window as JSObject).getProperty<JSObject?>('thinklyPip'.toJS) ??
          (web.window as JSObject).getProperty<JSObject?>('mindArenaPip'.toJS);
      if (pipObj != null) {
        pipObj.setProperty('autoPipEnabled'.toJS, armed.toJS);
      }
    } catch (e) {
      debugPrint('[WebInterop] Error setting PiP armed: $e');
    }
  }

  Future<bool> requestNativePip({
    required bool isListening,
    required String meetingBadge,
    required String transcript,
    required String latestNode,
    required int nodeCount,
    required int importantCount,
  }) async {
    if (!kIsWeb) return false;
    try {
      final pipObj = (web.window as JSObject).getProperty<JSObject?>('thinklyPip'.toJS) ??
          (web.window as JSObject).getProperty<JSObject?>('mindArenaPip'.toJS);
      if (pipObj != null) {
        updatePipState(
          isListening: isListening,
          meetingBadge: meetingBadge,
          transcript: transcript,
          latestNode: latestNode,
          nodeCount: nodeCount,
          importantCount: importantCount,
        );
        final promise = pipObj.callMethod<JSPromise<JSBoolean>>('openExternalPip'.toJS);
        final jsBool = await promise.toDart;
        _isPipOpen = jsBool.toDart;
        return _isPipOpen;
      }
    } catch (e) {
      debugPrint('[WebInterop] Error opening native PiP: $e');
    }
    return false;
  }

  void updatePipState({
    required bool isListening,
    String? meetingBadge,
    String? transcript,
    String? latestNode,
    int? nodeCount,
    int? importantCount,
  }) {
    if (!kIsWeb) return;
    try {
      final pipObj = (web.window as JSObject).getProperty<JSObject?>('thinklyPip'.toJS) ??
          (web.window as JSObject).getProperty<JSObject?>('mindArenaPip'.toJS);
      if (pipObj != null) {
        final stateMap = <String, dynamic>{
          'isListening': isListening,
          'meetingBadge': ?meetingBadge,
          'transcript': ?transcript,
          'latestNode': ?latestNode,
          'nodeCount': ?nodeCount,
          'importantCount': ?importantCount,
        };
        final jsState = (globalContext['JSON'] as JSObject).callMethod<JSAny?>(
          'parse'.toJS,
          jsonEncode(stateMap).toJS,
        );
        pipObj.callMethod<JSAny?>('updatePipState'.toJS, jsState);
      }
    } catch (e) {
      debugPrint('[WebInterop] Error updating PiP state: $e');
    }
  }

  void closeNativePip() {
    if (!kIsWeb || !_isPipOpen) return;
    try {
      final pipObj = (web.window as JSObject).getProperty<JSObject?>('thinklyPip'.toJS) ??
          (web.window as JSObject).getProperty<JSObject?>('mindArenaPip'.toJS);
      if (pipObj != null) {
        pipObj.callMethod<JSAny?>('closePip'.toJS);
      }
    } catch (e) {
      debugPrint('[WebInterop] Error closing PiP: $e');
    }
    _isPipOpen = false;
  }

  void updatePipLectures(List<Map<String, dynamic>> lectures, String activeLectureId) {
    if (!kIsWeb) return;
    try {
      final pipObj = (web.window as JSObject).getProperty<JSObject?>('thinklyPip'.toJS) ??
          (web.window as JSObject).getProperty<JSObject?>('mindArenaPip'.toJS);
      if (pipObj != null) {
        final stateMap = <String, dynamic>{
          'lectures': lectures,
          'activeLectureId': activeLectureId,
        };
        final jsState = (globalContext['JSON'] as JSObject).callMethod<JSAny?>(
          'parse'.toJS,
          jsonEncode(stateMap).toJS,
        );
        pipObj.callMethod<JSAny?>('updatePipState'.toJS, jsState);
      }
    } catch (e) {
      debugPrint('[WebInterop] Error updating PiP lectures: $e');
    }
  }

  void pauseTabAudioCapture() {
    if (!kIsWeb) return;
    try {
      final obj = (web.window as JSObject).getProperty<JSObject?>('thinklyTabAudio'.toJS) ??
          (web.window as JSObject).getProperty<JSObject?>('mindArenaTabAudio'.toJS);
      if (obj != null) {
        obj.callMethod<JSAny?>('pauseCapture'.toJS);
      }
    } catch (e) {
      debugPrint('[WebInterop] Error pausing tab audio: $e');
    }
  }

  void resumeTabAudioCapture() {
    if (!kIsWeb) return;
    try {
      final obj = (web.window as JSObject).getProperty<JSObject?>('thinklyTabAudio'.toJS) ??
          (web.window as JSObject).getProperty<JSObject?>('mindArenaTabAudio'.toJS);
      if (obj != null) {
        obj.callMethod<JSAny?>('resumeCapture'.toJS);
      }
    } catch (e) {
      debugPrint('[WebInterop] Error resuming tab audio: $e');
    }
  }

  void pauseSpeechRecognition() {
    if (!kIsWeb) return;
    try {
      final obj = (web.window as JSObject).getProperty<JSObject?>('thinklySpeech'.toJS) ??
          (web.window as JSObject).getProperty<JSObject?>('mindArenaSpeech'.toJS);
      if (obj != null) {
        obj.callMethod<JSAny?>('pauseListening'.toJS);
      }
    } catch (e) {
      debugPrint('[WebInterop] Error pausing speech: $e');
    }
  }

  void resumeSpeechRecognition() {
    if (!kIsWeb) return;
    try {
      final obj = (web.window as JSObject).getProperty<JSObject?>('thinklySpeech'.toJS) ??
          (web.window as JSObject).getProperty<JSObject?>('mindArenaSpeech'.toJS);
      if (obj != null) {
        obj.callMethod<JSAny?>('resumeListening'.toJS);
      }
    } catch (e) {
      debugPrint('[WebInterop] Error resuming speech: $e');
    }
  }
}
