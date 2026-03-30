/// Main application entry point with modular navigation and lifecycle management.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:no_to_distraction/providers/auth_provider.dart';
import 'package:no_to_distraction/providers/stats_provider.dart';
import 'package:no_to_distraction/theme/app_theme.dart';
import 'package:no_to_distraction/navigation/app_routes.dart';
import 'package:no_to_distraction/navigation/auth_navigator.dart';
import 'package:no_to_distraction/widgets/core/app_lifecycle_manager.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppRoutes.navigatorKey,
      title: 'No to Distraction',
      theme: AppTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      routes: AppRoutes.getRoutes(),
      home: const AppLifecycleManager(
        child: AuthNavigator(),
      ),
    );
  }
}
