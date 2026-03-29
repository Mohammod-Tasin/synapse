import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onStartFocus;

  const QuickActionsGrid({
    required this.onStartFocus,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        icon: Icons.timer_rounded,
        title: 'Start Focus',
        subtitle: 'Begin a session',
        color: AppTheme.primaryColor,
        onTap: onStartFocus,
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
