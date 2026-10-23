import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinkly_app/core/utils/audio_utils.dart';

void main() {
  group('AudioUtils Tests', () {
    test('calculateRmsAmplitude returns 0.0 for empty or single byte buffer', () {
      expect(AudioUtils.calculateRmsAmplitude(Uint8List(0)), 0.0);
      expect(AudioUtils.calculateRmsAmplitude(Uint8List(1)), 0.0);
    });

    test('calculateRmsAmplitude returns 0.0 for silence (zeros)', () {
      final silence = Uint8List(100);
      expect(AudioUtils.calculateRmsAmplitude(silence), 0.0);
    });

    test('calculateRmsAmplitude returns proportional value for non-zero PCM signal', () {
      final samples = [2000, -2000, 4000, -4000, 6000, -6000];
      final pcmBytes = AudioUtils.samplesToPcmBytes(samples);

      final amplitude = AudioUtils.calculateRmsAmplitude(pcmBytes);
      expect(amplitude, greaterThan(0.2));
      expect(amplitude, lessThanOrEqualTo(1.0));
    });

    test('pcmBytesToSamples and samplesToPcmBytes are inverse operations', () {
      final original = [0, 1000, -1000, 32767, -32768, 555];
      final bytes = AudioUtils.samplesToPcmBytes(original);
      final decoded = AudioUtils.pcmBytesToSamples(bytes);

      expect(decoded, equals(original));
    });
  });
}
