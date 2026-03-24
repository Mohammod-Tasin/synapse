/// Home screen displayed after successful login and onboarding.
library;

import 'package:flutter/material.dart';
import 'package:no_to_distraction/models/stats.dart';
import 'package:provider/provider.dart';
import 'package:no_to_distraction/providers/auth_provider.dart';
import 'package:no_to_distraction/services/accessibility_permission_service.dart';
import 'package:no_to_distraction/services/api_service.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AccessibilityPermissionService _permissionService =
      AccessibilityPermissionService();
  final ApiService _apiService = ApiService();
  static const Color _warningColor = Color(0xFFF59E0B);

  PermissionSnapshot? _permissionSnapshot;
  bool _isCheckingPermissions = true;
  bool _isLoadingBlockToggles = true;
  bool _isSavingBlockToggles = false;
  bool _blockFbReels = false;
  bool _blockInstaReels = false;
  bool _blockYtShorts = false;
  bool _isFbReelsLocked = false;
  bool _isInstaReelsLocked = false;
  bool _isYtShortsLocked = false;
  int _fbLockRemainingHours = 0;
  int _instaLockRemainingHours = 0;
  int _ytLockRemainingHours = 0;

  // Focus mode state
  bool _focusModeActive = false;
  int _focusModeRemainingMinutes = 0;

  TodayStats? _todayStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissionSnapshot();
    _loadBlockToggles();
    _loadFocusModeStatus();
    _loadTodayStats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionSnapshot();
      _loadBlockToggles();
      _loadFocusModeStatus();
      _loadTodayStats();
    }
  }

  Future<void> _loadTodayStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await _apiService.getTodayStats();
      if (!mounted) {
        return;
      }
      setState(() {
        _todayStats = stats;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _todayStats = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _refreshPermissionSnapshot() async {
    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      final snapshot = await _permissionService.getSnapshot();
      if (!mounted) {
        return;
      }
      setState(() {
        _permissionSnapshot = snapshot;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _permissionSnapshot = const PermissionSnapshot(
          accessibilityEnabled: false,
          overlayEnabled: false,
          usageAccessEnabled: false,
          batteryOptimizationIgnored: false,
          notificationEnabled: false,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPermissions = false;
        });
      }
    }
  }

  Future<void> _openAccessibilitySettings() async {
    final opened = await _permissionService.openAccessibilitySettings();
    if (!mounted) {
      return;
    }

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Accessibility settings.')),
      );
    }
  }

  Future<void> _loadBlockToggles() async {
    setState(() {
      _isLoadingBlockToggles = true;
    });

    try {
      final toggles = await _permissionService.getReelsBlockToggles();
      final lockStatus = await _permissionService.getReelsLockStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _blockFbReels = toggles['block_fb_reels'] ?? false;
        _blockInstaReels = toggles['block_insta_reels'] ?? false;
        _blockYtShorts = toggles['block_yt_shorts'] ?? false;
        _isFbReelsLocked = lockStatus['fbLocked'] as bool? ?? false;
        _isInstaReelsLocked = lockStatus['instaLocked'] as bool? ?? false;
        _isYtShortsLocked = lockStatus['ytLocked'] as bool? ?? false;
        _fbLockRemainingHours = lockStatus['fbRemainingHours'] as int? ?? 0;
        _instaLockRemainingHours =
            lockStatus['instaRemainingHours'] as int? ?? 0;
        _ytLockRemainingHours = lockStatus['ytRemainingHours'] as int? ?? 0;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _blockFbReels = false;
        _blockInstaReels = false;
        _blockYtShorts = false;
        _isFbReelsLocked = false;
        _isInstaReelsLocked = false;
        _isYtShortsLocked = false;
        _fbLockRemainingHours = 0;
        _instaLockRemainingHours = 0;
        _ytLockRemainingHours = 0;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBlockToggles = false;
        });
      }
    }
  }

  Future<void> _persistBlockToggles() async {
    setState(() {
      _isSavingBlockToggles = true;
    });

    try {
      final ok = await _permissionService.setReelsBlockToggles(
        blockFbReels: _blockFbReels,
        blockInstaReels: _blockInstaReels,
        blockYtShorts: _blockYtShorts,
      );

      if (!mounted) {
        return;
      }

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save blocking toggles.')),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save blocking toggles.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingBlockToggles = false;
        });
      }
    }
  }

  Future<void> _loadFocusModeStatus() async {
    try {
      final status = await _permissionService.getFocusModeStatus();
      if (!mounted) return;

      setState(() {
        _focusModeActive = status['isActive'] as bool? ?? false;
        _focusModeRemainingMinutes = status['remainingMinutes'] as int? ?? 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _focusModeActive = false;
        _focusModeRemainingMinutes = 0;
      });
    }
  }

  Future<void> _startFocusMode(int durationMinutes) async {
    try {
      final success = await _permissionService.startFocusMode(
        durationMinutes: durationMinutes,
      );

      if (!mounted) return;

      if (success) {
        try {
          await _apiService.logFocusSession(durationMinutes: durationMinutes);
        } catch (_) {
          // Ignore point logging failure for now. Session has started locally.
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Focus mode started for $durationMinutes minutes'),
          ),
        );
        _loadFocusModeStatus();
        _loadTodayStats();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start focus mode')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<List<String>> _getSelectedDistractingAppNames() async {
    final selectedPackages = await _permissionService.getDistractingApps();
    if (selectedPackages.isEmpty) {
      return <String>[];
    }

    final installedAppsRaw = await _permissionService.getInstalledApps();
    final appNameByPackage = <String, String>{};
    for (final item in installedAppsRaw) {
      if (item is Map<Object?, Object?>) {
        final packageName = (item['packageName'] as String?)?.trim() ?? '';
        final appName = (item['appName'] as String?)?.trim() ?? '';
        if (packageName.isNotEmpty) {
          appNameByPackage[packageName] = appName.isEmpty
              ? packageName
              : appName;
        }
      }
    }

    return selectedPackages.map((pkg) => appNameByPackage[pkg] ?? pkg).toList();
  }

  Future<List<String>> _openDistractingAppsManagerAndReload() async {
    await Navigator.of(context).pushNamed('/distracting-apps');
    return _getSelectedDistractingAppNames();
  }

  Future<void> _showFocusDurationPicker() async {
    final selectedApps = await _getSelectedDistractingAppNames();
    if (!mounted) {
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => FocusDurationPicker(
        selectedDistractingApps: selectedApps,
        onManageApps: _openDistractingAppsManagerAndReload,
        onDurationSelected: _startFocusMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('No to Distraction'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingMd),
            child: Center(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return GestureDetector(
                    onTap: () {
                      showMenu<String>(
                        context: context,
                        position: const RelativeRect.fromLTRB(100, 80, 0, 0),
                        items: <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'profile',
                            child: Text('Profile'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'settings',
                            child: Text('Settings'),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Text('Logout'),
                          ),
                        ],
                      ).then((value) {
                        if (value == 'logout') {
                          authProvider.logout();
                        }
                      });
                    },
                    child: const CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isCheckingPermissions)
                  const Center(child: CircularProgressIndicator())
                else if (_permissionSnapshot != null &&
                    !_permissionSnapshot!.allRequiredGranted) ...[
                  _MissingPermissionsCard(
                    snapshot: _permissionSnapshot!,
                    onOpenAccessibility: _openAccessibilitySettings,
                    onOpenOverlay: () async {
                      await _permissionService.openOverlaySettings();
                    },
                    onOpenUsageAccess: () async {
                      await _permissionService.openUsageAccessSettings();
                    },
                    onOpenBatteryOptimization: () async {
                      await _permissionService
                          .openBatteryOptimizationSettings();
                    },
                    onRequestNotification: () async {
                      await _permissionService.requestNotificationPermission();
                    },
                    onRefresh: _refreshPermissionSnapshot,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                ],

                Container(
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
                          const Expanded(
                            child: Text(
                              'Block Reels and Shorts',
                              style: AppTheme.headingSmall,
                            ),
                          ),
                          if (_isLoadingBlockToggles || _isSavingBlockToggles)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        _isFbReelsLocked ||
                                _isInstaReelsLocked ||
                                _isYtShortsLocked
                            ? '48-hour lock applies only to blocked platform(s).'
                            : 'Enable platform-wise protection. Blocking starts only for enabled apps.',
                        style: AppTheme.bodySmall,
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      SwitchListTile.adaptive(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _isFbReelsLocked
                              ? 'Facebook Reels (Locked ${_fbLockRemainingHours}h)'
                              : 'Facebook Reels',
                        ),
                        value: _blockFbReels,
                        onChanged:
                            _isLoadingBlockToggles ||
                                _isSavingBlockToggles ||
                                _isFbReelsLocked
                            ? null
                            : (value) async {
                                setState(() {
                                  _blockFbReels = value;
                                });
                                await _persistBlockToggles();
                              },
                      ),
                      SwitchListTile.adaptive(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _isInstaReelsLocked
                              ? 'Instagram Reels (Locked ${_instaLockRemainingHours}h)'
                              : 'Instagram Reels',
                        ),
                        value: _blockInstaReels,
                        onChanged:
                            _isLoadingBlockToggles ||
                                _isSavingBlockToggles ||
                                _isInstaReelsLocked
                            ? null
                            : (value) async {
                                setState(() {
                                  _blockInstaReels = value;
                                });
                                await _persistBlockToggles();
                              },
                      ),
                      SwitchListTile.adaptive(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _isYtShortsLocked
                              ? 'YouTube Shorts (Locked ${_ytLockRemainingHours}h)'
                              : 'YouTube Shorts',
                        ),
                        value: _blockYtShorts,
                        onChanged:
                            _isLoadingBlockToggles ||
                                _isSavingBlockToggles ||
                                _isYtShortsLocked
                            ? null
                            : (value) async {
                                setState(() {
                                  _blockYtShorts = value;
                                });
                                await _persistBlockToggles();
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Focus mode status
                if (_focusModeActive)
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.schedule, color: Colors.blue),
                            const SizedBox(width: AppTheme.spacingSm),
                            const Expanded(
                              child: Text(
                                'Focus Mode Active',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          'Time remaining: $_focusModeRemainingMinutes min',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                if (_focusModeActive)
                  const SizedBox(height: AppTheme.spacingLg),

                // Welcome card
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${user?.name}! 👋',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      const Text(
                        'Ready to focus today?',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        _isLoadingStats
                            ? 'Loading points...'
                            : 'Total Points: ${_todayStats?.totalPoints ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),

                if (!_isLoadingStats && _todayStats != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today at a Glance',
                          style: AppTheme.headingSmall,
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          'Focus: ${_todayStats!.focusSessionsCount} sessions, ${_todayStats!.focusMinutes} min (+${_todayStats!.focusPointsGained})',
                          style: AppTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Blocks: ${_todayStats!.blockScreensCount} (-${_todayStats!.pointsLost})',
                          style: AppTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Net today: ${_todayStats!.netPointsToday}',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                ],

                // Quick actions
                const Text('Quick Actions', style: AppTheme.headingSmall),
                const SizedBox(height: AppTheme.spacingMd),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppTheme.spacingMd,
                  mainAxisSpacing: AppTheme.spacingMd,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _ActionCard(
                      icon: Icons.timer,
                      title: 'Start Focus',
                      subtitle: 'Begin a session',
                      onTap: _showFocusDurationPicker,
                    ),
                    _ActionCard(
                      icon: Icons.timeline,
                      title: 'Today\'s Stats',
                      subtitle: 'View progress',
                      onTap: () {
                        Navigator.of(context).pushNamed('/today-stats');
                      },
                    ),
                    _ActionCard(
                      icon: Icons.apps,
                      title: 'Distracting Apps',
                      subtitle: 'Manage app list',
                      onTap: () {
                        Navigator.of(context).pushNamed('/distracting-apps');
                      },
                    ),
                    _ActionCard(
                      icon: Icons.settings,
                      title: 'Quick Block',
                      subtitle: 'Pick apps + duration',
                      onTap: () {
                        Navigator.of(context).pushNamed('/quick-block');
                      },
                    ),
                    _ActionCard(
                      icon: Icons.insights,
                      title: 'Analytics',
                      subtitle: 'Weekly report',
                      onTap: () {
                        Navigator.of(context).pushNamed('/analytics');
                      },
                    ),
                    _ActionCard(
                      icon: Icons.emoji_events,
                      title: 'Leaderboard',
                      subtitle: 'See top users',
                      onTap: () {
                        Navigator.of(context).pushNamed('/leaderboard');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Focus tips
                const Text('Focus Tips', style: AppTheme.headingSmall),
                const SizedBox(height: AppTheme.spacingMd),
                _TipCard(
                  title: 'Use the Pomodoro Technique',
                  subtitle: 'Work for 25 minutes, then take a 5-minute break.',
                  icon: Icons.lightbulb_outline,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _TipCard(
                  title: 'Eliminate Distractions',
                  subtitle: 'Turn off notifications during focus sessions.',
                  icon: Icons.do_not_disturb,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MissingPermissionsCard extends StatelessWidget {
  final PermissionSnapshot snapshot;
  final Future<void> Function() onOpenAccessibility;
  final Future<void> Function() onOpenOverlay;
  final Future<void> Function() onOpenUsageAccess;
  final Future<void> Function() onOpenBatteryOptimization;
  final Future<void> Function() onRequestNotification;
  final Future<void> Function() onRefresh;

  const _MissingPermissionsCard({
    required this.snapshot,
    required this.onOpenAccessibility,
    required this.onOpenOverlay,
    required this.onOpenUsageAccess,
    required this.onOpenBatteryOptimization,
    required this.onRequestNotification,
    required this.onRefresh,
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

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: _HomeScreenState._warningColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: _HomeScreenState._warningColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: _HomeScreenState._warningColor,
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text('Missing Permissions', style: AppTheme.bodyLarge),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          for (final item in missing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(item.title, style: AppTheme.bodySmall)),
                  ElevatedButton(
                    onPressed: () async {
                      await item.onTap();
                    },
                    child: Text(item.buttonLabel),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppTheme.spacingSm),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _PermissionAction {
  final String title;
  final String buttonLabel;
  final Future<void> Function() onTap;

  _PermissionAction({
    required this.title,
    required this.buttonLabel,
    required this.onTap,
  });
}

/// Reusable action card for quick actions.
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              title,
              style: AppTheme.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              subtitle,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable tip card.
class _TipCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _TipCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.bodyLarge),
                const SizedBox(height: AppTheme.spacingSm),
                Text(subtitle, style: AppTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FocusDurationPicker extends StatefulWidget {
  final List<String> selectedDistractingApps;
  final Future<List<String>> Function() onManageApps;
  final Function(int) onDurationSelected;

  const FocusDurationPicker({
    required this.selectedDistractingApps,
    required this.onManageApps,
    required this.onDurationSelected,
    super.key,
  });

  @override
  State<FocusDurationPicker> createState() => _FocusDurationPickerState();
}

class _FocusDurationPickerState extends State<FocusDurationPicker> {
  int _selectedDuration = 25;
  bool _isRefreshingApps = false;
  late List<String> _selectedApps;

  @override
  void initState() {
    super.initState();
    _selectedApps = List<String>.from(widget.selectedDistractingApps);
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours h';
    }
    return '$hours h $mins min';
  }

  Future<void> _manageApps() async {
    setState(() {
      _isRefreshingApps = true;
    });

    try {
      final updatedApps = await widget.onManageApps();
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedApps = updatedApps;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingApps = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start Focus Mode'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
          maxWidth: 420,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select focus duration:'),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                _formatDuration(_selectedDuration),
                style: AppTheme.headingSmall,
              ),
              Slider(
                value: _selectedDuration.toDouble(),
                min: 5,
                max: 720,
                divisions: 143,
                label: _formatDuration(_selectedDuration),
                onChanged: (value) {
                  setState(() {
                    _selectedDuration = value.toInt();
                  });
                },
              ),
              const SizedBox(height: AppTheme.spacingSm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final duration in [
                      15,
                      25,
                      45,
                      60,
                      90,
                      120,
                      180,
                      360,
                      720,
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_formatDuration(duration)),
                          selected: _selectedDuration == duration,
                          onSelected: (_) {
                            setState(() {
                              _selectedDuration = duration;
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected distracting apps',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    if (_selectedApps.isEmpty)
                      const Text(
                        'No app selected yet. You can continue anyway.',
                        style: AppTheme.bodySmall,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedApps
                            .map(
                              (name) => Chip(
                                label: Text(name),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextButton.icon(
                      onPressed: _isRefreshingApps ? null : _manageApps,
                      icon: _isRefreshingApps
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.edit),
                      label: const Text('Manage App List'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'During focus mode:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: AppTheme.spacingSm),
                    Text(
                      '✓ Reels and Shorts will be blocked',
                      style: AppTheme.bodySmall,
                    ),
                    Text(
                      '✓ Selected distracting apps will be blocked',
                      style: AppTheme.bodySmall,
                    ),
                    Text(
                      '✓ Motivational quotes will be shown',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onDurationSelected(_selectedDuration);
            Navigator.pop(context);
          },
          child: const Text('Start Focus'),
        ),
      ],
    );
  }
}
