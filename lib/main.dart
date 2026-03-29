/// Main application entry point with routing and state management.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:no_to_distraction/providers/auth_provider.dart';
import 'package:no_to_distraction/providers/stats_provider.dart';
import 'package:no_to_distraction/screens/blocking_overlay_screen.dart';
import 'package:no_to_distraction/screens/splash_screen.dart';
import 'package:no_to_distraction/screens/login_screen.dart';
import 'package:no_to_distraction/screens/forgot_password_screen.dart';
import 'package:no_to_distraction/screens/signup_screen.dart';
import 'package:no_to_distraction/screens/verify_email_screen.dart';
import 'package:no_to_distraction/screens/onboarding_screen.dart';
import 'package:no_to_distraction/screens/home_screen.dart';
import 'package:no_to_distraction/screens/today_stats_screen.dart';
import 'package:no_to_distraction/screens/analytics_screen.dart';
import 'package:no_to_distraction/screens/leaderboard_screen.dart';
import 'package:no_to_distraction/screens/permissions_screen.dart';
import 'package:no_to_distraction/screens/quick_block_screen.dart';
import 'package:no_to_distraction/screens/distracting_apps_screen.dart';
import 'package:no_to_distraction/screens/profile_screen.dart';
import 'package:no_to_distraction/services/stats_api.dart';
import 'package:no_to_distraction/services/reel_detection_listener_service.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
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
    final navigator = _navigatorKey.currentState;
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
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'No to Distraction',
      theme: AppTheme.lightTheme(),
      home: const _AuthNavigator(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/signup': (context) => const SignupScreen(),
        '/verify-email': (context) => const VerifyEmailScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/permissions': (context) => const PermissionsScreen(),
        '/home': (context) => const HomeScreen(),
        '/today-stats': (context) => const TodayStatsScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
        '/quick-block': (context) => const QuickBlockScreen(),
        '/distracting-apps': (context) => const DistractingAppsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

/// AuthNavigator handles routing based on authentication status.
class _AuthNavigator extends StatelessWidget {
  const _AuthNavigator();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Initial loading state - show splash screen
        if (authProvider.status == AuthStatus.initial ||
            authProvider.status == AuthStatus.authenticating) {
          return const SplashScreen();
        }

        // Not authenticated - show login screen
        if (authProvider.status == AuthStatus.notAuthenticated) {
          return const LoginScreen();
        }

        // Authenticated but needs onboarding
        if (authProvider.status == AuthStatus.onboarding) {
          return const OnboardingScreen();
        }

        // Fully authenticated - open home directly to avoid re-gating every launch.
        if (authProvider.status == AuthStatus.authenticated) {
          // Trigger a silent refresh of stats on every successful (re)authentication
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final statsProvider = Provider.of<StatsProvider>(context, listen: false);
            if (statsProvider.todayStats == null) {
              statsProvider.refreshAll();
            }
          });
          return const HomeScreen();
        }

        // Error state - show error message with retry option
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Text('An error occurred', style: AppTheme.headingMedium),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  authProvider.errorMessage ?? 'Unknown error',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                ElevatedButton(
                  onPressed: () {
                    authProvider.initialize();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
