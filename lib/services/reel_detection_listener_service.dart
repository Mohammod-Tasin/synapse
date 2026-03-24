library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BlockScreenEvent {
  final String reason;
  final String? packageName;
  final int timestampMs;

  const BlockScreenEvent({
    required this.reason,
    required this.timestampMs,
    this.packageName,
  });
}

class ReelDetectionListenerService {
  ReelDetectionListenerService._();

  static final ReelDetectionListenerService instance =
      ReelDetectionListenerService._();

  static const MethodChannel _channel = MethodChannel(
    'no_to_distraction/reel_detector',
  );

  bool _isListening = false;
  final StreamController<bool> _detectionController =
      StreamController<bool>.broadcast();
  final StreamController<BlockScreenEvent> _blockScreenController =
      StreamController<BlockScreenEvent>.broadcast();

  Stream<bool> get detectionStream => _detectionController.stream;
  Stream<BlockScreenEvent> get blockScreenStream =>
      _blockScreenController.stream;

  void start() {
    if (_isListening) {
      return;
    }
    _isListening = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onReelDetectionStateChanged') {
        final args =
            (call.arguments as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        final detected =
            args['isReelDetected'] as bool? ??
            args['detected'] as bool? ??
            false;
        final timestampMs = args['timestampMs'];

        debugPrint(
          '[ReelDetection] detected=$detected timestampMs=$timestampMs',
        );
        _detectionController.add(detected);
        return;
      }

      if (call.method == 'onBlockScreenShown') {
        final args =
            (call.arguments as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        _blockScreenController.add(
          BlockScreenEvent(
            reason: (args['reason'] as String? ?? 'unknown').trim(),
            packageName: args['packageName'] as String?,
            timestampMs:
                (args['timestampMs'] as num?)?.toInt() ??
                DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }
    });
  }

  void dispose() {
    _detectionController.close();
    _blockScreenController.close();
  }
}
