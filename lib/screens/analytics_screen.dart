library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:no_to_distraction/models/stats.dart';
import 'package:no_to_distraction/providers/stats_provider.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().fetchAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics (7 Days)'), elevation: 0),
      body: Consumer<StatsProvider>(
        builder: (context, statsProvider, _) {
          final data = statsProvider.analytics;

          return RefreshIndicator(
            onRefresh: () => statsProvider.fetchAnalytics(),
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              children: [
                if (statsProvider.isLoading && data == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (statsProvider.errorMessage != null)
                  Text(statsProvider.errorMessage!, style: AppTheme.bodySmall)
                else if (data != null) ...[
                  Container(
                    height: 260,
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: _NetPointsLineChart(series: data.series),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trend: ${data.trend.toUpperCase()}',
                          style: AppTheme.headingSmall,
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(data.message, style: AppTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  ...data.series.map(
                    (day) => Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(day.date, style: AppTheme.headingSmall),
                          const SizedBox(height: 6),
                          Text(
                            'Focus: ${day.focusSessionsCount} sessions, ${day.focusMinutes} min, +${day.focusPointsGained} pts',
                            style: AppTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Blocks: ${day.blockScreensCount}, -${day.pointsLost} pts, Net: ${day.netPoints}',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
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

class _NetPointsLineChart extends StatelessWidget {
  final List<AnalyticsDayStats> series;

  const _NetPointsLineChart({required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const Center(child: Text('No data yet'));
    }

    final spots = <FlSpot>[];
    var maxY = -9999.0;
    var minY = 9999.0;

    for (var i = 0; i < series.length; i++) {
      final y = series[i].netPoints.toDouble();
      spots.add(FlSpot(i.toDouble(), y));
      if (y > maxY) {
        maxY = y;
      }
      if (y < minY) {
        minY = y;
      }
    }

    final top = (maxY + 5).clamp(-1000.0, 1000.0);
    final bottom = (minY - 5).clamp(-1000.0, 1000.0);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (series.length - 1).toDouble(),
        minY: bottom,
        maxY: top,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 36),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= series.length) {
                  return const SizedBox.shrink();
                }
                final date = series[i].date;
                final short = date.length >= 10 ? date.substring(5) : date;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(short, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: AppTheme.primaryColor,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
