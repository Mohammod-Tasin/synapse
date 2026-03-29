import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

class ReelsCard extends StatelessWidget {
  final bool blockFbReels;
  final bool blockInstaReels;
  final bool blockYtShorts;
  final bool isFbReelsLocked;
  final bool isInstaReelsLocked;
  final bool isYtShortsLocked;
  final int fbLockRemainingHours;
  final int instaLockRemainingHours;
  final int ytLockRemainingHours;
  final bool isDisabled;
  final ValueChanged<bool> onFbReelsChanged;
  final ValueChanged<bool> onInstaReelsChanged;
  final ValueChanged<bool> onYtShortsChanged;

  const ReelsCard({
    required this.blockFbReels,
    required this.blockInstaReels,
    required this.blockYtShorts,
    required this.isFbReelsLocked,
    required this.isInstaReelsLocked,
    required this.isYtShortsLocked,
    required this.fbLockRemainingHours,
    required this.instaLockRemainingHours,
    required this.ytLockRemainingHours,
    required this.isDisabled,
    required this.onFbReelsChanged,
    required this.onInstaReelsChanged,
    required this.onYtShortsChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: AppTheme.softCard(radius: AppTheme.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: AppTheme.accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  'Block Reels & Shorts',
                  style: AppTheme.headingSmall,
                ),
              ),
              if (isDisabled)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isFbReelsLocked || isInstaReelsLocked || isYtShortsLocked
                ? '48-hour lock is active for enabled platform(s).'
                : 'Toggle platforms to enable protection.',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _ReelsToggleRow(
            platformName: 'Facebook Reels',
            value: blockFbReels,
            isLocked: isFbReelsLocked,
            remainingHours: fbLockRemainingHours,
            isDisabled: isDisabled,
            onChanged: onFbReelsChanged,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _ReelsToggleRow(
            platformName: 'Instagram Reels',
            value: blockInstaReels,
            isLocked: isInstaReelsLocked,
            remainingHours: instaLockRemainingHours,
            isDisabled: isDisabled,
            onChanged: onInstaReelsChanged,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _ReelsToggleRow(
            platformName: 'YouTube Shorts',
            value: blockYtShorts,
            isLocked: isYtShortsLocked,
            remainingHours: ytLockRemainingHours,
            isDisabled: isDisabled,
            onChanged: onYtShortsChanged,
          ),
        ],
      ),
    );
  }
}

/// Single reels toggle row with lock indicator.
class _ReelsToggleRow extends StatelessWidget {
  final String platformName;
  final bool value;
  final bool isLocked;
  final int remainingHours;
  final bool isDisabled;
  final ValueChanged<bool> onChanged;

  const _ReelsToggleRow({
    required this.platformName,
    required this.value,
    required this.isLocked,
    required this.remainingHours,
    required this.isDisabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(platformName, style: AppTheme.bodyLarge),
              if (isLocked)
                Row(
                  children: [
                    Icon(
                      Icons.lock_clock,
                      size: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Locked · ${remainingHours}h remaining',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
            ],
          ),
        ),
        Transform.scale(
          scale: 0.85,
          child: CupertinoSwitch(
            value: value,
            onChanged: (isDisabled || isLocked) ? null : onChanged,
            activeTrackColor: AppTheme.primaryColor,
            thumbColor: CupertinoDynamicColor.withBrightness(
              color: Colors.white,
              darkColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
