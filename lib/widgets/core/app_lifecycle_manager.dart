import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:no_to_distraction/providers/auth_provider.dart';
import 'package:no_to_distraction/providers/stats_provider.dart';
import 'package:no_to_distraction/services/stats_api.dart';
import 'package:no_to_distraction/services/reel_detection_listener_service.dart';
import 'package:no_to_distraction/screens/blocking_overlay_screen.dart';
import 'package:no_to_distraction/navigation/app_routes.dart';

/// AppLifecycleManager handles app-level observers, background sync, and reel detection.
class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> with WidgetsBindingObserver {
  final StatsApi _statsApi = StatsApi();
  StreamSubscription<bool>? _detectionSubscription;
  StreamSubscription<BlockScreenEvent>? _blockScreenSubscription;

  bool _overlayVisible = false;
  Route<void>? _overlayRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Sync points immediately on cold boot if background blocks happened
    _syncPendingBackgroundBlocks();

    ReelDetectionListenerService.instance.start();
    _detectionSubscription = ReelDetectionListenerService
        .instance
        .detectionStream
        .listen(_handleDetectionEvent);
    _blockScreenSubscription = ReelDetectionListenerService
        .instance
        .blockScreenStream
        .listen(_handleBlockScreenEvent);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detectionSubscription?.cancel();
    _blockScreenSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPendingBackgroundBlocks();
    }
  }

  Future<void> _syncPendingBackgroundBlocks() async {
    try {
      const channel = MethodChannel('no_to_distraction/accessibility_control');
      final int pendingCount = await channel.invokeMethod('getAndResetPendingBlocks') ?? 0;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final statsProvider = Provider.of<StatsProvider>(context, listen: false);

      if (pendingCount > 0) {
        if (authProvider.isAuthenticated) {
          statsProvider.applyLocalPenalty(pendingCount);
          await _statsApi.logBlockScreen(
            reason: 'Background Reel Block Sync',
            pointsPenalty: pendingCount,
          );
        }
      }

      if (authProvider.isAuthenticated) {
        await authProvider.fetchLatestProfileSilently();
      }
    } catch (_) {
      // Ignore background sync errors silently to preserve UX
    }
  }

  Future<void> _handleBlockScreenEvent(BlockScreenEvent event) async {
    try {
      // Immediately deduct score locally to eliminate UI delay
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final statsProvider = Provider.of<StatsProvider>(context, listen: false);
      
      if (authProvider.isAuthenticated) {
        statsProvider.applyLocalPenalty(1); 
      }

      await _statsApi.logBlockScreen(
        reason: event.reason,
        packageName: event.packageName,
      );
    } catch (_) {
      // Ignore transient logging failures to avoid interrupting app UX.
    }
  }

  void _handleDetectionEvent(bool isReelDetected) {
    final navigator = AppRoutes.navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    if (isReelDetected && !_overlayVisible) {
      _overlayVisible = true;
      _overlayRoute = PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, _, _) => const BlockingOverlayScreen(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );

      navigator.push(_overlayRoute!).whenComplete(() {
        _overlayVisible = false;
        _overlayRoute = null;
      });
      return;
    }

    if (!isReelDetected && _overlayVisible) {
      final route = _overlayRoute;
      if (route != null) {
        navigator.removeRoute(route);
        _overlayVisible = false;
        _overlayRoute = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
