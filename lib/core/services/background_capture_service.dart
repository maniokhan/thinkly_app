import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

@pragma('vm:entry-point')
void startThinklyCaptureCallback() {
  FlutterForegroundTask.setTaskHandler(ThinklyCaptureTaskHandler());
}

class ThinklyCaptureTaskHandler extends TaskHandler {
  int _secondsElapsed = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _secondsElapsed = 0;
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _secondsElapsed += 5;
    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');

    FlutterForegroundTask.updateService(
      notificationTitle: 'Class Recording Active • $minutes:$seconds',
      notificationText: 'Capturing lecture audio. You can use Meet or YouTube.',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isServiceStopped) async {
    _secondsElapsed = 0;
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop_analyze') {
      FlutterForegroundTask.sendDataToMain('stop_analyze');
    }
  }
}

class BackgroundCaptureService {
  static final BackgroundCaptureService _instance =
      BackgroundCaptureService._internal();
  factory BackgroundCaptureService() => _instance;
  BackgroundCaptureService._internal();

  bool _isServiceInitialized = false;
  bool _isServiceRunning = false;
  Timer? _autosaveTimer;

  final _stopAndAnalyzeController = StreamController<void>.broadcast();
  Stream<void> get onStopAndAnalyzeRequested =>
      _stopAndAnalyzeController.stream;

  bool get isServiceRunning => _isServiceRunning;

  /// Initializes foreground task options and notification channel
  Future<void> initialize() async {
    if (_isServiceInitialized) return;

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'thinkly_class_capture',
          channelName: 'Thinkly Class Recorder',
          channelDescription:
              'Captures live classroom and meeting audio in background',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(5000),
          autoRunOnBoot: false,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );

      // Listen for notification action button clicks
      FlutterForegroundTask.addTaskDataCallback(_handleTaskData);
    }

    _isServiceInitialized = true;
  }

  void _handleTaskData(dynamic data) {
    if (data == 'stop_analyze') {
      debugPrint('[BackgroundCaptureService] Received stop_analyze action from notification');
      _stopAndAnalyzeController.add(null);
    }
  }

  /// Request runtime permissions (mic, notifications, battery exemption on Android)
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;

    try {
      // 1. Microphone permission
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        return false;
      }

      // 2. Notification permission (Android 13+)
      if (Platform.isAndroid) {
        final notifStatus = await Permission.notification.request();
        debugPrint('[BackgroundCaptureService] Notification permission: $notifStatus');

        // Request battery optimization exemption for uninterrupted background recording
        if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
          await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        }
      }

      return true;
    } catch (e) {
      debugPrint('[BackgroundCaptureService] Error requesting permissions: $e');
      return false;
    }
  }

  /// Starts the Android Foreground Service with persistent notification
  Future<void> startBackgroundCapture({required String lectureTitle}) async {
    if (_isServiceRunning) return;
    if (kIsWeb) {
      _isServiceRunning = true;
      return;
    }

    try {
      await initialize();
      final granted = await requestPermissions();
      if (!granted) {
        debugPrint('[BackgroundCaptureService] Necessary permissions not granted');
      }

      if (Platform.isAndroid || Platform.isIOS) {
        await FlutterForegroundTask.startService(
          serviceId: 101,
          notificationTitle: 'Class Recording Active',
          notificationText: 'Listening to $lectureTitle. Background capture ready.',
          callback: startThinklyCaptureCallback,
          notificationButtons: [
            const NotificationButton(
              id: 'stop_analyze',
              text: 'Stop & Analyze',
            ),
          ],
        );
      }

      _isServiceRunning = true;
    } catch (e) {
      debugPrint('[BackgroundCaptureService] Error starting foreground service: $e');
    }
  }

  /// Stops foreground service and cleans up notification
  Future<void> stopBackgroundCapture() async {
    if (!_isServiceRunning) return;

    _autosaveTimer?.cancel();
    _autosaveTimer = null;

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await FlutterForegroundTask.stopService();
      } catch (e) {
        debugPrint('[BackgroundCaptureService] Error stopping foreground service: $e');
      }
    }

    _isServiceRunning = false;
  }

  // ==========================================================================
  // AUTOSAVE PARTIAL TRANSCRIPT (Every 15-30s)
  // ==========================================================================
  void startAutosaveLoop({
    required String sessionId,
    required String Function() getTranscript,
  }) {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      final transcript = getTranscript().trim();
      if (transcript.isNotEmpty) {
        await savePartialTranscript(sessionId, transcript);
      }
    });
  }

  void stopAutosaveLoop() {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
  }

  Future<void> savePartialTranscript(String sessionId, String transcript) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('thinkly_partial_transcript_$sessionId', transcript);
      await prefs.setString('thinkly_last_active_session', sessionId);
    } catch (e) {
      debugPrint('[BackgroundCaptureService] Error saving partial transcript: $e');
    }
  }

  Future<String?> recoverPartialTranscript(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('thinkly_partial_transcript_$sessionId');
    } catch (e) {
      debugPrint('[BackgroundCaptureService] Error recovering partial transcript: $e');
      return null;
    }
  }

  Future<void> clearPartialTranscript(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('thinkly_partial_transcript_$sessionId');
    } catch (_) {}
  }

  // ==========================================================================
  // YOUTUBE SHORTCUT (Direct transcript & captions extraction)
  // ==========================================================================
  Future<Map<String, dynamic>> extractYouTubeLecture(String youtubeUrl) async {
    final yt = YoutubeExplode();
    try {
      final video = await yt.videos.get(youtubeUrl);
      final videoTitle = video.title;
      final videoAuthor = video.author;
      final description = video.description;

      final trackManifest =
          await yt.videos.closedCaptions.getManifest(video.id);
      String transcript = '';

      if (trackManifest.tracks.isNotEmpty) {
        // Prefer English tracks, fallback to first available
        final enTracks = trackManifest.getByLanguage('en');
        final selectedTrack =
            enTracks.isNotEmpty ? enTracks.first : trackManifest.tracks.first;

        final closedCaptionTrack =
            await yt.videos.closedCaptions.get(selectedTrack);
        final buffer = StringBuffer();
        for (final subtitle in closedCaptionTrack.captions) {
          final mins = subtitle.offset.inMinutes.toString().padLeft(2, '0');
          final secs =
              (subtitle.offset.inSeconds % 60).toString().padLeft(2, '0');
          buffer.writeln('[$mins:$secs] ${subtitle.text}');
        }
        transcript = buffer.toString().trim();
      }

      // If no closed captions were found, fallback to description & chapters
      if (transcript.isEmpty) {
        transcript = description.isNotEmpty
            ? 'Lecture topic: $videoTitle by $videoAuthor.\n\nDescription & Outline:\n$description'
            : 'Lecture video: $videoTitle by $videoAuthor.';
      }

      return {
        'title': videoTitle,
        'author': videoAuthor,
        'transcript': transcript,
        'hasCaptions': trackManifest.tracks.isNotEmpty,
      };
    } finally {
      yt.close();
    }
  }
}
