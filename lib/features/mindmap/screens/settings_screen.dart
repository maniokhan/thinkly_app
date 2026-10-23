import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/env/env_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/gemini_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late String _selectedModel;
  bool _obscureText = true;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  final List<String> _models = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  @override
  void initState() {
    super.initState();
    final env = EnvConfig();
    _apiKeyController = TextEditingController(text: env.apiKey);
    _selectedModel = EnvConfig.sanitizeModel(env.model);
    if (!_models.contains(_selectedModel)) {
      _models.insert(0, _selectedModel);
    }
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
        _testResult = 'Please enter an API key to test connection.';
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
        _testResult = 'Connection successful! Extracted ${res.actions.length} actions from Gemini.';
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult = 'Connection note: $e. Simulated demo lectures work offline without any key!';
      });
    }
  }

  Future<void> _saveSettings() async {
    final key = _apiKeyController.text.trim();
    await EnvConfig().updateConfig(
      apiKey: key,
      model: _selectedModel,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.accentEmerald, size: 18),
            SizedBox(width: 8),
            Text('Settings saved successfully'),
          ],
        ),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvConfig>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.settings_outlined, color: AppColors.accentIndigo, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'AI Engine & App Preferences',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // SECTION 1: Gemini AI Engine
              _buildSectionCard(
                title: 'Gemini AI Engine',
                icon: Icons.auto_awesome,
                iconColor: AppColors.accentViolet,
                children: [
                  const Text(
                    'Google Gemini API Key',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Used for live classroom speech synthesis, concept mapping, and notes generation.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureText,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: 'AIzaSy...',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscureText = !_obscureText),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Model Selector
                  const Text(
                    'Active AI Model',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _models.map((model) {
                      final isSelected = _selectedModel == model;
                      return ChoiceChip(
                        label: Text(
                          model,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.accentIndigo.withAlpha(64),
                        backgroundColor: AppColors.card,
                        side: BorderSide(
                          color: isSelected ? AppColors.accentIndigo : AppColors.border,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedModel = model);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Test Connection & Status
                  if (_testResult != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _testSuccess ? AppColors.accentEmerald.withAlpha(30) : AppColors.accentRose.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _testSuccess ? AppColors.accentEmerald : AppColors.accentRose,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _testSuccess ? Icons.check_circle : Icons.error_outline,
                            color: _testSuccess ? AppColors.accentEmerald : AppColors.accentRose,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _testResult!,
                              style: TextStyle(
                                color: _testSuccess ? AppColors.accentEmerald : AppColors.accentRose,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Action Buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isTesting ? null : _testConnection,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentIndigo),
                              )
                            : const Icon(Icons.network_check_rounded, size: 16),
                        label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await env.resetToEnv();
                          _apiKeyController.text = env.apiKey;
                          setState(() {
                            _selectedModel = EnvConfig.sanitizeModel(env.model);
                            _testResult = null;
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Reset to .env'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 2: Audio & Microphone
              _buildSectionCard(
                title: 'Live Classroom Audio',
                icon: Icons.mic_rounded,
                iconColor: AppColors.accentAmber,
                children: [
                  _buildSettingRow(
                    icon: Icons.mic_external_on_rounded,
                    title: 'Microphone Sensitivity',
                    subtitle: 'Automatic gain control enabled for lecture halls',
                    trailing: const Text(
                      'Optimized',
                      style: TextStyle(color: AppColors.accentEmerald, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  _buildSettingRow(
                    icon: Icons.record_voice_over_rounded,
                    title: 'Speech Recognition Engine',
                    subtitle: 'Device Speech API with Gemini Fallback synthesis',
                    trailing: const Text(
                      'Hybrid AI',
                      style: TextStyle(color: AppColors.accentViolet, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  _buildSettingRow(
                    icon: Icons.offline_bolt_rounded,
                    title: 'Simulated Lecture Mode',
                    subtitle: 'Full offline simulation of Operating Systems lectures',
                    trailing: const Text(
                      'Ready',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 3: Notes & PDF Engine
              _buildSectionCard(
                title: 'PDF & Notes Engine',
                icon: Icons.picture_as_pdf_rounded,
                iconColor: AppColors.accentRose,
                children: [
                  _buildSettingRow(
                    icon: Icons.format_size_rounded,
                    title: 'Academic Document Format',
                    subtitle: 'ISO 216 standard formatted for print & reading',
                    trailing: const Text(
                      'A4 Portrait',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  _buildSettingRow(
                    icon: Icons.style_rounded,
                    title: 'Active Recall Flashcards',
                    subtitle: 'Automatically generates Q&A study cards for exam prep',
                    trailing: const Text(
                      'Included',
                      style: TextStyle(color: AppColors.accentEmerald, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 4: System Information
              _buildSectionCard(
                title: 'System & Device Info',
                icon: Icons.phone_android_rounded,
                iconColor: AppColors.accentTeal,
                children: [
                  _buildSettingRow(
                    icon: Icons.touch_app_rounded,
                    title: 'App Version',
                    subtitle: 'Thinkly Mobile Edition v1.0.0+1',
                    trailing: const Text(
                      'Production',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  _buildSettingRow(
                    icon: Icons.verified_user_rounded,
                    title: 'Target Platform',
                    subtitle: 'Android 15+ / Pixel 9 Pro Architecture',
                    trailing: const Text(
                      'ARM64-v8a',
                      style: TextStyle(color: AppColors.accentEmerald, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }
}
