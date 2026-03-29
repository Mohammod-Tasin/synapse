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
import 'package:no_to_distraction/widgets/synapse_illustrations.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
          appNameByPackage[packageName] =
              appName.isEmpty ? packageName : appName;
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
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.3),
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
                      _MissingPermissionsCard(
                        snapshot: _permissionSnapshot!,
                        onOpenAccessibility: _openAccessibilitySettings,
                        onOpenOverlay: () async =>
                            _permissionService.openOverlaySettings(),
                        onOpenUsageAccess: () async =>
                            _permissionService.openUsageAccessSettings(),
                        onOpenBatteryOptimization: () async =>
                            _permissionService.openBatteryOptimizationSettings(),
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
                      _FocusModeBanner(
                        remainingMinutes: _focusModeRemainingMinutes,
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                    ] else
                      const SizedBox(height: AppTheme.spacingMd),

                    // ── Welcome / Score card ──
                    _buildWelcomeCard(user?.name),
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Reels blocking card ──
                    _buildReelsCard(),
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Today at a glance ──
                    if (!_isLoadingStats && _todayStats != null) ...[
                      _buildGlanceCard(),
                      const SizedBox(height: AppTheme.spacingLg),
                    ],

                    // ── Quick Actions ──
                    Text('Quick Actions', style: AppTheme.headingSmall),
                    const SizedBox(height: AppTheme.spacingXs),
                    _buildQuickActions(),
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

  // ─── Welcome / Score Card ───────────────────────────────────────────────────
  Widget _buildWelcomeCard(String? name) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: AppTheme.softCard(radius: AppTheme.radiusLg),
      child: Row(
        children: [
          // Left: greeting text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${name ?? 'there'} 👋',
                  style: AppTheme.headingSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready to focus today?',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Base Focus Score',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right: score badge
          if (_isLoadingStats)
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          else
            FocusScoreBadge(score: _focusScore, size: 110),
        ],
      ),
    );
  }

  // ─── Reels Blocking Card ────────────────────────────────────────────────────
  Widget _buildReelsCard() {
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
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusSm),
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
              if (_isLoadingBlockToggles || _isSavingBlockToggles)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isFbReelsLocked || _isInstaReelsLocked || _isYtShortsLocked
                ? '48-hour lock is active for enabled platform(s).'
                : 'Toggle platforms to enable protection.',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _ReelsToggleRow(
            platformName: 'Facebook Reels',
            value: _blockFbReels,
            isLocked: _isFbReelsLocked,
            remainingHours: _fbLockRemainingHours,
            isDisabled: _isLoadingBlockToggles || _isSavingBlockToggles,
            onChanged: (v) async {
              setState(() => _blockFbReels = v);
              await _persistBlockToggles();
            },
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _ReelsToggleRow(
            platformName: 'Instagram Reels',
            value: _blockInstaReels,
            isLocked: _isInstaReelsLocked,
            remainingHours: _instaLockRemainingHours,
            isDisabled: _isLoadingBlockToggles || _isSavingBlockToggles,
            onChanged: (v) async {
              setState(() => _blockInstaReels = v);
              await _persistBlockToggles();
            },
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _ReelsToggleRow(
            platformName: 'YouTube Shorts',
            value: _blockYtShorts,
            isLocked: _isYtShortsLocked,
            remainingHours: _ytLockRemainingHours,
            isDisabled: _isLoadingBlockToggles || _isSavingBlockToggles,
            onChanged: (v) async {
              setState(() => _blockYtShorts = v);
              await _persistBlockToggles();
            },
          ),
        ],
      ),
    );
  }

  // ─── Today at a Glance Card ─────────────────────────────────────────────────
  Widget _buildGlanceCard() {
    final stats = _todayStats!;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: AppTheme.softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today at a Glance', style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: _GlanceStat(
                  icon: Icons.timer_outlined,
                  value: '${stats.focusSessionsCount}',
                  label: 'Sessions',
                  color: AppTheme.primaryColor,
                ),
              ),
              Expanded(
                child: _GlanceStat(
                  icon: Icons.schedule_rounded,
                  value: '${stats.focusMinutes}',
                  label: 'Minutes',
                  color: AppTheme.secondaryColor,
                ),
              ),
              Expanded(
                child: _GlanceStat(
                  icon: Icons.block_rounded,
                  value: '${stats.blockScreensCount}',
                  label: 'Blocks',
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          if (stats.focusPointsGained > 0 || stats.pointsLost > 0) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    size: 14,
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+${stats.focusPointsGained} earned  ·  ${stats.pointsLost} reduced',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Quick Actions Grid ──────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _ActionData(
        icon: Icons.timer_rounded,
        title: 'Start Focus',
        subtitle: 'Begin a session',
        color: AppTheme.primaryColor,
        onTap: _showFocusDurationPicker,
      ),
      _ActionData(
        icon: Icons.timeline_rounded,
        title: "Today's Stats",
        subtitle: 'View progress',
        color: AppTheme.secondaryColor,
        onTap: () => Navigator.of(context).pushNamed('/today-stats'),
      ),
      _ActionData(
        icon: Icons.apps_rounded,
        title: 'Distracting Apps',
        subtitle: 'Manage list',
        color: AppTheme.textSecondaryColor,
        onTap: () => Navigator.of(context).pushNamed('/distracting-apps'),
      ),
      _ActionData(
        icon: Icons.flash_on_rounded,
        title: 'Quick Block',
        subtitle: 'Pick + duration',
        color: AppTheme.secondaryColor,
        onTap: () => Navigator.of(context).pushNamed('/quick-block'),
      ),
      _ActionData(
        icon: Icons.insights_rounded,
        title: 'Analytics',
        subtitle: 'Weekly report',
        color: AppTheme.primaryColor,
        onTap: () => Navigator.of(context).pushNamed('/analytics'),
      ),
      _ActionData(
        icon: Icons.emoji_events_rounded,
        title: 'Leaderboard',
        subtitle: 'Top users',
        color: AppTheme.warningColor,
        onTap: () => Navigator.of(context).pushNamed('/leaderboard'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppTheme.spacingSm,
        mainAxisSpacing: AppTheme.spacingSm,
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (ctx, i) => _ActionTile(data: actions[i]),
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
            onPageChanged: (p) =>
                setState(() => _currentTipPage = p),
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
        PopupMenuItem<String>(value: 'profile', child: Text('Profile Settings')),
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

/// Glance stat column widget.
class _GlanceStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _GlanceStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTheme.caption),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

/// Data model for action tiles.
class _ActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

/// Neumorphic-light action tile.
class _ActionTile extends StatelessWidget {
  final _ActionData data;
  const _ActionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          decoration: AppTheme.softCard(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                data.title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                data.subtitle,
                style: AppTheme.caption,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spacingMd,
              ),
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

/// Focus mode active banner (calm organic feel).
class _FocusModeBanner extends StatelessWidget {
  final int remainingMinutes;
  const _FocusModeBanner({required this.remainingMinutes});

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

/// Missing permissions card.
class _MissingPermissionsCard extends StatelessWidget {
  final PermissionSnapshot snapshot;
  final Future<void> Function() onOpenAccessibility;
  final Future<void> Function() onOpenOverlay;
  final Future<void> Function() onOpenUsageAccess;
  final Future<void> Function() onOpenBatteryOptimization;
  final Future<void> Function() onRequestNotification;
  final Future<void> Function() onOpenAutoStart;
  final Future<void> Function() onRefresh;

  const _MissingPermissionsCard({
    required this.snapshot,
    required this.onOpenAccessibility,
    required this.onOpenOverlay,
    required this.onOpenUsageAccess,
    required this.onOpenBatteryOptimization,
    required this.onRequestNotification,
    required this.onOpenAutoStart,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final missing = <_PermissionAction>[];
    if (!snapshot.accessibilityEnabled) {
      missing.add(_PermissionAction(
        title: 'Accessibility Permission',
        buttonLabel: 'Enable',
        onTap: onOpenAccessibility,
      ));
    }
    if (!snapshot.overlayEnabled) {
      missing.add(_PermissionAction(
        title: 'Overlay Permission',
        buttonLabel: 'Enable',
        onTap: onOpenOverlay,
      ));
    }
    if (!snapshot.usageAccessEnabled) {
      missing.add(_PermissionAction(
        title: 'Usage Access',
        buttonLabel: 'Enable',
        onTap: onOpenUsageAccess,
      ));
    }
    if (!snapshot.batteryOptimizationIgnored) {
      missing.add(_PermissionAction(
        title: 'Battery Optimization Exemption',
        hint: 'Set to: No Restriction',
        buttonLabel: 'Allow',
        onTap: onOpenBatteryOptimization,
      ));
    }
    if (!snapshot.notificationEnabled) {
      missing.add(_PermissionAction(
        title: 'Notification Permission',
        buttonLabel: 'Allow',
        onTap: onRequestNotification,
      ));
    }
    if (!snapshot.autoStartEnabled) {
      missing.add(_PermissionAction(
        title: 'Auto-Start Permission',
        buttonLabel: 'Enable',
        onTap: onOpenAutoStart,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.warningColor.withValues(alpha: 0.3),
        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// FOCUS DURATION PICKER DIALOG (preserved logic, soft styling)
// ─────────────────────────────────────────────────────────────────────────────
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
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours h';
    return '$hours h $mins m';
  }

  Future<void> _manageApps() async {
    setState(() => _isRefreshingApps = true);
    try {
      final updatedApps = await widget.onManageApps();
      if (!mounted) return;
      setState(() => _selectedApps = updatedApps);
    } finally {
      if (mounted) setState(() => _isRefreshingApps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Start Focus Mode',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimaryColor,
        ),
      ),
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
              Text('Select duration:', style: AppTheme.bodyMedium),
              const SizedBox(height: AppTheme.spacingSm),
              Center(
                child: Text(
                  _formatDuration(_selectedDuration),
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: AppTheme.borderColor,
                  thumbColor: AppTheme.primaryColor,
                  overlayColor:
                      AppTheme.primaryColor.withValues(alpha: 0.1),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _selectedDuration.toDouble(),
                  min: 5,
                  max: 720,
                  divisions: 143,
                  label: _formatDuration(_selectedDuration),
                  onChanged: (v) =>
                      setState(() => _selectedDuration = v.toInt()),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final d in [15, 25, 45, 60, 90, 120, 180, 360, 720])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_formatDuration(d)),
                          selected: _selectedDuration == d,
                          onSelected: (_) =>
                              setState(() => _selectedDuration = d),
                          selectedColor:
                              AppTheme.primaryColor.withValues(alpha: 0.2),
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
                  color: AppTheme.warningColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.warningColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distracting apps',
                      style: AppTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    if (_selectedApps.isEmpty)
                      Text(
                        'No apps selected. You can continue anyway.',
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
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Manage App List'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        textStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
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
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('During focus mode:', style: AppTheme.bodyLarge),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      '✓ Reels and Shorts will be blocked',
                      style: AppTheme.bodySmall,
                    ),
                    Text(
                      '✓ Selected apps will be blocked',
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
        TextButton(
          onPressed: () {
            widget.onDurationSelected(_selectedDuration);
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusPill),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: 10,
            ),
          ),
          child: Text(
            'Start Focus',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
