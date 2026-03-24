library;

class PointsEventResponse {
  final String message;
  final int pointsDelta;
  final int totalPoints;

  PointsEventResponse({
    required this.message,
    required this.pointsDelta,
    required this.totalPoints,
  });

  factory PointsEventResponse.fromJson(Map<String, dynamic> json) {
    return PointsEventResponse(
      message: json['message'] as String? ?? '',
      pointsDelta: (json['points_delta'] as num?)?.toInt() ?? 0,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
    );
  }
}

class TodayStats {
  final String date;
  final int totalPoints;
  final int focusSessionsCount;
  final int focusMinutes;
  final int focusPointsGained;
  final int blockScreensCount;
  final int pointsLost;
  final int netPointsToday;

  TodayStats({
    required this.date,
    required this.totalPoints,
    required this.focusSessionsCount,
    required this.focusMinutes,
    required this.focusPointsGained,
    required this.blockScreensCount,
    required this.pointsLost,
    required this.netPointsToday,
  });

  factory TodayStats.fromJson(Map<String, dynamic> json) {
    return TodayStats(
      date: json['date'] as String? ?? '',
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      focusSessionsCount: (json['focus_sessions_count'] as num?)?.toInt() ?? 0,
      focusMinutes: (json['focus_minutes'] as num?)?.toInt() ?? 0,
      focusPointsGained: (json['focus_points_gained'] as num?)?.toInt() ?? 0,
      blockScreensCount: (json['block_screens_count'] as num?)?.toInt() ?? 0,
      pointsLost: (json['points_lost'] as num?)?.toInt() ?? 0,
      netPointsToday: (json['net_points_today'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnalyticsDayStats {
  final String date;
  final int focusSessionsCount;
  final int focusMinutes;
  final int focusPointsGained;
  final int blockScreensCount;
  final int pointsLost;
  final int netPoints;

  AnalyticsDayStats({
    required this.date,
    required this.focusSessionsCount,
    required this.focusMinutes,
    required this.focusPointsGained,
    required this.blockScreensCount,
    required this.pointsLost,
    required this.netPoints,
  });

  factory AnalyticsDayStats.fromJson(Map<String, dynamic> json) {
    return AnalyticsDayStats(
      date: json['date'] as String? ?? '',
      focusSessionsCount: (json['focus_sessions_count'] as num?)?.toInt() ?? 0,
      focusMinutes: (json['focus_minutes'] as num?)?.toInt() ?? 0,
      focusPointsGained: (json['focus_points_gained'] as num?)?.toInt() ?? 0,
      blockScreensCount: (json['block_screens_count'] as num?)?.toInt() ?? 0,
      pointsLost: (json['points_lost'] as num?)?.toInt() ?? 0,
      netPoints: (json['net_points'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnalyticsResponse {
  final int days;
  final List<AnalyticsDayStats> series;
  final String trend;
  final String message;

  AnalyticsResponse({
    required this.days,
    required this.series,
    required this.trend,
    required this.message,
  });

  factory AnalyticsResponse.fromJson(Map<String, dynamic> json) {
    final rawSeries = (json['series'] as List<dynamic>? ?? <dynamic>[]);
    return AnalyticsResponse(
      days: (json['days'] as num?)?.toInt() ?? 7,
      series: rawSeries
          .map(
            (item) => AnalyticsDayStats.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      trend: json['trend'] as String? ?? 'stable',
      message: json['message'] as String? ?? '',
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String name;
  final String email;
  final int totalPoints;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.email,
    required this.totalPoints,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaderboardResponse {
  final List<LeaderboardEntry> leaderboard;
  final int currentUserRank;
  final int currentUserPoints;

  LeaderboardResponse({
    required this.leaderboard,
    required this.currentUserRank,
    required this.currentUserPoints,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final rows = (json['leaderboard'] as List<dynamic>? ?? <dynamic>[]);
    return LeaderboardResponse(
      leaderboard: rows
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentUserRank: (json['current_user_rank'] as num?)?.toInt() ?? 0,
      currentUserPoints: (json['current_user_points'] as num?)?.toInt() ?? 0,
    );
  }
}
