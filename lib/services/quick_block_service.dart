library;

import 'package:flutter/services.dart';

class QuickBlockStatus {
  final bool isActive;
  final int blockedCount;
  final int endTimeMs;
  final List<QuickBlockRuleStatus> rules;

  const QuickBlockStatus({
    required this.isActive,
    required this.blockedCount,
    required this.endTimeMs,
    required this.rules,
  });
}

class QuickBlockRuleStatus {
  final String packageName;
  final int endTimeMs;
  final int remainingMs;

  const QuickBlockRuleStatus({
    required this.packageName,
    required this.endTimeMs,
    required this.remainingMs,
  });
}

/// Handles Quick Block communication with native Android code.
///
/// The native side stores data in SharedPreferences so it can continue
/// blocking apps even if Flutter engine is dead.
class QuickBlockService {
  static const MethodChannel _channel = MethodChannel(
    'no_to_distraction/accessibility_control',
  );

  /// Sends selected packages and end time (epoch ms) to native side.
  Future<bool> startQuickBlock({
    required List<String> packageNames,
    required Duration duration,
  }) async {
    // Native side expects an absolute end timestamp so service can compare
    // against System.currentTimeMillis() directly in background mode.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final endTimeMs = nowMs + duration.inMilliseconds;

    final result = await _channel.invokeMethod<bool>('startQuickBlock', {
      'packages': packageNames,
      'endTimeMs': endTimeMs,
    });

    return result ?? false;
  }

  /// Upserts app-specific block end-times.
  Future<bool> upsertQuickBlockRules({
    required Map<String, int> packageEndTimes,
  }) async {
    final result = await _channel.invokeMethod<bool>('startQuickBlock', {
      'packageEndTimes': packageEndTimes,
    });

    return result ?? false;
  }

  /// Reads current native quick-block state persisted in SharedPreferences.
  Future<QuickBlockStatus> getQuickBlockStatus() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getQuickBlockStatus',
    );

    final data = raw ?? <dynamic, dynamic>{};
    final rawRules = (data['rules'] as List<dynamic>? ?? <dynamic>[]);

    final rules = rawRules
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (rule) => QuickBlockRuleStatus(
            packageName: rule['packageName']?.toString() ?? '',
            endTimeMs: (rule['endTimeMs'] as num?)?.toInt() ?? 0,
            remainingMs: (rule['remainingMs'] as num?)?.toInt() ?? 0,
          ),
        )
        .where((rule) => rule.packageName.isNotEmpty)
        .toList();

    return QuickBlockStatus(
      isActive: data['isActive'] as bool? ?? false,
      blockedCount: data['blockedCount'] as int? ?? 0,
      endTimeMs: (data['endTimeMs'] as num?)?.toInt() ?? 0,
      rules: rules,
    );
  }
}
