import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
  }) : variant = AppButtonVariant.destructive;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Color bgColor;
    Color fgColor;
    BorderSide borderSide;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bgColor = isDisabled ? AppColors.accent.withAlpha(120) : AppColors.accent;
        fgColor = AppColors.accentText;
        borderSide = BorderSide.none;
        break;
      case AppButtonVariant.secondary:
        bgColor = isDisabled ? AppColors.raisedSurface.withAlpha(120) : AppColors.raisedSurface;
        fgColor = isDisabled ? AppColors.secondaryText : AppColors.primaryText;
        borderSide = const BorderSide(color: AppColors.hairlineBorder, width: 1.0);
        break;
      case AppButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = isDisabled ? AppColors.secondaryText : AppColors.primaryText;
        borderSide = BorderSide.none;
        break;
      case AppButtonVariant.destructive:
        bgColor = AppColors.destructiveBg;
        fgColor = AppColors.destructive;
        borderSide = const BorderSide(color: AppColors.destructive, width: 1.0);
        break;
    }

    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: fgColor),
          const SizedBox(width: AppSpacing.s),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTypography.fontHeading,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: fgColor,
            ),
          ),
        ),
      ],
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusM,
          side: borderSide,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isDisabled ? null : widget.onPressed,
          onTapDown: (_) {
            if (!isDisabled) _pressController.forward();
          },
          onTapUp: (_) {
            if (!isDisabled) _pressController.reverse();
          },
          onTapCancel: () {
            if (!isDisabled) _pressController.reverse();
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.white.withAlpha(12),
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );
  }
}
