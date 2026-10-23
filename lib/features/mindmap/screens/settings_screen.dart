import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/env/env_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_badge.dart';

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
      const SnackBar(
        content: Text('Settings saved successfully'),
        duration: Duration(seconds: 2),
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.radiusS,
                      border: Border.all(color: AppColors.hairlineBorder),
                    ),
                    child: const Icon(Icons.settings_outlined, color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: AppTypography.titleLarge,
                        ),
                        Text(
                          'AI Engine & App Preferences',
                          style: AppTypography.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),

              // SECTION 1: Gemini AI Engine
              _buildSectionCard(
                index: 0,
                title: 'Gemini AI Engine',
                icon: Icons.auto_awesome,
                iconColor: AppColors.accent,
                children: [
                  const Text(
                    'Google Gemini API Key',
                    style: TextStyle(
                      fontFamily: AppTypography.fontHeading,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Used for live classroom speech synthesis, concept mapping, and notes generation.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureText,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontMono,
                      fontSize: 13,
                      color: AppColors.primaryText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'AIzaSy...',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppColors.secondaryText,
                        ),
                        onPressed: () => setState(() => _obscureText = !_obscureText),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Model Selector
                  const Text(
                    'Active AI Model',
                    style: TextStyle(
                      fontFamily: AppTypography.fontHeading,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: _models.map((model) {
                      final isSelected = _selectedModel == model;
                      return ChoiceChip(
                        label: Text(
                          model,
                          style: TextStyle(
                            fontFamily: AppTypography.fontMono,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            letterSpacing: 0.5,
                            color: isSelected ? AppColors.accentText : AppColors.secondaryText,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.accent,
                        backgroundColor: AppColors.surface,
                        elevation: 0,
                        side: BorderSide(
                          color: isSelected ? AppColors.accent : AppColors.hairlineBorder,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedModel = model);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Test Connection & Status
                  if (_testResult != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.s),
                      decoration: BoxDecoration(
                        color: _testSuccess ? AppColors.statusLive.withAlpha(20) : AppColors.destructiveBg,
                        borderRadius: AppRadius.radiusS,
                        border: Border.all(
                          color: _testSuccess ? AppColors.statusLive : AppColors.destructive,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _testSuccess ? Icons.check_circle : Icons.error_outline,
                            color: _testSuccess ? AppColors.statusLive : AppColors.destructive,
                            size: 16,
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Text(
                              _testResult!,
                              style: AppTypography.bodySmall.copyWith(
                                color: _testSuccess ? AppColors.statusLive : AppColors.destructive,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                  ],

                  // Action Buttons
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: [
                      AppButton.secondary(
                        label: _isTesting ? 'Testing...' : 'Test Connection',
                        icon: Icons.network_check_rounded,
                        isLoading: _isTesting,
                        height: 42,
                        onPressed: _isTesting ? null : _testConnection,
                      ),
                      AppButton.ghost(
                        label: 'Reset to .env',
                        icon: Icons.refresh_rounded,
                        height: 42,
                        onPressed: () async {
                          await env.resetToEnv();
                          _apiKeyController.text = env.apiKey;
                          setState(() {
                            _selectedModel = EnvConfig.sanitizeModel(env.model);
                            _testResult = null;
                          });
                        },
                      ),
                      AppButton.primary(
                        label: 'Save Changes',
                        icon: Icons.save_rounded,
                        height: 42,
                        onPressed: _saveSettings,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),

              // SECTION 2: Audio & Microphone
              _buildSectionCard(
                index: 1,
                title: 'Live Classroom Audio',
                icon: Icons.mic_rounded,
                iconColor: AppColors.statusLive,
                children: [
                  _buildSettingRow(
                    icon: Icons.mic_external_on_rounded,
                    title: 'Microphone Sensitivity',
                    subtitle: 'Automatic gain control enabled for lecture halls',
                    trailing: const AppBadge(text: 'OPTIMIZED', isLive: true),
                  ),
                  const Divider(color: AppColors.hairlineBorder, height: 20),
                  _buildSettingRow(
                    icon: Icons.record_voice_over_rounded,
                    title: 'Speech Recognition Engine',
                    subtitle: 'Device Speech API with Gemini Fallback synthesis',
                    trailing: const AppBadge(text: 'HYBRID AI', isAccent: true),
                  ),
                  const Divider(color: AppColors.hairlineBorder, height: 20),
                  _buildSettingRow(
                    icon: Icons.offline_bolt_rounded,
                    title: 'Simulated Lecture Mode',
                    subtitle: 'Full offline simulation of Operating Systems lectures',
                    trailing: const AppBadge(text: 'READY'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),

              // SECTION 3: Notes & PDF Engine
              _buildSectionCard(
                index: 2,
                title: 'PDF & Notes Engine',
                icon: Icons.picture_as_pdf_rounded,
                iconColor: AppColors.primaryText,
                children: [
                  _buildSettingRow(
                    icon: Icons.format_size_rounded,
                    title: 'Academic Document Format',
                    subtitle: 'ISO 216 standard formatted for print & reading',
                    trailing: const AppBadge(text: 'A4 PORTRAIT'),
                  ),
                  const Divider(color: AppColors.hairlineBorder, height: 20),
                  _buildSettingRow(
                    icon: Icons.style_rounded,
                    title: 'Active Recall Flashcards',
                    subtitle: 'Automatically generates Q&A study cards for exam prep',
                    trailing: const AppBadge(text: 'INCLUDED', isAccent: true),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),

              // SECTION 4: System Information
              _buildSectionCard(
                index: 3,
                title: 'System & Device Info',
                icon: Icons.phone_android_rounded,
                iconColor: AppColors.secondaryText,
                children: [
                  _buildSettingRow(
                    icon: Icons.touch_app_rounded,
                    title: 'App Version',
                    subtitle: 'Thinkly Mobile Edition v1.0.0+1',
                    trailing: const AppBadge(text: 'PRODUCTION'),
                  ),
                  const Divider(color: AppColors.hairlineBorder, height: 20),
                  _buildSettingRow(
                    icon: Icons.verified_user_rounded,
                    title: 'Target Platform',
                    subtitle: 'Android 15+ / Pixel 9 Pro Architecture',
                    trailing: const AppBadge(text: 'ARM64-V8A', isLive: true),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
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
    int index = 0,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusM,
        border: Border.all(color: AppColors.hairlineBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          ...children,
        ],
      ),
    ).animate(delay: (index * 40).ms).fade(duration: 200.ms, curve: Curves.easeOut).slideY(begin: 0.04, end: 0, duration: 200.ms, curve: Curves.easeOut);
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondaryText),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTypography.fontHeading,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        trailing,
      ],
    );
  }
}
