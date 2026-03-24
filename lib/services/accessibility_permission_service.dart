library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionSnapshot {
  final bool accessibilityEnabled;
  final bool overlayEnabled;
  final bool usageAccessEnabled;
  final bool batteryOptimizationIgnored;
  final bool notificationEnabled;

  const PermissionSnapshot({
    required this.accessibilityEnabled,
    required this.overlayEnabled,
    required this.usageAccessEnabled,
    required this.batteryOptimizationIgnored,
    required this.notificationEnabled,
  });

  bool get allRequiredGranted =>
      accessibilityEnabled &&
      overlayEnabled &&
      usageAccessEnabled &&
      batteryOptimizationIgnored &&
      notificationEnabled;
}

class AccessibilityPermissionService {
  static const MethodChannel _channel = MethodChannel(
    'no_to_distraction/accessibility_control',
  );

  Future<bool> isAccessibilityServiceEnabled() async {
    final result = await _channel.invokeMethod<bool>(
      'isAccessibilityServiceEnabled',
    );
    return result ?? false;
  }

  Future<bool> openAccessibilitySettings() async {
    final result = await _channel.invokeMethod<bool>(
      'openAccessibilitySettings',
    );
    return result ?? false;
  }

  Future<bool> isOverlayPermissionGranted() async {
    final result = await _channel.invokeMethod<bool>(
      'isOverlayPermissionGranted',
    );
    return result ?? false;
  }

  Future<bool> openOverlaySettings() async {
    final result = await _channel.invokeMethod<bool>('openOverlaySettings');
    return result ?? false;
  }

  Future<bool> isUsageAccessGranted() async {
    final result = await _channel.invokeMethod<bool>('isUsageAccessGranted');
    return result ?? false;
  }

  Future<bool> openUsageAccessSettings() async {
    final result = await _channel.invokeMethod<bool>('openUsageAccessSettings');
    return result ?? false;
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    final result = await _channel.invokeMethod<bool>(
      'isIgnoringBatteryOptimizations',
    );
    return result ?? false;
  }

  Future<bool> openBatteryOptimizationSettings() async {
    final result = await _channel.invokeMethod<bool>(
      'openBatteryOptimizationSettings',
    );
    return result ?? false;
  }

  Future<bool> isNotificationPermissionGranted() async {
    if (!Platform.isAndroid) {
      return true;
    }

    // Android 12 and below do not require runtime notification permission.
    if (Platform.isAndroid &&
        (await _channel.invokeMethod<int>('getSdkInt') ?? 0) < 33) {
      return true;
    }

    return Permission.notification.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> openAutoStartSettings() async {
    final result = await _channel.invokeMethod<bool>('openAutoStartSettings');
    return result ?? false;
  }

  Future<Map<String, bool>> getReelsBlockToggles() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getReelsBlockToggles',
    );

    final map = result ?? <Object?, Object?>{};
    return <String, bool>{
      'block_fb_reels': (map['block_fb_reels'] as bool?) ?? false,
      'block_insta_reels': (map['block_insta_reels'] as bool?) ?? false,
      'block_yt_shorts': (map['block_yt_shorts'] as bool?) ?? false,
    };
  }

  Future<Map<String, dynamic>> getReelsLockStatus() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getReelsLockStatus',
    );

    if (result == null) {
      return {
        'fbLocked': false,
        'instaLocked': false,
        'ytLocked': false,
        'fbRemainingHours': 0,
        'instaRemainingHours': 0,
        'ytRemainingHours': 0,
      };
    }

    return {
      'fbLocked': (result['fbLocked'] as bool?) ?? false,
      'instaLocked': (result['instaLocked'] as bool?) ?? false,
      'ytLocked': (result['ytLocked'] as bool?) ?? false,
      'fbRemainingHours': (result['fbRemainingHours'] as num?)?.toInt() ?? 0,
      'instaRemainingHours':
          (result['instaRemainingHours'] as num?)?.toInt() ?? 0,
      'ytRemainingHours': (result['ytRemainingHours'] as num?)?.toInt() ?? 0,
    };
  }

  Future<bool> setReelsBlockToggles({
    required bool blockFbReels,
    required bool blockInstaReels,
    required bool blockYtShorts,
  }) async {
    final result = await _channel.invokeMethod<bool>('setReelsBlockToggles', {
      'block_fb_reels': blockFbReels,
      'block_insta_reels': blockInstaReels,
      'block_yt_shorts': blockYtShorts,
    });
    return result ?? false;
  }

  Future<PermissionSnapshot> getSnapshot() async {
    final accessibility = await isAccessibilityServiceEnabled();
    final overlay = await isOverlayPermissionGranted();
    final usage = await isUsageAccessGranted();
    final battery = await isIgnoringBatteryOptimizations();
    final notification = await isNotificationPermissionGranted();

    return PermissionSnapshot(
      accessibilityEnabled: accessibility,
      overlayEnabled: overlay,
      usageAccessEnabled: usage,
      batteryOptimizationIgnored: battery,
      notificationEnabled: notification,
    );
  }

  Future<List<Object?>> getInstalledApps() async {
    final result = await _channel.invokeMethod<List<Object?>>(
      'getInstalledApps',
    );
    return result ?? [];
  }

  Future<List<String>> getDistractingApps() async {
    final result = await _channel.invokeMethod<List<Object?>>(
      'getDistractingApps',
    );
    return (result ?? []).cast<String>();
  }

  Future<bool> setDistractingApps(List<String> packageNames) async {
    final result = await _channel.invokeMethod<bool>('setDistractingApps', {
      'packages': packageNames,
    });
    return result ?? false;
  }

  Future<bool> startFocusMode({required int durationMinutes}) async {
    final result = await _channel.invokeMethod<bool>('startFocusMode', {
      'durationMinutes': durationMinutes,
    });
    return result ?? false;
  }

  Future<Map<String, dynamic>> getFocusModeStatus() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getFocusModeStatus',
    );

    if (result == null) {
      return {'isActive': false, 'endTimeMs': 0, 'remainingMinutes': 0};
    }

    return {
      'isActive': (result['isActive'] as bool?) ?? false,
      'endTimeMs': (result['endTimeMs'] as num?)?.toInt() ?? 0,
      'remainingMinutes': (result['remainingMinutes'] as num?)?.toInt() ?? 0,
    };
  }

  Future<bool> stopFocusMode() async {
    final result = await _channel.invokeMethod<bool>('stopFocusMode');
    return result ?? false;
  }
}
