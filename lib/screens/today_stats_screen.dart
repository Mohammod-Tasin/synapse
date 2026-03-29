library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:no_to_distraction/providers/stats_provider.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

class TodayStatsScreen extends StatefulWidget {
  const TodayStatsScreen({super.key});

  @override
  State<TodayStatsScreen> createState() => _TodayStatsScreenState();
}

class _TodayStatsScreenState extends State<TodayStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().fetchTodayStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Stats"), elevation: 0),
      body: Consumer<StatsProvider>(
        builder: (context, statsProvider, _) {
          final stats = statsProvider.todayStats;
          
          return RefreshIndicator(
            onRefresh: () => statsProvider.fetchTodayStats(),
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              children: [
                if (statsProvider.isLoading && stats == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (statsProvider.errorMessage != null)
                  _ErrorCard(
                    message: statsProvider.errorMessage!,
                    onRetry: () => statsProvider.fetchTodayStats(),
                  )
                else if (stats != null) ...[
                  _MetricCard(
                    title: 'Total Points',
                    value: stats.totalPoints.toString(),
                    subtitle: 'Your cumulative score across all days',
                    icon: Icons.emoji_events,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  _MetricCard(
                    title: 'Focus Work',
                    value:
                        '${stats.focusSessionsCount} sessions • ${stats.focusMinutes} min',
                    subtitle: '+${stats.focusPointsGained} points gained today',
                    icon: Icons.timer,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  _MetricCard(
                    title: 'Block Screens',
                    value: stats.blockScreensCount.toString(),
                    subtitle: '-${stats.pointsLost} points penalty today',
                    icon: Icons.block,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  _MetricCard(
                    title: 'Net Today',
                    value: stats.netPointsToday.toString(),
                    subtitle: 'Today performance impact (gain - penalty)',
                    icon: Icons.trending_up,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.headingSmall),
                const SizedBox(height: AppTheme.spacingSm),
                Text(value, style: AppTheme.bodyLarge),
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

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Failed to load stats', style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spacingSm),
          Text(message, style: AppTheme.bodySmall),
          const SizedBox(height: AppTheme.spacingMd),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
