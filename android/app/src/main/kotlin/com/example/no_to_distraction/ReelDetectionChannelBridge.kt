package com.example.no_to_distraction

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object ReelDetectionChannelBridge {
    const val CHANNEL_NAME = "no_to_distraction/reel_detector"
    const val METHOD_REEL_STATE_CHANGED = "onReelDetectionStateChanged"
    const val METHOD_BLOCK_SCREEN_SHOWN = "onBlockScreenShown"

    private const val TAG = "ReelChannelBridge"

    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var channel: MethodChannel? = null

    @Volatile
    private var isEngineAttached: Boolean = false

    fun attachFlutterEngine(flutterEngine: FlutterEngine) {
        mainHandler.post {
            channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            isEngineAttached = true
            Log.i(TAG, "MethodChannel attached: $CHANNEL_NAME")
        }
    }

    fun detachChannel() {
        mainHandler.post {
            channel = null
            isEngineAttached = false
            Log.i(TAG, "MethodChannel detached")
        }
    }

    fun publishReelDetected(isDetected: Boolean) {
        val payload = hashMapOf(
             "isReelDetected" to isDetected,
            "timestampMs" to System.currentTimeMillis()
        )

        mainHandler.post {
            try {
                if (!isEngineAttached) {
                    return@post
                }

                val localChannel = channel ?: return@post
                localChannel.invokeMethod(METHOD_REEL_STATE_CHANGED, payload)
            } catch (t: Throwable) {
                Log.w(TAG, "Unable to publish reel detection state", t)
            }
        }
    }

    fun publishBlockScreenShown(reason: String, packageName: String? = null) {
        val payload = hashMapOf<String, Any>(
            "reason" to reason,
            "timestampMs" to System.currentTimeMillis(),
        )
        if (!packageName.isNullOrBlank()) {
            payload["packageName"] = packageName
        }

        mainHandler.post {
            try {
                if (!isEngineAttached) {
                    return@post
                }

                val localChannel = channel ?: return@post
                localChannel.invokeMethod(METHOD_BLOCK_SCREEN_SHOWN, payload)
            } catch (t: Throwable) {
                Log.w(TAG, "Unable to publish block-screen event", t)
            }
        }
    }
}