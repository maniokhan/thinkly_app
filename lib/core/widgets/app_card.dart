import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool isRaised;
  final bool isSelected;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.m),
    this.onTap,
    this.isRaised = false,
    this.isSelected = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final border = isSelected
        ? const BorderSide(color: AppColors.accent, width: 1.5)
        : const BorderSide(color: AppColors.hairlineBorder, width: 1.0);

    final card = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: isRaised ? AppColors.raisedSurface : AppColors.surface,
        borderRadius: AppRadius.radiusM,
        border: Border.fromBorderSide(border),
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusM,
        splashColor: Colors.transparent,
        highlightColor: Colors.white.withAlpha(10),
        child: card,
      ),
    );
  }
}
