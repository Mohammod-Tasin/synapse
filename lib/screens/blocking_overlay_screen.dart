library;

import 'package:flutter/material.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

class BlockingOverlayScreen extends StatelessWidget {
  const BlockingOverlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.86),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.block,
                    color: AppTheme.errorColor,
                    size: 48,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    'Reels/Shorts Blocked',
                    style: AppTheme.headingSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Short-form video is blocked to protect your focus.',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Continue Focus'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
