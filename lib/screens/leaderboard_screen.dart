library;

import 'package:flutter/material.dart';
import 'package:no_to_distraction/models/stats.dart';
import 'package:no_to_distraction/services/api_service.dart';
import 'package:no_to_distraction/theme/app_theme.dart';
import 'package:no_to_distraction/widgets/leaderboard/current_user_rank_card.dart';
import 'package:no_to_distraction/widgets/leaderboard/leaderboard_entry_tile.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();

  LeaderboardResponse? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiService.getLeaderboard(limit: 50);
      if (!mounted) {
        return;
      }
      setState(() {
        _data = data;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text(_error!, style: AppTheme.bodySmall)
            else if (_data != null) ...[
              CurrentUserRankCard(
                rank: _data!.currentUserRank,
                points: _data!.currentUserPoints,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              ..._data!.leaderboard.map(
                (entry) => LeaderboardEntryTile(entry: entry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
