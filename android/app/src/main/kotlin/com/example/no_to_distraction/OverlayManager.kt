package com.example.no_to_distraction

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import java.util.concurrent.TimeUnit

class OverlayManager(private val service: AccessibilityService) {
    private val windowManager = service.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val handler = Handler(Looper.getMainLooper())

    private var reelsOverlay: View? = null
    private var quickBlockOverlay: View? = null
    private var activeBlockPackageName: String? = null
    private var activeBlockEndTimeMs: Long = 0L
    private var remainingTimeView: TextView? = null

    private var suppressPackage: String? = null
    private var suppressUntilMs: Long = 0L

    private val countdownRunnable = object : Runnable {
        override fun run() {
            val view = remainingTimeView ?: return
            if (quickBlockOverlay == null) return

            val remaining = activeBlockEndTimeMs - System.currentTimeMillis()
            view.text = formatRemainingTime(remaining)
            handler.postDelayed(this, 1000L)
        }
    }

    fun showReelsOverlay(isFocusMode: Boolean) {
        if (!canDrawOverlays()) return
        if (reelsOverlay != null) return

        val root = FrameLayout(service).apply {
            setBackgroundColor(Color.parseColor("#E6000000"))
            isClickable = true
            isFocusable = true
            setOnClickListener {}
        }

        val content = LinearLayout(service).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
        }

        if (isFocusMode) {
            val quote = TextView(service).apply {
                text = getMotivationalQuote()
                setTextColor(Color.parseColor("#FFD4A5"))
                textSize = 16f
                gravity = Gravity.CENTER
                setPadding(0, 0, 0, 24)
            }
            content.addView(quote)
        }

        val title = TextView(service).apply {
            text = if (isFocusMode) "Focus Mode Active" else "Reels Blocked!"
            setTextColor(Color.WHITE)
            textSize = 28f
            gravity = Gravity.CENTER
        }

        val subtitle = TextView(service).apply {
            text = if (isFocusMode) "Reels are restricted during focus." else "Return fresh from launcher to use regular feed."
            setTextColor(Color.parseColor("#CCFFFFFF"))
            textSize = 14f
            gravity = Gravity.CENTER
            setPadding(0, 12, 0, 0)
        }

        val goHome = Button(service).apply {
            text = "Go Home"
            isAllCaps = false
            setOnClickListener {
                service.performGlobalAction(AccessibilityService.GLOBAL_ACTION_HOME)
                hideReelsOverlay()
            }
        }

        content.addView(title)
        content.addView(subtitle)
        content.addView(goHome)
        root.addView(content, FrameLayout.LayoutParams(-1, -1))

        val params = createLayoutParams()
        try {
            windowManager.addView(root, params)
            reelsOverlay = root
            ReelDetectionChannelBridge.publishBlockScreenShown(reason = if (isFocusMode) "focus_reels" else "reels")
        } catch (e: Exception) {
            Log.e(Constants.TAG, "Failed to show reels overlay", e)
        }
    }

    fun hideReelsOverlay() {
        reelsOverlay?.let {
            try { windowManager.removeView(it) } catch (_: Exception) {}
            reelsOverlay = null
        }
    }

    fun showQuickBlockOverlay(packageName: String, endTimeMs: Long) {
        if (!canDrawOverlays()) return
        if (quickBlockOverlay != null) {
            activeBlockPackageName = packageName
            activeBlockEndTimeMs = endTimeMs
            return
        }

        val root = FrameLayout(service).apply {
            setBackgroundColor(Color.parseColor("#CC000000"))
            isClickable = true
        }

        val content = LinearLayout(service).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
        }

        val icon = ImageView(service).apply {
            setImageResource(android.R.drawable.ic_lock_lock)
            setColorFilter(Color.WHITE)
        }

        val title = TextView(service).apply {
            text = "App Blocked"
            setTextColor(Color.WHITE)
            textSize = 24f
        }

        val timer = TextView(service).apply {
            setTextColor(Color.WHITE)
            textSize = 16f
        }
        remainingTimeView = timer

        val home = Button(service).apply {
            text = "Go Home"
            setOnClickListener {
                suppressPackage = packageName
                suppressUntilMs = SystemClock.elapsedRealtime() + Constants.HOME_CLICK_SUPPRESS_MS
                service.performGlobalAction(AccessibilityService.GLOBAL_ACTION_HOME)
                hideQuickBlockOverlay()
            }
        }

        content.addView(icon)
        content.addView(title)
        content.addView(timer)
        content.addView(home)
        root.addView(content, FrameLayout.LayoutParams(-1, -1))

        val params = createLayoutParams(notFocusable = true)
        try {
            windowManager.addView(root, params)
            quickBlockOverlay = root
            activeBlockPackageName = packageName
            activeBlockEndTimeMs = endTimeMs
            handler.post(countdownRunnable)
            ReelDetectionChannelBridge.publishBlockScreenShown(reason = "quick_block", packageName = packageName)
        } catch (e: Exception) {
            Log.e(Constants.TAG, "Failed to show quick block overlay", e)
        }
    }

    fun hideQuickBlockOverlay() {
        handler.removeCallbacks(countdownRunnable)
        quickBlockOverlay?.let {
            try { windowManager.removeView(it) } catch (_: Exception) {}
            quickBlockOverlay = null
            activeBlockPackageName = null
            remainingTimeView = null
        }
    }

    fun isSuppressed(packageName: String): Boolean {
        if (packageName == suppressPackage && SystemClock.elapsedRealtime() < suppressUntilMs) return true
        suppressPackage = null
        return false
    }

    fun isOverlayShowing(): Boolean = reelsOverlay != null || quickBlockOverlay != null
    
    fun getActiveOverlayPackage(): String? = activeBlockPackageName

    private fun canDrawOverlays() = Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(service)

    private fun createLayoutParams(notFocusable: Boolean = false): WindowManager.LayoutParams {
        val flags = WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or WindowManager.LayoutParams.FLAG_FULLSCREEN or
                   (if (notFocusable) WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE else 0)
        
        return WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            flags,
            PixelFormat.TRANSLUCENT
        )
    }

    private fun formatRemainingTime(ms: Long): String {
        val sec = Math.max(0, TimeUnit.MILLISECONDS.toSeconds(ms))
        return "Remaining: ${sec / 3600}h ${(sec % 3600) / 60}m ${sec % 60}s"
    }

    private fun getMotivationalQuote() = listOf(
        "Focus is the gateway to success.",
        "Your future self will thank you for focusing.",
        "Distractions are temporary, goals are permanent.",
        "You are stronger than your distractions.",
        "Stay unstoppable."
    ).random()
}
