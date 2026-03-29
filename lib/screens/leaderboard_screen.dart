library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:no_to_distraction/providers/stats_provider.dart';
import 'package:no_to_distraction/theme/app_theme.dart';
import 'package:no_to_distraction/widgets/leaderboard/current_user_rank_card.dart';
import 'package:no_to_distraction/widgets/leaderboard/leaderboard_entry_tile.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().fetchLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard'), elevation: 0),
      body: Consumer<StatsProvider>(
        builder: (context, statsProvider, _) {
          return RefreshIndicator(
            onRefresh: () => statsProvider.fetchLeaderboard(),
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              children: [
                if (statsProvider.isLoading && statsProvider.leaderboard == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (statsProvider.errorMessage != null)
                  Text(statsProvider.errorMessage!, style: AppTheme.bodySmall)
                else if (statsProvider.leaderboard != null) ...[
                  CurrentUserRankCard(
                    rank: statsProvider.leaderboard!.currentUserRank,
                    points: statsProvider.leaderboard!.currentUserPoints,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  ...statsProvider.leaderboard!.leaderboard.map(
                    (entry) => LeaderboardEntryTile(entry: entry),
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
