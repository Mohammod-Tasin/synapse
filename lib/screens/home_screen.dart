/// Synapse — Neuro-Minimalist Home Screen.
/// All business logic preserved; only UI/presentation layer revamped.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:no_to_distraction/models/stats.dart';
import 'package:no_to_distraction/providers/auth_provider.dart';
import 'package:no_to_distraction/services/accessibility_permission_service.dart';
import 'package:no_to_distraction/services/api_service.dart';
import 'package:no_to_distraction/theme/app_theme.dart';
import 'package:no_to_distraction/widgets/welcome_card.dart';
import 'package:no_to_distraction/widgets/reels_card.dart';
import 'package:no_to_distraction/widgets/focus_duration_picker.dart';
import 'package:no_to_distraction/widgets/focus_mode_banner.dart';
import 'package:no_to_distraction/widgets/glance_card.dart';
import 'package:no_to_distraction/widgets/missing_permissions_card.dart';
import 'package:no_to_distraction/widgets/quick_actions_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AccessibilityPermissionService _permissionService =
      AccessibilityPermissionService();
  final ApiService _apiService = ApiService();

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

  bool _focusModeActive = false;
  int _focusModeRemainingMinutes = 0;

  TodayStats? _todayStats;
  bool _isLoadingStats = true;

  // Tips PageView controller
  final PageController _tipsController = PageController();
  int _currentTipPage = 0;

  static const List<_TipData> _tips = [
    _TipData(
      icon: Icons.timer_rounded,
      title: 'Pomodoro Technique',
      body: 'Work 25 minutes, rest 5. Your brain will thank you.',
      color: AppTheme.primaryColor,
    ),
    _TipData(
      icon: Icons.do_not_disturb_on_rounded,
      title: 'Eliminate Distractions',
      body: 'Turn off notifications during focus sessions.',
      color: AppTheme.secondaryColor,
    ),
    _TipData(
      icon: Icons.bedtime_rounded,
      title: 'Protect Your Sleep',
      body: 'Good sleep improves focus by up to 40%.',
      color: AppTheme.accentColor,
    ),
    _TipData(
      icon: Icons.water_drop_rounded,
      title: 'Stay Hydrated',
      body: 'Drink water regularly. Dehydration kills concentration.',
      color: AppTheme.secondaryColor,
    ),
    _TipData(
      icon: Icons.directions_walk_rounded,
      title: 'Take Movement Breaks',
      body: 'A 5-minute walk resets your focus capacity.',
      color: AppTheme.textSecondaryColor,
    ),
  ];

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
    _tipsController.dispose();
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
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _apiService.getTodayStats();
      if (!mounted) return;
      setState(() => _todayStats = stats);
    } catch (_) {
      if (!mounted) return;
      setState(() => _todayStats = null);
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _refreshPermissionSnapshot() async {
    setState(() => _isCheckingPermissions = true);
    try {
      final snapshot = await _permissionService.getSnapshot();
      if (!mounted) return;
      setState(() => _permissionSnapshot = snapshot);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _permissionSnapshot = const PermissionSnapshot(
          accessibilityEnabled: false,
          overlayEnabled: false,
          usageAccessEnabled: false,
          batteryOptimizationIgnored: false,
          notificationEnabled: false,
          autoStartEnabled: false,
        );
      });
    } finally {
      if (mounted) setState(() => _isCheckingPermissions = false);
    }
  }

  Future<void> _openAccessibilitySettings() async {
    final opened = await _permissionService.openAccessibilitySettings();
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Accessibility settings.')),
      );
    }
  }

  Future<void> _loadBlockToggles() async {
    setState(() => _isLoadingBlockToggles = true);
    try {
      final toggles = await _permissionService.getReelsBlockToggles();
      final lockStatus = await _permissionService.getReelsLockStatus();
      if (!mounted) return;
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
      if (!mounted) return;
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
      if (mounted) setState(() => _isLoadingBlockToggles = false);
    }
  }

  Future<void> _persistBlockToggles() async {
    setState(() => _isSavingBlockToggles = true);
    try {
      final ok = await _permissionService.setReelsBlockToggles(
        blockFbReels: _blockFbReels,
        blockInstaReels: _blockInstaReels,
        blockYtShorts: _blockYtShorts,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save blocking toggles.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save blocking toggles.')),
      );
    } finally {
      if (mounted) setState(() => _isSavingBlockToggles = false);
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
        } catch (_) {}
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
    if (selectedPackages.isEmpty) return <String>[];
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
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => FocusDurationPicker(
        selectedDistractingApps: selectedApps,
        onManageApps: _openDistractingAppsManagerAndReload,
        onDurationSelected: _startFocusMode,
      ),
    );
  }

  // ── Native DB score binding ──
  int get _focusScore {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.user?.totalPoints ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          return CustomScrollView(
            slivers: [
              // ── Soft SliverAppBar ──
              SliverAppBar(
                expandedHeight: 72,
                floating: true,
                snap: true,
                backgroundColor: AppTheme.backgroundColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: AppTheme.surfaceColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLg,
                      vertical: AppTheme.spacingMd,
                    ),
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      children: [
                        Text(
                          'Synapse',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const Spacer(),
                        // Hero profile avatar
                        GestureDetector(
                          onTap: () => _showProfileMenu(context, authProvider),
                          child: Hero(
                            tag: 'profile-avatar',
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingLg,
                  0,
                  AppTheme.spacingLg,
                  AppTheme.spacingXl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Missing permissions banner ──
                    if (_isCheckingPermissions)
                      const Padding(
                        padding: EdgeInsets.only(top: AppTheme.spacingMd),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_permissionSnapshot != null &&
                        !_permissionSnapshot!.allRequiredGranted) ...[
                      const SizedBox(height: AppTheme.spacingMd),
                      MissingPermissionsCard(
                        snapshot: _permissionSnapshot!,
                        onOpenAccessibility: _openAccessibilitySettings,
                        onOpenOverlay: () async =>
                            _permissionService.openOverlaySettings(),
                        onOpenUsageAccess: () async =>
                            _permissionService.openUsageAccessSettings(),
                        onOpenBatteryOptimization: () async =>
                            _permissionService
                                .openBatteryOptimizationSettings(),
                        onRequestNotification: () async =>
                            _permissionService.requestNotificationPermission(),
                        onOpenAutoStart: () async =>
                            _permissionService.openAutoStartSettings(),
                        onRefresh: _refreshPermissionSnapshot,
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                    ],

                    // ── Focus mode active banner ──
                    if (_focusModeActive) ...[
                      const SizedBox(height: AppTheme.spacingMd),
                      FocusModeBanner(
                        remainingMinutes: _focusModeRemainingMinutes,
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                    ] else
                      const SizedBox(height: AppTheme.spacingMd),

                    // ── Welcome / Score card ──
                    WelcomeCard(
                      name: user?.name,
                      isLoadingStats: _isLoadingStats,
                      focusScore: _focusScore,
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Reels blocking card ──
                    ReelsCard(
                      blockFbReels: _blockFbReels,
                      blockInstaReels: _blockInstaReels,
                      blockYtShorts: _blockYtShorts,
                      isFbReelsLocked: _isFbReelsLocked,
                      isInstaReelsLocked: _isInstaReelsLocked,
                      isYtShortsLocked: _isYtShortsLocked,
                      fbLockRemainingHours: _fbLockRemainingHours,
                      instaLockRemainingHours: _instaLockRemainingHours,
                      ytLockRemainingHours: _ytLockRemainingHours,
                      isDisabled:
                          _isLoadingBlockToggles || _isSavingBlockToggles,
                      onFbReelsChanged: (v) async {
                        setState(() => _blockFbReels = v);
                        await _persistBlockToggles();
                      },
                      onInstaReelsChanged: (v) async {
                        setState(() => _blockInstaReels = v);
                        await _persistBlockToggles();
                      },
                      onYtShortsChanged: (v) async {
                        setState(() => _blockYtShorts = v);
                        await _persistBlockToggles();
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Today at a glance ──
                    if (!_isLoadingStats && _todayStats != null) ...[
                      GlanceCard(stats: _todayStats!),
                      const SizedBox(height: AppTheme.spacingLg),
                    ],

                    // ── Quick Actions ──
                    Text('Quick Actions', style: AppTheme.headingSmall),
                    const SizedBox(height: AppTheme.spacingXs),
                    QuickActionsGrid(onStartFocus: _showFocusDurationPicker),
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Focus Tips ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Focus Tips', style: AppTheme.headingSmall),
                        Text(
                          '${_currentTipPage + 1} / ${_tips.length}',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    _buildFocusTips(),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Focus Tips PageView ─────────────────────────────────────────────────────
  Widget _buildFocusTips() {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _tipsController,
            onPageChanged: (p) => setState(() => _currentTipPage = p),
            itemCount: _tips.length,
            itemBuilder: (ctx, i) => _TipCard(tip: _tips[i]),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _tips.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentTipPage ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _currentTipPage
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Profile menu ────────────────────────────────────────────────────────────
  void _showProfileMenu(BuildContext ctx, AuthProvider authProvider) {
    showMenu<String>(
      context: ctx,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      items: const <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'profile',
          child: Text('Profile Settings'),
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
      ],
    ).then((value) {
      if (value == 'profile') {
        Navigator.of(ctx).pushNamed('/profile');
      } else if (value == 'logout') {
        authProvider.logout();
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUBWIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Data model for tips.
class _TipData {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _TipData({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}

/// Horizontal swipeable tip card.
class _TipCard extends StatelessWidget {
  final _TipData tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppTheme.spacingMd),
      decoration: AppTheme.softCard(),
      child: Row(
        children: [
          // Color accent strip
          Container(
            width: 5,
            decoration: BoxDecoration(
              color: tip.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMd),
                bottomLeft: Radius.circular(AppTheme.radiusMd),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tip.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(tip.icon, color: tip.color, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          // Text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(tip.title, style: AppTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(
                    tip.body,
                    style: AppTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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


