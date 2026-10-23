import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/speech_service.dart';
import '../models/mind_map_node.dart';
import '../providers/mind_map_provider.dart';
import 'study_guide_dialog.dart';
import 'pdf_preview_dialog.dart';

class FloatingDock extends StatelessWidget {
  const FloatingDock({super.key});

  void _showAudioModePicker(BuildContext context) {
    final speech = context.read<SpeechService>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            maxWidth: 620,
          ),
          margin: const EdgeInsets.all(16),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.hub_rounded, color: AppColors.alabaster, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Start Live Class • Select Input Mode',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose how Thinkly captures your lecture to generate real-time mind maps & PDF notes:',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeOptionTile(
                            ctx: ctx,
                            title: 'Share YouTube / Meet Tab Audio',
                            subtitle: 'Captures live audio stream directly from any YouTube video or Google Meet lecture tab.',
                            icon: Icons.tab_rounded,
                            badge: 'LIVE TAB AUDIO',
                            badgeColor: AppColors.textPrimary,
                            onTap: () {
                              Navigator.pop(ctx);
                              final provider = context.read<MindMapProvider>();
                              provider.startLiveLectureSession();
                              speech.setMode(SpeechMode.tabAudio);
                              speech.startListening();
                            },
                          ),

                          const SizedBox(height: 10),

                          _buildModeOptionTile(
                            ctx: ctx,
                            title: 'Live Classroom Microphone',
                            subtitle: 'Continuously transcribes instructor speech in an in-person physical classroom or seminar.',
                            icon: Icons.mic_external_on_rounded,
                            badge: 'IN-PERSON MIC',
                            badgeColor: AppColors.cyan,
                            onTap: () {
                              Navigator.pop(ctx);
                              final provider = context.read<MindMapProvider>();
                              provider.startLiveLectureSession();
                              speech.setMode(SpeechMode.liveMicrophone);
                              speech.startListening();
                            },
                          ),

                          const SizedBox(height: 10),

                          _buildModeOptionTile(
                            ctx: ctx,
                            title: 'Simulated University Lecture (Instant Demo)',
                            subtitle: 'Instant offline live simulation: ${speech.selectedLecture.topic} (${speech.selectedLecture.course}).',
                            icon: Icons.school_rounded,
                            badge: 'INSTANT DEMO',
                            badgeColor: AppColors.emerald,
                            onTap: () {
                              Navigator.pop(ctx);
                              final provider = context.read<MindMapProvider>();
                              provider.startNewLecture(speech.selectedLecture.topic);
                              speech.setMode(SpeechMode.simulation);
                              speech.startListening();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeOptionTile({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.pillTag,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.pillTag,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddManualNodeDialog(BuildContext context) {
    final provider = context.read<MindMapProvider>();
    final titleController = TextEditingController();
    final summaryController = TextEditingController();
    NodeCategory selectedCategory = NodeCategory.coreConcept;
    bool isTakeaway = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Container(
              width: 440,
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Manual Concept Node',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manually add a concept or teacher note to the active branch.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Concept Title',
                      hintText: 'e.g. Asymmetric Cryptography',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: summaryController,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Explanation / Summary',
                      hintText: 'Core mechanism or operational nuance...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Category: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      DropdownButton<NodeCategory>(
                        value: selectedCategory,
                        dropdownColor: AppColors.surface,
                        items: NodeCategory.values
                            .where((c) => c != NodeCategory.root)
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.displayName, style: const TextStyle(fontSize: 12)),
                                ))
                            .toList(),
                        onChanged: (cat) {
                          if (cat != null) setState(() => selectedCategory = cat);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: isTakeaway,
                        activeColor: AppColors.alabaster,
                        checkColor: AppColors.alabasterText,
                        onChanged: (v) => setState(() => isTakeaway = v ?? false),
                      ),
                      const Text(
                        'Flag as Exam Key Takeaway',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;
                          provider.addManualNode(
                            title: titleController.text.trim(),
                            summary: summaryController.text.trim().isNotEmpty
                                ? summaryController.text.trim()
                                : null,
                            category: selectedCategory,
                            isKeyTakeaway: isTakeaway,
                          );
                          Navigator.pop(ctx);
                        },
                        child: const Text('Add Node'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showGenerateFromTopicDialog(BuildContext context) {
    final provider = context.read<MindMapProvider>();
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.video_library_rounded, color: AppColors.rose, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Generate from YouTube / Topic',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter any YouTube video lecture URL or academic topic to synthesize an instant knowledge graph & notes:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'e.g. Distributed Consensus & Paxos Protocol',
                  prefixIcon: Icon(Icons.link_rounded, size: 18, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      final text = controller.text.trim();
                      if (text.isEmpty) return;
                      Navigator.pop(ctx);
                      provider.generateFromYoutubeOrTopic(text);
                    },
                    icon: const Icon(Icons.auto_awesome, size: 14),
                    label: const Text('Generate Map'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaveAndExportMenu(BuildContext context) {
    final provider = context.read<MindMapProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            maxWidth: 620,
          ),
          margin: const EdgeInsets.all(16),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E1A1A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF4C2222)),
                              ),
                              child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.rose, size: 20),
                            ),
                            title: const Text(
                              'Export Class Notes as PDF Document',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            subtitle: const Text(
                              'Generates a formatted academic PDF with summary, concepts, student notes, and flashcards.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.pillTag,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('PDF', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.rose)),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              showDialog(
                                context: context,
                                builder: (_) => PdfPreviewDialog(
                                  session: provider.currentSession,
                                ),
                              );
                            },
                          ),

                          const Divider(color: AppColors.border),

                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.pillTag,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(Icons.auto_stories_rounded, color: AppColors.alabaster, size: 20),
                            ),
                            title: const Text(
                              'View AI Study Guide & Flashcards',
                              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            subtitle: const Text(
                              'Gemini synthesizes knowledge graph + notes into interactive markdown flashcards.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            onTap: () async {
                              Navigator.pop(ctx);
                              final guide = await provider.generateStudyGuide();
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (_) => StudyGuideDialog(
                                    title: provider.currentSession.title,
                                    markdownContent: guide,
                                  ),
                                );
                              }
                            },
                          ),

                          const Divider(color: AppColors.border),

                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14241B),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF1E3B2C)),
                              ),
                              child: const Icon(Icons.bookmark_add_rounded, color: AppColors.emerald, size: 20),
                            ),
                            title: const Text(
                              'Save Map to Local Library',
                              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            subtitle: const Text(
                              'Saves graph, hierarchy, and student notes to device storage.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await provider.saveCurrentLecture();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Mind Map successfully saved to library!'),
                                    backgroundColor: AppColors.cardElevated,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),

                          const Divider(color: AppColors.border),

                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.pillTag,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(Icons.code_rounded, color: AppColors.cyan, size: 20),
                            ),
                            title: const Text('Copy Graph JSON', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            subtitle: const Text('Export raw graph data structure to clipboard.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            onTap: () {
                              Navigator.pop(ctx);
                              final jsonStr = const JsonEncoder.withIndent('  ').convert(provider.currentSession.toJson());
                              Clipboard.setData(ClipboardData(text: jsonStr));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mind Map JSON copied to clipboard!'),
                                  backgroundColor: AppColors.cardElevated,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final speech = context.watch<SpeechService>();
    final mindMap = context.watch<MindMapProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (speech.isListening)
                ElevatedButton.icon(
                  onPressed: () => speech.stopListening(),
                  icon: const Icon(Icons.pause_circle_filled_rounded, size: 16),
                  label: const Text('Listening (Stop)', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.graphiteBtn,
                    foregroundColor: AppColors.rose,
                    side: const BorderSide(color: AppColors.graphiteBtnBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _showAudioModePicker(context),
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Start Live Class', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down_rounded, size: 16),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alabaster,
                    foregroundColor: AppColors.alabasterText,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),

              const SizedBox(width: 6),

              TextButton.icon(
                onPressed: () => _showGenerateFromTopicDialog(context),
                icon: const Icon(Icons.auto_awesome, size: 15, color: AppColors.textPrimary),
                label: const Text('Topic / URL', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),

              const SizedBox(width: 4),

              TextButton.icon(
                onPressed: () => _showAddManualNodeDialog(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Node', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),

              const SizedBox(width: 4),

              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => PdfPreviewDialog(
                      session: mindMap.currentSession,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF261919),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF482525)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf_rounded, size: 14, color: AppColors.rose),
                      SizedBox(width: 5),
                      Text(
                        'PDF Notes',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.rose,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 4),

              TextButton.icon(
                onPressed: () => _showSaveAndExportMenu(context),
                icon: const Icon(Icons.bookmark_border_rounded, size: 16),
                label: const Text('Export', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),

              const SizedBox(width: 4),

              Container(height: 20, width: 1, color: AppColors.border),

              const SizedBox(width: 4),

              Tooltip(
                message: 'Pop out always-on-top floating PiP companion',
                child: InkWell(
                  onTap: () async {
                    await mindMap.openExternalPip();
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.picture_in_picture_alt_rounded,
                          size: 15,
                          color: AppColors.textPrimary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Floating PiP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
