import 'dart:convert';
import 'package:no_to_distraction/config/app_config.dart';
import 'package:no_to_distraction/models/stats.dart';
import 'package:no_to_distraction/services/base_api.dart';
import 'package:no_to_distraction/utils/api_utils.dart';

/// Service for productivity/stats-related API calls.
class StatsApi extends BaseApi {
  Future<PointsEventResponse> logFocusSession({
    required int durationMinutes,
  }) async {
    final response = await request(
      method: 'POST',
      endpoint: AppConfig.focusSessionEventEndpoint,
      body: {'duration_minutes': durationMinutes},
    );

    if (response.statusCode == 200) {
      return PointsEventResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(ApiUtils.resolveErrorMessage(response, ErrorMessages.serverError));
  }

  Future<PointsEventResponse> logBlockScreen({
    required String reason,
    int pointsPenalty = 1,
    String? packageName,
  }) async {
    final response = await request(
      method: 'POST',
      endpoint: AppConfig.blockScreenEventEndpoint,
      body: {
        'reason': reason,
        'points_penalty': pointsPenalty,
        if (packageName != null) 'package_name': packageName,
      },
    );

    if (response.statusCode == 200) {
      return PointsEventResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(ApiUtils.resolveErrorMessage(response, ErrorMessages.serverError));
  }

  Future<TodayStats> getTodayStats() async {
    final response = await request(
      method: 'GET',
      endpoint: AppConfig.todayStatsEndpoint,
    );

    if (response.statusCode == 200) {
      return TodayStats.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(ApiUtils.resolveErrorMessage(response, ErrorMessages.serverError));
  }

  Future<AnalyticsResponse> getAnalytics({int days = 7}) async {
    final response = await request(
      method: 'GET',
      endpoint: '${AppConfig.analyticsEndpoint}?days=$days',
    );

    if (response.statusCode == 200) {
      return AnalyticsResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(ApiUtils.resolveErrorMessage(response, ErrorMessages.serverError));
  }

  Future<LeaderboardResponse> getLeaderboard({int limit = 20}) async {
    final response = await request(
      method: 'GET',
      endpoint: '${AppConfig.leaderboardEndpoint}?limit=$limit',
    );

    if (response.statusCode == 200) {
      return LeaderboardResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(ApiUtils.resolveErrorMessage(response, ErrorMessages.serverError));
  }
}
