import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnvConfig extends ChangeNotifier {
  static final EnvConfig _instance = EnvConfig._internal();
  factory EnvConfig() => _instance;
  EnvConfig._internal();

  static const String _keyStorageKey = 'thinkly_gemini_api_key';
  static const String _modelStorageKey = 'thinkly_gemini_model';
  static const String _autoPipStorageKey = 'thinkly_auto_pip_enabled';
  static const String defaultModel = 'gemini-3.8-flash';

  String _apiKey = '';
  String _model = defaultModel;
  bool _autoPipEnabled = true;
  bool _isInitialized = false;

  String get apiKey => _apiKey;
  String get model => _model;
  bool get autoPipEnabled => _autoPipEnabled;
  bool get isInitialized => _isInitialized;

  /// Returns true if API key is valid and not a placeholder
  bool get isConfigured {
    if (_apiKey.isEmpty) return false;
    final lower = _apiKey.toLowerCase();
    if (lower.contains('youractualgeminiapikey') ||
        lower.contains('placeholder') ||
        lower == 'aizasydummykey' ||
        _apiKey.length < 15) {
      return false;
    }
    return true;
  }

  static const Set<String> supportedModels = {
    'gemini-3.8-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.5-flash',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
  };

  static String sanitizeModel(String? model) {
    if (model == null || model.trim().isEmpty) return defaultModel;
    final trimmed = model.trim();
    if (supportedModels.contains(trimmed)) {
      return trimmed;
    }
    return defaultModel;
  }

  Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('[EnvConfig] .env not loaded or missing: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final storedKey = prefs.getString(_keyStorageKey);
    final storedModel = prefs.getString(_modelStorageKey);

    if (storedKey != null && storedKey.isNotEmpty) {
      _apiKey = storedKey;
    } else {
      _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    }

    final rawModel = (storedModel != null && storedModel.isNotEmpty)
        ? storedModel
        : (dotenv.env['GEMINI_MODEL'] ?? defaultModel);
    _model = sanitizeModel(rawModel);

    _autoPipEnabled = prefs.getBool(_autoPipStorageKey) ?? true;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setAutoPipEnabled(bool value) async {
    _autoPipEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoPipStorageKey, value);
    notifyListeners();
  }

  Future<void> updateConfig({required String apiKey, String? model}) async {
    _apiKey = apiKey.trim();
    if (model != null && model.isNotEmpty) {
      _model = sanitizeModel(model);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStorageKey, _apiKey);
    await prefs.setString(_modelStorageKey, _model);

    notifyListeners();
  }

  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStorageKey);
    await prefs.remove(_modelStorageKey);

    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = dotenv.env['GEMINI_MODEL'] ?? defaultModel;

    notifyListeners();
  }

  Future<void> resetToEnv() => resetToDefault();
}
