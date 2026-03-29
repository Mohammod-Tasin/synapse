import 'package:flutter/material.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

class CurrentUserRankCard extends StatelessWidget {
  final int rank;
  final int points;

  const CurrentUserRankCard({
    required this.rank,
    required this.points,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: AppTheme.softCard(color: AppTheme.inputFillColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Rank: $rank',
            style: AppTheme.headingSmall,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Your Points: $points',
            style: AppTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
