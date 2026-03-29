package com.example.no_to_distraction

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.os.SystemClock
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class ShortVideoAccessibilityService : AccessibilityService() {

    private var lastProcessedAtMs: Long = 0L
    private var lastPublishedState: Boolean? = null
    
    private lateinit var overlayManager: OverlayManager

    override fun onServiceConnected() {
        super.onServiceConnected()
        serviceInfo = serviceInfo.apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                    AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                    AccessibilityEvent.TYPE_VIEW_SCROLLED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 120
            flags = flags or AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            packageNames = null
        }
        overlayManager = OverlayManager(this)
        Log.i(Constants.TAG, "ShortVideoAccessibilityService modularized and connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        // 🛡️ Step 1: Handle Quick Block & Overlays
        if (handleOverlaysAndQuickBlock(event)) return

        if (event.eventType !in Constants.TARGET_EVENT_TYPES) return

        val packageName = resolvePackageName(event) ?: return

        // 🛡️ Step 2: Focus Mode App Blocking
        if (StorageManager.isFocusModeActive(this)) {
            if (StorageManager.isDistractingApp(this, packageName)) {
                overlayManager.showReelsOverlay(isFocusMode = true)
                performGlobalAction(GLOBAL_ACTION_BACK)
                return
            }
        }

        // 🛡️ Step 3: Reels Gatekeeper
        if (packageName !in Constants.TARGET_REELS_PACKAGES) {
            updateDetectionState(false, "package_out: $packageName")
            return
        }

        if (!StorageManager.isFocusModeActive(this) && 
            !StorageManager.isBlockingEnabledForPackage(this, packageName)) {
            updateDetectionState(false, "reels_disabled: $packageName")
            return
        }

        // ⏱️ Step 4: Debounce
        val now = SystemClock.elapsedRealtime()
        if (now - lastProcessedAtMs < Constants.EVENT_DEBOUNCE_MS) return
        lastProcessedAtMs = now

        // 🔍 Step 5: Detection Engine
        val root = rootInActiveWindow ?: return
        try {
            val screenW = getScreenWidth()
            val screenH = getScreenHeight()
            
            val detected = if (packageName == Constants.FACEBOOK_PACKAGE) {
                ScannerEngine.isFacebookReel(root, screenW, screenH)
            } else {
                ScannerEngine.detectBySpatialHeuristics(root, screenW, screenH)
            }

            updateDetectionState(detected, "engine: $packageName", packageName)
        } catch (t: Throwable) {
            Log.w(Constants.TAG, "Detection failed", t)
        } finally {
            root.recycle()
        }
    }

    private fun handleOverlaysAndQuickBlock(event: AccessibilityEvent): Boolean {
        val packageName = resolvePackageName(event) ?: ""
        
        // Check for home-click suppression (prevents immediate re-blocking)
        if (overlayManager.isSuppressed(packageName)) return false

        // 🚧 Quick Block Enforcement
        val now = System.currentTimeMillis()
        val quickBlockState = QuickBlockStorage.readActive(this, now)
        
        if (quickBlockState.isPackageBlocked(packageName, now)) {
            val endTime = quickBlockState.packageEndTime(packageName) ?: 0L
            overlayManager.hideReelsOverlay()
            overlayManager.showQuickBlockOverlay(packageName, endTime)
            return true
        }

        // If overlay is already showing for the current package, consume the event
        if (overlayManager.isOverlayShowing()) {
            val activePkg = overlayManager.getActiveOverlayPackage()
            if (activePkg == null || activePkg == packageName || packageName.isEmpty()) return true
        }

        return false
    }

    private fun updateDetectionState(newState: Boolean, reason: String, detectedPackageName: String? = null) {
        if (lastPublishedState == newState) return
        
        ReelDetectionChannelBridge.publishReelDetected(newState)
        lastPublishedState = newState

        if (newState) {
            detectedPackageName?.let { pkg ->
                StorageManager.applyReelsLockForTwoDays(this, pkg)
                StorageManager.incrementPendingBlocks(this)
            }
            overlayManager.showReelsOverlay(StorageManager.isFocusModeActive(this))
            performGlobalAction(GLOBAL_ACTION_BACK)
        }
        Log.d(Constants.TAG, "State changed to $newState: $reason")
    }

    private fun resolvePackageName(event: AccessibilityEvent): String? {
        return event.packageName?.toString() ?: rootInActiveWindow?.packageName?.toString()
    }

    private fun getScreenWidth(): Int = resources.displayMetrics.widthPixels
    private fun getScreenHeight(): Int = resources.displayMetrics.heightPixels

    override fun onInterrupt() {
        overlayManager.hideReelsOverlay()
        overlayManager.hideQuickBlockOverlay()
    }

    override fun onDestroy() {
        onInterrupt()
        super.onDestroy()
    }
}
