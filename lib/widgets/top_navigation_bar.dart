import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/env/env_config.dart';
import '../core/theme/app_theme.dart';
import '../features/mindmap/providers/mind_map_provider.dart';
import '../features/mindmap/widgets/saved_lectures_drawer.dart';
import '../features/mindmap/widgets/pdf_preview_dialog.dart';
import 'api_key_settings_dialog.dart';

class TopNavigationBar extends StatelessWidget {
  const TopNavigationBar({super.key});

  void _showSavedLecturesModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: 440,
          height: 600,
          child: SavedLecturesDrawer(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvConfig>();
    final mindMap = context.watch<MindMapProvider>();
    final savedCount = mindMap.savedLectures.length;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Thinkly Brand Logo & Tag
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.cardElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderRoot),
                ),
                child: const Center(
                  child: Text(
                    'T',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.alabaster,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Thinkly',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.pillTag,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'AI CLASS NOTES',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.textPill,
                  ),
                ),
              ),
            ],
          ),

          // Center: Active Lecture Topic Badge
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        mindMap.currentSession.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right Controls: PDF Export, Saved Library & Settings
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. One-Click PDF Notes Export
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PdfPreviewDialog(
                      session: mindMap.currentSession,
                    ),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 14, color: AppColors.alabasterText),
                label: const Text('Export PDF', style: TextStyle(fontSize: 11.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.alabaster,
                  foregroundColor: AppColors.alabasterText,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              const SizedBox(width: 10),

              // 2. Saved Lectures Modal Button
              InkWell(
                onTap: () => _showSavedLecturesModal(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_open_rounded, size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      const Text(
                        'Saved',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      if (savedCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.pillTag,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Text(
                            '$savedCount',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 3. Gemini Key / Model Pill (Clickable)
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const ApiKeySettingsDialog(),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    env.isConfigured ? env.model : 'Set Gemini Key',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // 4. Settings Cog Icon Button
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 19, color: AppColors.textSecondary),
                tooltip: 'API Key & Companion Settings',
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const ApiKeySettingsDialog(),
                ),
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
