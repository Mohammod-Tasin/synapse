import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:no_to_distraction/services/accessibility_permission_service.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

/// Missing permissions card.
class MissingPermissionsCard extends StatelessWidget {
  final PermissionSnapshot snapshot;
  final Future<void> Function() onOpenAccessibility;
  final Future<void> Function() onOpenOverlay;
  final Future<void> Function() onOpenUsageAccess;
  final Future<void> Function() onOpenBatteryOptimization;
  final Future<void> Function() onRequestNotification;
  final Future<void> Function() onOpenAutoStart;
  final Future<void> Function() onRefresh;

  const MissingPermissionsCard({
    required this.snapshot,
    required this.onOpenAccessibility,
    required this.onOpenOverlay,
    required this.onOpenUsageAccess,
    required this.onOpenBatteryOptimization,
    required this.onRequestNotification,
    required this.onOpenAutoStart,
    required this.onRefresh,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final missing = <_PermissionAction>[];
    if (!snapshot.accessibilityEnabled) {
      missing.add(
        _PermissionAction(
          title: 'Accessibility Permission',
          buttonLabel: 'Enable',
          onTap: onOpenAccessibility,
        ),
      );
    }
    if (!snapshot.overlayEnabled) {
      missing.add(
        _PermissionAction(
          title: 'Overlay Permission',
          buttonLabel: 'Enable',
          onTap: onOpenOverlay,
        ),
      );
    }
    if (!snapshot.usageAccessEnabled) {
      missing.add(
        _PermissionAction(
          title: 'Usage Access',
          buttonLabel: 'Enable',
          onTap: onOpenUsageAccess,
        ),
      );
    }
    if (!snapshot.batteryOptimizationIgnored) {
      missing.add(
        _PermissionAction(
          title: 'Battery Optimization Exemption',
          hint: 'Set to: No Restriction',
          buttonLabel: 'Allow',
          onTap: onOpenBatteryOptimization,
        ),
      );
    }
    if (!snapshot.notificationEnabled) {
      missing.add(
        _PermissionAction(
          title: 'Notification Permission',
          buttonLabel: 'Allow',
          onTap: onRequestNotification,
        ),
      );
    }
    if (!snapshot.autoStartEnabled) {
      missing.add(
        _PermissionAction(
          title: 'Auto-Start Permission',
          buttonLabel: 'Enable',
          onTap: onOpenAutoStart,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warningColor,
                size: 18,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'Missing Permissions',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          for (final item in missing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: AppTheme.bodySmall),
                        if (item.hint != null)
                          Text(
                            item.hint!,
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async => item.onTap(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      textStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    child: Text(item.buttonLabel),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondaryColor,
              textStyle: GoogleFonts.inter(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionAction {
  final String title;
  final String buttonLabel;
  final String? hint;
  final Future<void> Function() onTap;

  _PermissionAction({
    required this.title,
    required this.buttonLabel,
    required this.onTap,
    this.hint,
  });
}
