import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PulseMicButton extends StatefulWidget {
  final bool isMuted;
  final bool isListening;
  final VoidCallback onTap;
  final double size;

  const PulseMicButton({
    super.key,
    required this.isMuted,
    required this.isListening,
    required this.onTap,
    this.size = 64,
  });

  @override
  State<PulseMicButton> createState() => _PulseMicButtonState();
}

class _PulseMicButtonState extends State<PulseMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isMuted ? AppColors.error : AppColors.primary;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return SizedBox(
          width: widget.size * 1.6,
          height: widget.size * 1.6,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ripple Ring 1
              if (widget.isListening && !widget.isMuted)
                Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.55),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withValues(
                          alpha: (1.0 - _pulseController.value) * 0.45,
                        ),
                        width: 2.5,
                      ),
                    ),
                  ),
                ),

              // Outer Ripple Ring 2 (delayed phase)
              if (widget.isListening && !widget.isMuted)
                Transform.scale(
                  scale: 1.0 + (((_pulseController.value + 0.5) % 1.0) * 0.4),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withValues(
                          alpha: (1.0 - ((_pulseController.value + 0.5) % 1.0)) * 0.35,
                        ),
                        width: 1.8,
                      ),
                    ),
                  ),
                ),

              // Core Button
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: widget.onTap,
                  customBorder: const CircleBorder(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: widget.isMuted
                            ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                            : [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.38),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.isMuted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        color: Colors.white,
                        size: widget.size * 0.48,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
