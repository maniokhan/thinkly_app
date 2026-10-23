import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/mascot_emotion.dart';
import '../models/mascot_state.dart';

class MascotController extends ChangeNotifier {
  WebViewController? _webViewController;
  bool _isReady = false;

  String _currentCharacter = 'Strobi';
  MascotState _currentState = MascotState.idle;
  MascotEmotion _currentEmotion = MascotEmotion.neutral;
  double _currentMouthLevel = 0.0;

  DateTime _lastMouthUpdateTime = DateTime.now();
  static const int _minMouthUpdateIntervalMs = 28; // ~35 updates/sec max to keep WebView butter smooth

  bool get isReady => _isReady;
  String get currentCharacter => _currentCharacter;
  MascotState get currentState => _currentState;
  MascotEmotion get currentEmotion => _currentEmotion;
  double get currentMouthLevel => _currentMouthLevel;

  void attachController(WebViewController controller) {
    _webViewController = controller;
  }

  void onMascotReady() {
    _isReady = true;
    notifyListeners();
    // Re-apply latest state to ensure sync
    setCharacter(_currentCharacter);
    setState(_currentState);
    setEmotion(_currentEmotion);
  }

  void handleBridgeMessage(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      final action = map['action'] as String?;

      if (action == 'ready') {
        onMascotReady();
      } else if (action == 'characterChanged') {
        _currentCharacter = map['character'] as String? ?? _currentCharacter;
        notifyListeners();
      } else if (action == 'stateChanged') {
        _currentState = MascotState.fromString(map['state'] as String?);
        notifyListeners();
      } else if (action == 'emotionChanged') {
        _currentEmotion = MascotEmotion.fromString(map['emotion'] as String?);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[MascotController] Failed to parse bridge message: $e');
    }
  }

  Future<void> setCharacter(String name) async {
    _currentCharacter = name;
    notifyListeners();
    if (_webViewController == null || !_isReady) return;

    try {
      final escaped = jsonEncode(name);
      await _webViewController?.runJavaScript('window.setCharacter($escaped);');
    } catch (e) {
      debugPrint('[MascotController] Error setting character: $e');
    }
  }

  Future<void> setState(MascotState state) async {
    _currentState = state;
    notifyListeners();
    if (_webViewController == null || !_isReady) return;

    try {
      final escaped = jsonEncode(state.name);
      await _webViewController?.runJavaScript('window.setState($escaped);');
    } catch (e) {
      debugPrint('[MascotController] Error setting state: $e');
    }
  }

  Future<void> setEmotion(MascotEmotion emotion) async {
    _currentEmotion = emotion;
    notifyListeners();
    if (_webViewController == null || !_isReady) return;

    try {
      final escaped = jsonEncode(emotion.name);
      await _webViewController?.runJavaScript('window.setEmotion($escaped);');
    } catch (e) {
      debugPrint('[MascotController] Error setting emotion: $e');
    }
  }

  Future<void> setMouthLevel(double level) async {
    final clamped = level.clamp(0.0, 1.0);
    _currentMouthLevel = clamped;

    final now = DateTime.now();
    if (now.difference(_lastMouthUpdateTime).inMilliseconds < _minMouthUpdateIntervalMs) {
      return;
    }
    _lastMouthUpdateTime = now;

    if (_webViewController == null || !_isReady) return;

    try {
      final formatted = clamped.toStringAsFixed(3);
      await _webViewController?.runJavaScript('window.setMouthLevel($formatted);');
    } catch (e) {
      // Ignore background race errors during page reload
    }
  }
}
