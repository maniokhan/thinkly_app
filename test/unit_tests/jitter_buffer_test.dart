import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinkly_app/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.llfbandit.record/messages'), (call) async {
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_pcm_sound/methods'), (call) async {
      return null;
    });
  });

  group('AudioService Jitter Buffer & Metrics Tests', () {
    late AudioService audioService;

    setUp(() {
      audioService = AudioService();
    });

    tearDown(() {
      audioService.dispose();
    });

    test('Initial metrics are zero', () {
      expect(audioService.bufferUnderruns, 0);
      expect(audioService.totalChunksReceived, 0);
      expect(audioService.totalBytesReceived, 0);
      expect(audioService.queuedAudioMs, 0);
      expect(audioService.isRecording, isFalse);
      expect(audioService.isPlaying, isFalse);
      expect(audioService.isMuted, isFalse);
    });

    test('Mute toggle properly sets state', () {
      audioService.setMuted(true);
      expect(audioService.isMuted, isTrue);

      audioService.setMuted(false);
      expect(audioService.isMuted, isFalse);
    });

    test('resetMetrics clears metrics counters', () {
      audioService.resetMetrics();
      expect(audioService.bufferUnderruns, 0);
      expect(audioService.totalChunksReceived, 0);
      expect(audioService.totalBytesReceived, 0);
    });
  });
}
