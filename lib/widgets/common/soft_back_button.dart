import 'package:flutter/material.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

/// Soft back arrow button.
class SoftBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const SoftBackButton({this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).pop(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.inputFillColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }
}
