import 'package:flutter/foundation.dart';
import 'package:no_to_distraction/models/stats.dart';
import 'package:no_to_distraction/services/base_api.dart';
import 'package:no_to_distraction/services/stats_api.dart';
import 'package:no_to_distraction/utils/error_utils.dart';

class StatsProvider extends ChangeNotifier {
  final StatsApi _statsApi = StatsApi();

  // State
  TodayStats? _todayStats;
  LeaderboardResponse? _leaderboard;
  AnalyticsResponse? _analytics;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  TodayStats? get todayStats => _todayStats;
  LeaderboardResponse? get leaderboard => _leaderboard;
  AnalyticsResponse? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch all relevant stats (usually on app start or login).
  Future<void> refreshAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchTodayStats(),
        fetchLeaderboard(),
      ]);
    } catch (e) {
      if (e is TokenExpiredException) rethrow;
      _errorMessage = getFriendlyErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch today's summary stats.
  Future<void> fetchTodayStats() async {
    try {
      _todayStats = await _statsApi.getTodayStats();
      notifyListeners();
    } catch (e) {
      if (e is TokenExpiredException) rethrow;
      _errorMessage = getFriendlyErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Fetch leaderboard data.
  Future<void> fetchLeaderboard({int limit = 50}) async {
    try {
      _leaderboard = await _statsApi.getLeaderboard(limit: limit);
      notifyListeners();
    } catch (e) {
      if (e is TokenExpiredException) rethrow;
      _errorMessage = getFriendlyErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Fetch analytics series.
  Future<void> fetchAnalytics({int days = 7}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _analytics = await _statsApi.getAnalytics(days: days);
    } catch (e) {
      if (e is TokenExpiredException) rethrow;
      _errorMessage = getFriendlyErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Log a focus session and update state.
  Future<PointsEventResponse> logFocusSession(int minutes) async {
    try {
      final response = await _statsApi.logFocusSession(durationMinutes: minutes);
      // Refresh stats to reflect new points/minutes
      await fetchTodayStats();
      return response;
    } catch (e) {
      if (e is TokenExpiredException) rethrow;
      _errorMessage = getFriendlyErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Log a block event.
  Future<PointsEventResponse> logBlockEvent({
    required String reason,
    String? packageName,
    int penalty = 1,
  }) async {
    try {
      final response = await _statsApi.logBlockScreen(
        reason: reason,
        packageName: packageName,
        pointsPenalty: penalty,
      );
      // Refresh stats
      await fetchTodayStats();
      return response;
    } catch (e) {
      if (e is TokenExpiredException) rethrow;
      _errorMessage = getFriendlyErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Apply local points deduction immediately for snappy UI.
  /// This doesn't call the API, just updates local state until the next sync/refresh.
  void applyLocalPenalty(int penalty) {
    if (_todayStats != null) {
      final newTotal = (_todayStats!.totalPoints - penalty).clamp(0, 999999);
      final newLost = _todayStats!.pointsLost + penalty;
      
      _todayStats = TodayStats(
        date: _todayStats!.date,
        totalPoints: newTotal,
        focusSessionsCount: _todayStats!.focusSessionsCount,
        focusMinutes: _todayStats!.focusMinutes,
        focusPointsGained: _todayStats!.focusPointsGained,
        blockScreensCount: _todayStats!.blockScreensCount + 1,
        pointsLost: newLost,
        netPointsToday: _todayStats!.netPointsToday - penalty,
      );
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
