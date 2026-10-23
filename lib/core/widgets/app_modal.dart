import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppModal {
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
          border: Border(
            top: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
            left: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
            right: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.s),
            // Minimal drag handle
            Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.hairlineBorder,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }

  static Future<T?> showAppDialog<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.radiusL,
          side: BorderSide(color: AppColors.hairlineBorder, width: 1.0),
        ),
        child: child,
      ),
    );
  }
}
