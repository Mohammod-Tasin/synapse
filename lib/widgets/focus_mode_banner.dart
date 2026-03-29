import 'package:flutter/material.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

/// Focus mode active banner (calm organic feel).
class FocusModeBanner extends StatelessWidget {
  final int remainingMinutes;
  const FocusModeBanner({required this.remainingMinutes, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.softCard(color: AppTheme.inputFillColor),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMd),
                bottomLeft: Radius.circular(AppTheme.radiusMd),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.center_focus_strong_rounded,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Focus Mode Active',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$remainingMinutes min remaining',
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
        ],
      ),
    );
  }
}
