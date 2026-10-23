enum DebateMode {
  live('Live Debate', 'Full-duplex, interruptible, conversational voice flow'),
  turnBased('Turn-Based', 'Structured, immune to background noise, tap to handoff');

  final String title;
  final String subtitle;
  const DebateMode(this.title, this.subtitle);
}

enum InterruptionSensitivity {
  low('Low', 0.060, 450),
  medium('Medium', 0.035, 300),
  high('High', 0.020, 200);

  final String label;
  final double thresholdDelta;
  final int requiredSpeechMs;
  const InterruptionSensitivity(this.label, this.thresholdDelta, this.requiredSpeechMs);
}

class AppConfig {
  /// The Gemini Multimodal Live API model ID.
  static const String defaultModelId = 'models/gemini-2.5-flash-native-audio-latest';

  /// List of verified live multimodal models
  static const List<String> supportedLiveModels = [
    'models/gemini-2.5-flash-native-audio-latest',
    'models/gemini-3.8-live',
    'models/gemini-3.1-flash-live-preview',
  ];

  /// Compile-time API key (optional fallback for local testing)
  static const String compileTimeApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// Official Gemini WebSocket endpoint
  static const String geminiLiveEndpoint =
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';

  /// Audio formats required by Gemini Live API
  static const int inputSampleRate = 16000;
  static const int outputSampleRate = 24000;
  static const int audioChannels = 1;

  /// Available Gemini voices
  static const List<String> availableVoices = [
    'Puck',
    'Charon',
    'Kore',
    'Fenrir',
    'Aoede',
  ];

  /// Runtime mutable settings
  static String apiKey = compileTimeApiKey;
  static String selectedModel = defaultModelId;
  static String selectedVoice = 'Puck';
  static bool echoCancellation = true;
  static bool noiseSuppression = true;

  /// Debate configuration
  static DebateMode debateMode = DebateMode.live;
  static InterruptionSensitivity interruptionSensitivity = InterruptionSensitivity.medium;
  static bool noisyEnvironmentMode = false;
  static int speakerCheckTimeoutSeconds = 6;

  /// Check whether Gemini API key is configured
  static bool get isConfigured => apiKey.trim().isNotEmpty;
}
