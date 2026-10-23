import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SoundWaveVisualizer extends StatefulWidget {
  final double level; // 0.0 to 1.0
  final bool isActive;
  final Color? color;
  final int barCount;
  final double height;

  const SoundWaveVisualizer({
    super.key,
    required this.level,
    this.isActive = true,
    this.color,
    this.barCount = 28,
    this.height = 48,
  });

  @override
  State<SoundWaveVisualizer> createState() => _SoundWaveVisualizerState();
}

class _SoundWaveVisualizerState extends State<SoundWaveVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? AppColors.primary;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              // Sine wave modulation across the bars
              final phase = (_animController.value * 2 * math.pi) + (index * 0.28);
              final wave = (math.sin(phase) + 1.0) / 2.0;

              // Combined height derived from volume level & gentle idle wave
              final dynamicFactor = widget.isActive
                  ? (0.15 + (widget.level * 0.85 * wave))
                  : 0.08;

              final barHeight = (widget.height * dynamicFactor).clamp(4.0, widget.height);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.2),
                width: 3.5,
                height: barHeight,
                decoration: BoxDecoration(
                  color: activeColor.withValues(
                    alpha: widget.isActive ? (0.45 + (widget.level * 0.55)) : 0.25,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
