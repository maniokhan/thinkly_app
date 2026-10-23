import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLoader extends StatelessWidget {
  final String? message;

  const AppLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 2,
            child: LinearProgressIndicator(
              backgroundColor: AppColors.raisedSurface,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.m),
            Text(
              message!,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
