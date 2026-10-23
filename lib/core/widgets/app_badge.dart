import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBadge extends StatelessWidget {
  final String text;
  final bool isAccent;
  final bool isDestructive;
  final bool isLive;

  const AppBadge({
    super.key,
    required this.text,
    this.isAccent = false,
    this.isDestructive = false,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    Color fg;
    Color bg;
    BorderSide border;

    if (isLive) {
      fg = AppColors.statusLive;
      bg = AppColors.statusLive.withAlpha(25);
      border = const BorderSide(color: AppColors.statusLive, width: 0.8);
    } else if (isAccent) {
      fg = AppColors.accent;
      bg = AppColors.accent.withAlpha(25);
      border = const BorderSide(color: AppColors.accent, width: 0.8);
    } else if (isDestructive) {
      fg = AppColors.destructive;
      bg = AppColors.destructiveBg;
      border = const BorderSide(color: AppColors.destructive, width: 0.8);
    } else {
      fg = AppColors.secondaryText;
      bg = AppColors.raisedSurface;
      border = const BorderSide(color: AppColors.hairlineBorder, width: 0.8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.fromBorderSide(border),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: fg,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
