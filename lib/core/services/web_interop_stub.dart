import 'dart:async';

class WebInteropService {
  static final WebInteropService _instance = WebInteropService._internal();
  factory WebInteropService() => _instance;
  WebInteropService._internal();

  final _speechResultController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onSpeechResult => _speechResultController.stream;

  final _speechErrorController = StreamController<String>.broadcast();
  Stream<String> get onSpeechError => _speechErrorController.stream;

  final _tabAudioChunkController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onTabAudioChunk => _tabAudioChunkController.stream;

  final _tabAudioStatusController = StreamController<bool>.broadcast();
  Stream<bool> get onTabAudioStatus => _tabAudioStatusController.stream;

  final _audioVolumeController = StreamController<double>.broadcast();
  Stream<double> get onAudioVolume => _audioVolumeController.stream;

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

  bool get isPipOpen => false;
  bool _isPipArmed = true;
  bool get isPipArmed => _isPipArmed;

  void initialize() {}

  bool startSpeechRecognition() => false;
  void stopSpeechRecognition() {}
  void pauseSpeechRecognition() {}
  void resumeSpeechRecognition() {}

  Future<bool> startTabAudioCapture() async => false;
  void stopTabAudioCapture() {}
  void pauseTabAudioCapture() {}
  void resumeTabAudioCapture() {}

  void setPipArmed(bool armed) {
    _isPipArmed = armed;
  }

  Future<bool> requestNativePip({
    required bool isListening,
    required String meetingBadge,
    required String transcript,
    required String latestNode,
    required int nodeCount,
    required int importantCount,
  }) async => false;

  void updatePipState({
    required bool isListening,
    String? meetingBadge,
    String? transcript,
    String? latestNode,
    int? nodeCount,
    int? importantCount,
  }) {}

  void updatePipLectures(List<Map<String, dynamic>> lectures, String activeLectureId) {}

  void closeNativePip() {}
}
