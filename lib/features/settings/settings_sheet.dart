import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsSheet(),
    );
  }

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;

  bool _obscureApiKey = true;
  late String _selectedVoice;
  late bool _echoCancellation;
  late bool _noiseSuppression;
  late InterruptionSensitivity _sensitivity;
  late bool _noisyEnvironment;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: AppConfig.apiKey);
    _modelController = TextEditingController(text: AppConfig.selectedModel);
    _selectedVoice = AppConfig.selectedVoice;
    _echoCancellation = AppConfig.echoCancellation;
    _noiseSuppression = AppConfig.noiseSuppression;
    _sensitivity = AppConfig.interruptionSensitivity;
    _noisyEnvironment = AppConfig.noisyEnvironmentMode;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    AppConfig.apiKey = _apiKeyController.text.trim();
    AppConfig.selectedModel = _modelController.text.trim().isNotEmpty
        ? _modelController.text.trim()
        : AppConfig.defaultModelId;
    AppConfig.selectedVoice = _selectedVoice;
    AppConfig.echoCancellation = _echoCancellation;
    AppConfig.noiseSuppression = _noiseSuppression;
    AppConfig.interruptionSensitivity = _sensitivity;
    AppConfig.noisyEnvironmentMode = _noisyEnvironment;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ARENA SETTINGS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Gemini API Key
            Text(
              'GEMINI API KEY',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              style: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter Gemini API key...',
                hintStyle: GoogleFonts.ibmPlexSans(fontSize: 13, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Interruption Sensitivity
            Text(
              'INTERRUPTION SENSITIVITY',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: InterruptionSensitivity.values.map((s) {
                final isSelected = s == _sensitivity;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _sensitivity = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.accent : AppColors.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            s.label,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? AppColors.accent : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Noisy Environment Toggle
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Noisy Environment Mode',
                        style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Disables auto-barge-in; requires tap to handoff or interrupt',
                        style: GoogleFonts.ibmPlexSans(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _noisyEnvironment,
                  activeThumbColor: AppColors.accent,
                  onChanged: (val) => setState(() => _noisyEnvironment = val),
                ),
              ],
            ),

            // Voice Selector
            Text(
              'OPPONENT VOICE',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedVoice,
              dropdownColor: AppColors.surfaceElevated,
              style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              items: AppConfig.availableVoices.map((voice) {
                return DropdownMenuItem<String>(
                  value: voice,
                  child: Text(voice),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedVoice = val);
              },
            ),
            const SizedBox(height: 16),

            // Model ID
            Text(
              'LIVE MODEL ID',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: AppConfig.supportedLiveModels.contains(_modelController.text)
                  ? _modelController.text
                  : AppConfig.defaultModelId,
              dropdownColor: AppColors.surfaceElevated,
              style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              items: AppConfig.supportedLiveModels.map((model) {
                return DropdownMenuItem<String>(
                  value: model,
                  child: Text(
                    model == AppConfig.defaultModelId ? '$model (Default)' : model,
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _modelController.text = val);
                }
              },
            ),

            const SizedBox(height: 20),

            // Save CTA
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('SAVE SETTINGS'),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
