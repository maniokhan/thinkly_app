import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/env/env_config.dart';
import '../core/theme/app_theme.dart';
import '../core/services/gemini_service.dart';
import '../core/widgets/app_button.dart';

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
        _testResult = 'Connection note: $e. Simulated Demo mode works offline without any key!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvConfig>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

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
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.radiusL,
        side: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 16 : 32,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.raisedSurface,
                            borderRadius: AppRadius.radiusS,
                            border: Border.all(color: AppColors.hairlineBorder),
                          ),
                          child: const Icon(
                            Icons.settings_suggest_rounded,
                            color: AppColors.primaryText,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        const Flexible(
                          child: Text(
                            'API Key & Settings',
                            style: AppTypography.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppColors.secondaryText),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Configure your Google Gemini API key to enable live speech extraction & academic notes synthesis:',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.m),

              // API Key input
              TextField(
                controller: _apiKeyController,
                obscureText: _obscureText,
                style: const TextStyle(
                  fontFamily: AppTypography.fontMono,
                  fontSize: 12.5,
                  color: AppColors.primaryText,
                ),
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
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

              // Model selector
              const Text(
                'Active Gemini Model',
                style: TextStyle(
                  fontFamily: AppTypography.fontHeading,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: models.map((m) {
                  final isSelected = _selectedModel == m;
                  return ChoiceChip(
                    label: Text(
                      m,
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
                      if (val) setState(() => _selectedModel = m);
                    },
                  );
                }).toList(),
              ),

              if (_testResult != null) ...[
                const SizedBox(height: AppSpacing.m),
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
                    children: [
                      Icon(
                        _testSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded,
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
              ],

              const SizedBox(height: AppSpacing.l),

              // Action buttons
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  AppButton.ghost(
                    label: 'Reset to .env',
                    height: 40,
                    onPressed: () async {
                      await env.resetToDefault();
                      _apiKeyController.text = env.apiKey;
                      setState(() {
                        _selectedModel = EnvConfig.sanitizeModel(env.model);
                        _testResult = null;
                      });
                    },
                  ),
                  AppButton.secondary(
                    label: _isTesting ? 'Testing...' : 'Test Connection',
                    isLoading: _isTesting,
                    height: 40,
                    onPressed: _isTesting ? null : _testConnection,
                  ),
                  AppButton.primary(
                    label: 'Save Changes',
                    height: 40,
                    onPressed: () async {
                      await env.updateConfig(
                        apiKey: _apiKeyController.text.trim(),
                        model: _selectedModel,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
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
