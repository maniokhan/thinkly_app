import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/env/env_config.dart';
import '../core/theme/app_theme.dart';
import '../core/services/gemini_service.dart';

class ApiKeySettingsDialog extends StatefulWidget {
  const ApiKeySettingsDialog({super.key});

  @override
  State<ApiKeySettingsDialog> createState() => _ApiKeySettingsDialogState();
}

class _ApiKeySettingsDialogState extends State<ApiKeySettingsDialog> {
  late TextEditingController _apiKeyController;
  late String _selectedModel;
  bool _obscureText = true;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final env = EnvConfig();
    _apiKeyController = TextEditingController(text: env.apiKey);
    _selectedModel = EnvConfig.sanitizeModel(env.model);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final testKey = _apiKeyController.text.trim();
    if (testKey.isEmpty) {
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult = 'Please enter an API key to test.';
      });
      return;
    }

    try {
      await EnvConfig().updateConfig(apiKey: testKey, model: _selectedModel);
      final gemini = GeminiAiService();
      final res = await gemini.extractMindMapDelta(
        transcriptChunk: 'Today we discuss computer systems architecture and latency.',
        existingNodes: [],
        rootTopic: 'Systems Architecture',
      );

      setState(() {
        _isTesting = false;
        _testSuccess = true;
        _testResult = 'Connection successful! Extracted ${res.actions.length} graph actions from Gemini.';
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult = 'Connection test note: $e. Simulated Demo mode works offline without any key!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvConfig>();
    final models = <String>{
      'gemini-3.8-flash',
      'gemini-3.5-flash-lite',
      'gemini-3.5-flash',
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
      'gemini-2.0-flash',
      _selectedModel,
    }.toList();

    if (!models.contains(_selectedModel)) {
      _selectedModel = models.first;
    }

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.pillTag,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.settings_suggest_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'API Key & Companion Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // API Key Field
              const Text(
                'Gemini API Key',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _apiKeyController,
                obscureText: _obscureText,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'AIzaSy...',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Used for real-time concept extraction, mind map generation, and study guide summaries.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),

              const SizedBox(height: 18),

              // Model Selection
              const Text(
                'Gemini Model',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedModel,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    items: models.map((model) {
                      return DropdownMenuItem(
                        value: model,
                        child: Text(model),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedModel = val);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Auto-PiP Switch Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_in_picture_alt_rounded, size: 20, color: AppColors.textPrimary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto-enable PiP when switching tabs',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Automatically opens the floating companion when you switch tabs during a lecture',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: env.autoPipEnabled,
                      activeThumbColor: AppColors.alabaster,
                      onChanged: (val) {
                        env.setAutoPipEnabled(val);
                      },
                    ),
                  ],
                ),
              ),

              if (_testResult != null) ...[
                const SizedBox(height: 14),
                Text(
                  _testResult!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _testSuccess ? AppColors.emerald : AppColors.amber,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await env.resetToDefault();
                      _apiKeyController.text = env.apiKey;
                      setState(() {
                        _selectedModel = EnvConfig.sanitizeModel(env.model);
                        _testResult = 'Reset to .env default configuration.';
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reset to .env'),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isTesting ? null : _testConnection,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textPrimary,
                                ),
                              )
                            : const Icon(Icons.flash_on_rounded, size: 16),
                        label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await env.updateConfig(
                            apiKey: _apiKeyController.text.trim(),
                            model: _selectedModel,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('API Configuration Saved!'),
                                backgroundColor: AppColors.emerald,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
