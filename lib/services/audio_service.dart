import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart' hide IosAudioCategory;
import '../core/config/app_config.dart';
import '../core/utils/audio_utils.dart';

class AudioService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordSubscription;

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isPlayerInitialized = false;

  // Stream controllers for volume visualizer and mouth sync
  final _inputAmplitudeController = StreamController<double>.broadcast();
  final _outputAmplitudeController = StreamController<double>.broadcast();

  Stream<double> get inputAmplitudeStream => _inputAmplitudeController.stream;
  Stream<double> get outputAmplitudeStream => _outputAmplitudeController.stream;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isMuted => _isMuted;

  /// Callback when mic yields a raw PCM 16-bit 16kHz chunk
  void Function(Uint8List chunk)? onMicData;

  // Jitter buffer queue for smooth continuous 24kHz playback
  // 24kHz * 2 bytes/sample = 48,000 bytes/sec
  // 200ms = 9,600 bytes
  static const int _jitterBufferThresholdBytes = 9600;
  final List<Uint8List> _jitterBuffer = [];
  int _bufferedBytes = 0;
  bool _isJitterBuffering = true;

  // Audio queue health metrics
  int _bufferUnderruns = 0;
  int _totalChunksReceived = 0;
  int _totalBytesReceived = 0;

  int get bufferUnderruns => _bufferUnderruns;
  int get totalChunksReceived => _totalChunksReceived;
  int get totalBytesReceived => _totalBytesReceived;
  int get queuedAudioMs => (_bufferedBytes / (AppConfig.outputSampleRate * 2) * 1000).round();

  void resetMetrics() {
    _bufferUnderruns = 0;
    _totalChunksReceived = 0;
    _totalBytesReceived = 0;
  }

  /// Check & request mic permissions
  Future<bool> checkAndRequestPermissions() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) return true;

      final result = await Permission.microphone.request();
      if (result.isGranted) return true;

      // Fallback check on recorder
      return await _audioRecorder.hasPermission();
    } catch (e) {
      debugPrint('[AudioService] Permission check error: $e');
      return await _audioRecorder.hasPermission();
    }
  }

  /// Initialize PCM sound output at 24kHz mono with underrun detection
  Future<void> initAudioPlayer() async {
    if (_isPlayerInitialized) return;

    try {
      await FlutterPcmSound.setLogLevel(LogLevel.none);
      await FlutterPcmSound.setup(
        sampleRate: AppConfig.outputSampleRate,
        channelCount: AppConfig.audioChannels,
        iosAudioCategory: IosAudioCategory.playAndRecord,
        iosAllowBackgroundAudio: true,
      );

      // Track buffer underruns via feed callback
      FlutterPcmSound.setFeedCallback((remainingFrames) {
        if (remainingFrames == 0 && _isPlaying && !_isJitterBuffering) {
          _bufferUnderruns++;
          debugPrint('[AudioService] Buffer underrun detected! Total: $_bufferUnderruns');
        }
      });

      _isPlayerInitialized = true;
      debugPrint('[AudioService] PCM Audio player initialized at ${AppConfig.outputSampleRate}Hz');
    } catch (e) {
      debugPrint('[AudioService] Failed to init PCM player: $e');
    }
  }

  /// Start recording continuous 16kHz PCM audio stream with AEC & voice communication mode
  Future<bool> startRecording() async {
    if (_isRecording) return true;

    final hasPerm = await checkAndRequestPermissions();
    if (!hasPerm) {
      debugPrint('[AudioService] Cannot record: Microphone permission not granted');
      return false;
    }

    try {
      final config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: AppConfig.inputSampleRate,
        numChannels: AppConfig.audioChannels,
        echoCancel: AppConfig.echoCancellation,
        autoGain: true,
        noiseSuppress: AppConfig.noiseSuppression,
        androidConfig: const AndroidRecordConfig(
          audioSource: AndroidAudioSource.voiceCommunication,
        ),
        iosConfig: const IosRecordConfig(
          categoryOptions: [
            IosAudioCategoryOption.defaultToSpeaker,
            IosAudioCategoryOption.allowBluetooth,
            IosAudioCategoryOption.allowBluetoothA2DP,
          ],
        ),
      );

      final stream = await _audioRecorder.startStream(config);
      _isRecording = true;

      _recordSubscription = stream.listen(
        (Uint8List data) {
          if (_isMuted) {
            _inputAmplitudeController.add(0.0);
            return;
          }

          // Compute input volume amplitude
          final amplitude = AudioUtils.calculateRmsAmplitude(data);
          _inputAmplitudeController.add(amplitude);

          // Deliver chunk to consumer (Gemini Live WebSocket)
          onMicData?.call(data);
        },
        onError: (err) {
          debugPrint('[AudioService] Record stream error: $err');
          stopRecording();
        },
      );

      debugPrint('[AudioService] Started recording at ${AppConfig.inputSampleRate}Hz (VOICE_COMMUNICATION)');
      return true;
    } catch (e) {
      debugPrint('[AudioService] Failed to start recording: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stop recording
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    try {
      await _recordSubscription?.cancel();
      _recordSubscription = null;
      await _audioRecorder.stop();
      _isRecording = false;
      _inputAmplitudeController.add(0.0);
      debugPrint('[AudioService] Recording stopped.');
    } catch (e) {
      debugPrint('[AudioService] Error stopping recording: $e');
      _isRecording = false;
    }
  }

  /// Toggle mute
  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      _inputAmplitudeController.add(0.0);
    }
  }

  /// Reset jitter buffer state ahead of an expected new AI turn
  void prepareForNextTurn() {
    _isJitterBuffering = true;
    _jitterBuffer.clear();
    _bufferedBytes = 0;
  }

  /// Feed incoming model audio (24kHz PCM 16-bit little endian) into the jitter buffer
  Future<void> feedModelAudio(Uint8List pcmChunk) async {
    if (!_isPlayerInitialized) {
      await initAudioPlayer();
    }

    if (pcmChunk.isEmpty) return;

    try {
      _totalChunksReceived++;
      _totalBytesReceived += pcmChunk.length;

      // Calculate output amplitude for visualizer & mascot mouth sync
      final amplitude = AudioUtils.calculateRmsAmplitude(pcmChunk);
      _outputAmplitudeController.add(amplitude);

      if (_isJitterBuffering) {
        _jitterBuffer.add(pcmChunk);
        _bufferedBytes += pcmChunk.length;

        // Start playback once jitter buffer reaches ~200ms
        if (_bufferedBytes >= _jitterBufferThresholdBytes) {
          _isJitterBuffering = false;
          _isPlaying = true;
          await _drainJitterBuffer();
        }
      } else {
        // Already drained initial buffer: feed directly to keep continuous stream
        _isPlaying = true;
        await _feedDirect(pcmChunk);
      }
    } catch (e) {
      debugPrint('[AudioService] Error feeding PCM audio: $e');
    }
  }

  /// Flush any remaining jitter buffer (e.g., at end of turn for very short responses)
  Future<void> flushJitterBuffer() async {
    if (_jitterBuffer.isNotEmpty) {
      _isJitterBuffering = false;
      _isPlaying = true;
      await _drainJitterBuffer();
    }
  }

  Future<void> _drainJitterBuffer() async {
    if (_jitterBuffer.isEmpty) return;

    final totalLen = _jitterBuffer.fold<int>(0, (sum, c) => sum + c.length);
    final combined = Uint8List(totalLen);
    int offset = 0;
    for (final chunk in _jitterBuffer) {
      combined.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    _jitterBuffer.clear();
    _bufferedBytes = 0;

    await _feedDirect(combined);
  }

  Future<void> _feedDirect(Uint8List chunk) async {
    final byteData = ByteData.sublistView(chunk);
    await FlutterPcmSound.feed(PcmArrayInt16(bytes: byteData));
  }

  /// Interruption / Barge-in handling: Stop output playback immediately and clear buffers
  Future<void> stopPlaybackAndClear() async {
    try {
      _isPlaying = false;
      _isJitterBuffering = true;
      _jitterBuffer.clear();
      _bufferedBytes = 0;
      if (!_outputAmplitudeController.isClosed) {
        _outputAmplitudeController.add(0.0);
      }

      if (_isPlayerInitialized) {
        // Re-setup flushes native audio buffers instantly and readies player
        await FlutterPcmSound.setup(
          sampleRate: AppConfig.outputSampleRate,
          channelCount: AppConfig.audioChannels,
          iosAudioCategory: IosAudioCategory.playAndRecord,
          iosAllowBackgroundAudio: true,
        );
        debugPrint('[AudioService] Playback buffer flushed & reset.');
      }
    } catch (e) {
      debugPrint('[AudioService] Error resetting audio buffer: $e');
    }
  }

  /// Pause/Resume for app lifecycle transitions
  Future<void> pauseAudio() async {
    await stopRecording();
    await stopPlaybackAndClear();
  }

  Future<void> resumeAudio() async {
    if (!_isMuted) {
      await startRecording();
    }
  }

  void dispose() {
    stopRecording();
    stopPlaybackAndClear();
    _inputAmplitudeController.close();
    _outputAmplitudeController.close();
    try {
      _audioRecorder.dispose();
    } catch (_) {}
    if (_isPlayerInitialized) {
      try {
        FlutterPcmSound.release();
      } catch (_) {}
    }
  }
}
