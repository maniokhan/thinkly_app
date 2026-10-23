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
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget content = Container(
      constraints: const BoxConstraints(maxWidth: 580),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isMobile ? 24 : 16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle for mobile sheet
          if (isMobile)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderRoot,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.mic_rounded, color: AppColors.alabaster, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Select Audio Source',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
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
                    ctx: context,
                    title: 'Share YouTube / Meet Tab Audio',
                    subtitle: 'Captures live audio directly from any YouTube video or Google Meet lecture tab.',
                    icon: Icons.tab_rounded,
                    badge: 'LIVE TAB AUDIO',
                    badgeColor: AppColors.cyan,
                    onTap: () {
                      Navigator.pop(context);
                      final provider = context.read<MindMapProvider>();
                      provider.startLiveLectureSession();
                      speech.setMode(SpeechMode.tabAudio);
                      speech.startListening();
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildModeOptionTile(
                    ctx: context,
                    title: 'Live Classroom Microphone',
                    subtitle: 'Continuously transcribes instructor speech in an in-person physical classroom or hall.',
                    icon: Icons.mic_external_on_rounded,
                    badge: 'IN-PERSON MIC',
                    badgeColor: AppColors.emerald,
                    onTap: () {
                      Navigator.pop(context);
                      final provider = context.read<MindMapProvider>();
                      provider.startLiveLectureSession();
                      speech.setMode(SpeechMode.liveMicrophone);
                      speech.startListening();
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildModeOptionTile(
                    ctx: context,
                    title: 'Simulated University Lecture (Instant Demo)',
                    subtitle: 'Instant offline live simulation: ${speech.selectedLecture.topic} (${speech.selectedLecture.course}).',
                    icon: Icons.school_rounded,
                    badge: 'INSTANT DEMO',
                    badgeColor: AppColors.amber,
                    onTap: () {
                      Navigator.pop(context);
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
    );

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => content,
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: content,
        ),
      );
    }
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.pillTag,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.pillTag,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.3,
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget content = StatefulBuilder(
      builder: (context, setState) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(isMobile ? 20 : 14),
            border: Border.all(color: AppColors.border),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMobile)
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.borderRoot,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                const Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: AppColors.textPrimary, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Add Manual Concept Node',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add a concept or instructor note to the active branch.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  autofocus: true,
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
                    hintText: 'Core mechanism or key takeaway...',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Category: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(width: 6),
                        DropdownButton<NodeCategory>(
                          value: selectedCategory,
                          dropdownColor: AppColors.card,
                          underline: const SizedBox.shrink(),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isTakeaway,
                          activeColor: AppColors.alabaster,
                          checkColor: AppColors.alabasterText,
                          onChanged: (v) => setState(() => isTakeaway = v ?? false),
                        ),
                        const Flexible(
                          child: Text(
                            'Flag as Exam Key Takeaway',
                            style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
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
                        Navigator.pop(context);
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
    );

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            left: 12,
            right: 12,
            top: 12,
          ),
          child: content,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: content,
        ),
      );
    }
  }

  void _showGenerateFromTopicDialog(BuildContext context) {
    final provider = context.read<MindMapProvider>();
    final controller = TextEditingController();
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget content = Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isMobile ? 20 : 14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.borderRoot,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          const Row(
            children: [
              Icon(Icons.video_library_rounded, color: AppColors.rose, size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Generate from YouTube / Topic',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter any YouTube lecture URL or academic topic to synthesize an instant knowledge graph & notes:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'e.g. Distributed Consensus & Paxos Protocol',
              prefixIcon: Icon(Icons.link_rounded, size: 18, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(context);
                  provider.generateFromYoutubeOrTopic(text);
                },
                icon: const Icon(Icons.auto_awesome, size: 14),
                label: const Text('Generate Map'),
              ),
            ],
          ),
        ],
      ),
    );

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            left: 12,
            right: 12,
            top: 12,
          ),
          child: content,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: content,
        ),
      );
    }
  }

  void _showSaveAndExportMenu(BuildContext context) {
    final provider = context.read<MindMapProvider>();
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget content = Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(isMobile ? 24 : 16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 24 : 16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          if (isMobile)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.borderRoot,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4C2222)),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.rose, size: 18),
            ),
            title: const Text(
              'Export Class Notes as PDF Document',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
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
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => PdfPreviewDialog(
                  session: provider.currentSession,
                ),
              );
            },
          ),

          const Divider(color: AppColors.border, height: 1),

          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.pillTag,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.auto_stories_rounded, color: AppColors.alabaster, size: 18),
            ),
            title: const Text(
              'View AI Study Guide & Flashcards',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
            ),
            subtitle: const Text(
              'Gemini synthesizes knowledge graph + notes into interactive markdown flashcards.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            onTap: () async {
              Navigator.pop(context);
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

          const Divider(color: AppColors.border, height: 1),

          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF14241B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E3B2C)),
              ),
              child: const Icon(Icons.bookmark_add_rounded, color: AppColors.emerald, size: 18),
            ),
            title: const Text(
              'Save Map to Local Library',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
            ),
            subtitle: const Text(
              'Saves graph, hierarchy, and student notes to device storage.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            onTap: () async {
              Navigator.pop(context);
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

          const Divider(color: AppColors.border, height: 1),

          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.pillTag,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.code_rounded, color: AppColors.cyan, size: 18),
            ),
            title: const Text('Copy Graph JSON', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
            subtitle: const Text('Export raw graph data structure to clipboard.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            onTap: () {
              Navigator.pop(context);
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
  );

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => content,
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: content,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final speech = context.watch<SpeechService>();
    final mindMap = context.watch<MindMapProvider>();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.hairlineBorder, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Primary Hero Audio Button
                if (speech.isListening)
                  ElevatedButton.icon(
                    onPressed: () => speech.stopListening(),
                    icon: const Icon(Icons.stop_circle_rounded, size: 16),
                    label: Text(
                      'Stop (${speech.captureElapsedSeconds}s)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A1515),
                      foregroundColor: AppColors.rose,
                      side: const BorderSide(color: Color(0xFF4C2222)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _showAudioModePicker(context),
                    icon: const Icon(Icons.mic_rounded, size: 15),
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Start Live Class', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_drop_down_rounded, size: 15),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.alabaster,
                      foregroundColor: AppColors.alabasterText,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),

                const SizedBox(width: 4),

                // 2. Topic / URL
                TextButton.icon(
                  onPressed: () => _showGenerateFromTopicDialog(context),
                  icon: const Icon(Icons.auto_awesome, size: 14, color: AppColors.textPrimary),
                  label: const Text('Topic / URL', style: TextStyle(fontSize: 11.5)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),

                const SizedBox(width: 2),

                // 3. Add Node
                TextButton.icon(
                  onPressed: () => _showAddManualNodeDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: const Text('Add Node', style: TextStyle(fontSize: 11.5)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),

                const SizedBox(width: 2),

                // 4. PDF Notes
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => PdfPreviewDialog(
                        session: mindMap.currentSession,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF261919),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF482525)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf_rounded, size: 13, color: AppColors.rose),
                        SizedBox(width: 4),
                        Text(
                          'PDF Notes',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.rose,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 2),

                // 5. Export
                TextButton.icon(
                  onPressed: () => _showSaveAndExportMenu(context),
                  icon: const Icon(Icons.bookmark_border_rounded, size: 15),
                  label: const Text('Export', style: TextStyle(fontSize: 11.5)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),

                const SizedBox(width: 2),

                Container(height: 16, width: 1, color: AppColors.border),

                const SizedBox(width: 2),

                // 6. Floating PiP
                InkWell(
                  onTap: () async {
                    await mindMap.openExternalPip();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.picture_in_picture_alt_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Floating PiP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
