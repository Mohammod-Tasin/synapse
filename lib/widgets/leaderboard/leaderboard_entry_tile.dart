import 'package:flutter/material.dart';
import 'package:no_to_distraction/models/stats.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

class LeaderboardEntryTile extends StatelessWidget {
  final LeaderboardEntry entry;

  const LeaderboardEntryTile({required this.entry, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: AppTheme.softCard(),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#${entry.rank}',
              style: AppTheme.bodyLarge,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: AppTheme.headingSmall),
                const SizedBox(height: 2),
                Text(entry.email, style: AppTheme.bodySmall),
              ],
            ),
          ),
          Text(
            '${entry.totalPoints} pts',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
