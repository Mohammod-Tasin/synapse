library;

import 'package:flutter/material.dart';
import 'package:no_to_distraction/screens/home_screen.dart';
import 'package:no_to_distraction/services/accessibility_permission_service.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  final AccessibilityPermissionService _permissionService =
      AccessibilityPermissionService();

  PermissionSnapshot? _snapshot;
  bool _isLoading = true;
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  Future<void> _refreshAll() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _permissionService.getSnapshot();
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _runAction(Future<bool> Function() action) async {
    setState(() {
      _isActionInProgress = true;
    });

    try {
      final ok = await action();
      if (!mounted) {
        return;
      }
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open permission page.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
        });
        await _refreshAll();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    if (_isLoading || snapshot == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (snapshot.allRequiredGranted) {
      return const HomeScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Grant Required Permissions'),
        actions: [
          IconButton(
            onPressed: _isActionInProgress ? null : _refreshAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To block Reels/Shorts reliably in background, allow all required permissions below.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            _PermissionTile(
              title: 'Accessibility Service',
              subtitle: 'Core detector service. Must be enabled manually.',
              granted: snapshot.accessibilityEnabled,
              actionLabel: 'Open Settings',
              isBusy: _isActionInProgress,
              onAction: () =>
                  _runAction(_permissionService.openAccessibilitySettings),
            ),
            _PermissionTile(
              title: 'Display Over Other Apps',
              subtitle: 'Required to show blocking overlay over target apps.',
              granted: snapshot.overlayEnabled,
              actionLabel: 'Grant Overlay',
              isBusy: _isActionInProgress,
              onAction: () =>
                  _runAction(_permissionService.openOverlaySettings),
            ),
            _PermissionTile(
              title: 'Usage Access',
              subtitle: 'Detect foreground app transitions.',
              granted: snapshot.usageAccessEnabled,
              actionLabel: 'Grant Usage Access',
              isBusy: _isActionInProgress,
              onAction: () =>
                  _runAction(_permissionService.openUsageAccessSettings),
            ),
            _PermissionTile(
              title: 'Ignore Battery Optimizations',
              subtitle:
                  'Prevents Android Doze from killing long-running service.',
              granted: snapshot.batteryOptimizationIgnored,
              actionLabel: 'Allow Ignore',
              isBusy: _isActionInProgress,
              onAction: () => _runAction(
                _permissionService.openBatteryOptimizationSettings,
              ),
            ),
            _PermissionTile(
              title: 'Notification Permission (Android 13+)',
              subtitle:
                  'Needed for persistent notification while service runs.',
              granted: snapshot.notificationEnabled,
              actionLabel: 'Allow Notification',
              isBusy: _isActionInProgress,
              onAction: () =>
                  _runAction(_permissionService.requestNotificationPermission),
            ),
            _PermissionTile(
              title: 'Auto-Start (Optional)',
              subtitle: 'Helpful for Xiaomi/Oppo/Vivo/Realme devices.',
              granted: false,
              actionLabel: 'Open Vendor Page',
              isOptional: true,
              isBusy: _isActionInProgress,
              onAction: () =>
                  _runAction(_permissionService.openAutoStartSettings),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isActionInProgress ? null : _refreshAll,
                icon: const Icon(Icons.verified),
                label: const Text('Re-check All Permissions'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool granted;
  final String actionLabel;
  final bool isOptional;
  final bool isBusy;
  final VoidCallback onAction;

  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.actionLabel,
    required this.isBusy,
    required this.onAction,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = granted ? AppTheme.successColor : AppTheme.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                granted ? Icons.check_circle : Icons.error_outline,
                color: statusColor,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  isOptional ? '$title (Optional)' : title,
                  style: AppTheme.headingSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(subtitle, style: AppTheme.bodySmall),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            granted ? 'Status: Granted' : 'Status: Not granted',
            style: AppTheme.bodySmall.copyWith(color: statusColor),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: isBusy ? null : onAction,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
