import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:no_to_distraction/models/stats.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

class GlanceCard extends StatelessWidget {
  final TodayStats stats;

  const GlanceCard({
    required this.stats,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
