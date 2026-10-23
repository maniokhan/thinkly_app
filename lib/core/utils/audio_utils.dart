import 'dart:math' as math;
import 'dart:typed_data';

class AudioUtils {
  /// Calculate normalized volume amplitude (0.0 to 1.0) from raw 16-bit PCM byte data
  static double calculateRmsAmplitude(Uint8List pcmBytes) {
    if (pcmBytes.isEmpty || pcmBytes.length < 2) return 0.0;

    // View as 16-bit signed integers
    final sampleCount = pcmBytes.length ~/ 2;
    final byteData = ByteData.sublistView(pcmBytes);

    double sumSquares = 0.0;
    for (int i = 0; i < sampleCount; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      sumSquares += sample * sample;
    }

    final rms = math.sqrt(sumSquares / sampleCount);
    // 16-bit max amplitude is 32767. Speech typically ranges up to ~8000-16000 RMS
    // Normalize with a dynamic curve for visual responsiveness
    final normalized = (rms / 6000.0).clamp(0.0, 1.0);
    return normalized;
  }

  /// Converts 16-bit PCM bytes (little-endian) into `List<int>` of samples
  static List<int> pcmBytesToSamples(Uint8List bytes) {
    if (bytes.length < 2) return [];
    final count = bytes.length ~/ 2;
    final byteData = ByteData.sublistView(bytes);
    final samples = List<int>.filled(count, 0);

    for (int i = 0; i < count; i++) {
      samples[i] = byteData.getInt16(i * 2, Endian.little);
    }
    return samples;
  }

  /// Converts `List<int>` of samples to 16-bit PCM Uint8List
  static Uint8List samplesToPcmBytes(List<int> samples) {
    final byteData = ByteData(samples.length * 2);
    for (int i = 0; i < samples.length; i++) {
      byteData.setInt16(i * 2, samples[i].clamp(-32768, 32767), Endian.little);
    }
    return byteData.buffer.asUint8List();
  }
}
