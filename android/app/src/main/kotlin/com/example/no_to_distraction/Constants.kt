package com.example.no_to_distraction

import android.view.accessibility.AccessibilityEvent

object Constants {
    const val TAG = "ShortVideoA11yService"
    const val PREFS_NAME = "reels_block_prefs"
    
    // SharedPreferences Keys
    const val PREF_BLOCK_FB_REELS = "block_fb_reels"
    const val PREF_BLOCK_INSTA_REELS = "block_insta_reels"
    const val PREF_BLOCK_YT_SHORTS = "block_yt_shorts"
    const val PREF_DISTRACTING_APPS = "distracting_apps"
    const val PREF_FOCUS_MODE_END_TIME_MS = "focus_mode_end_ms"
    const val PREF_FB_REELS_LOCK_UNTIL_MS = "fb_reels_lock_until_ms"
    const val PREF_INSTA_REELS_LOCK_UNTIL_MS = "insta_reels_lock_until_ms"
    const val PREF_YT_SHORTS_LOCK_UNTIL_MS = "yt_shorts_lock_until_ms"
    const val PREF_PENDING_BLOCKS = "pending_blocks"

    // Package Names
    const val FACEBOOK_PACKAGE = "com.facebook.katana"
    const val INSTAGRAM_PACKAGE = "com.instagram.android"
    const val YOUTUBE_PACKAGE = "com.google.android.youtube"

    // Thresholds & Durations
    const val EVENT_DEBOUNCE_MS = 400L
    const val HOME_CLICK_SUPPRESS_MS = 2_500L
    const val MIN_REELS_OVERLAY_VISIBLE_MS = 1_500L
    const val REELS_LOCK_DURATION_MS = 2L * 24L * 60L * 60L * 1000L

    // Spatial Heuristic Constants
    const val RIGHT_SIDE_MIN_RATIO = 0.60f
    const val FULL_SCREEN_MIN_RATIO = 0.80f
    const val STACK_X_ALIGNMENT_TOLERANCE_PX = 50
    const val MIN_VERTICAL_STACK_GAP_PX = 50
    const val HORIZONTAL_REJECTION_Y_DIFF_PX = 40
    const val POINT_DEDUP_TOLERANCE_PX = 24
    const val MAX_PARENT_DEPTH = 12

    val TARGET_REELS_PACKAGES = setOf(
        FACEBOOK_PACKAGE,
        INSTAGRAM_PACKAGE,
        YOUTUBE_PACKAGE
    )

    val TARGET_EVENT_TYPES = setOf(
        AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
        AccessibilityEvent.TYPE_VIEW_SCROLLED
    )
}
