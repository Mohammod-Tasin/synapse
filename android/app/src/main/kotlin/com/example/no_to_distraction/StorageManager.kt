package com.example.no_to_distraction

import android.content.Context
import android.util.Log

object StorageManager {
    private const val PREFS_NAME = Constants.PREFS_NAME

    fun isBlockingEnabledForPackage(context: Context, packageName: String): Boolean {
        if (isReelsLockActiveForPackage(context, packageName)) return true

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return when (packageName) {
            Constants.FACEBOOK_PACKAGE -> prefs.getBoolean(Constants.PREF_BLOCK_FB_REELS, false)
            Constants.INSTAGRAM_PACKAGE -> prefs.getBoolean(Constants.PREF_BLOCK_INSTA_REELS, false)
            Constants.YOUTUBE_PACKAGE -> prefs.getBoolean(Constants.PREF_BLOCK_YT_SHORTS, false)
            else -> true
        }
    }

    fun isReelsLockActiveForPackage(context: Context, packageName: String, nowMs: Long = System.currentTimeMillis()): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val key = when (packageName) {
            Constants.FACEBOOK_PACKAGE -> Constants.PREF_FB_REELS_LOCK_UNTIL_MS
            Constants.INSTAGRAM_PACKAGE -> Constants.PREF_INSTA_REELS_LOCK_UNTIL_MS
            Constants.YOUTUBE_PACKAGE -> Constants.PREF_YT_SHORTS_LOCK_UNTIL_MS
            else -> return false
        }
        return prefs.getLong(key, 0L) > nowMs
    }

    fun applyReelsLockForTwoDays(context: Context, packageName: String) {
        val lockKey = when (packageName) {
            Constants.FACEBOOK_PACKAGE -> Constants.PREF_FB_REELS_LOCK_UNTIL_MS
            Constants.INSTAGRAM_PACKAGE -> Constants.PREF_INSTA_REELS_LOCK_UNTIL_MS
            Constants.YOUTUBE_PACKAGE -> Constants.PREF_YT_SHORTS_LOCK_UNTIL_MS
            else -> return
        }

        val nowMs = System.currentTimeMillis()
        val newLockUntilMs = nowMs + Constants.REELS_LOCK_DURATION_MS
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val existingLockUntilMs = prefs.getLong(lockKey, 0L)
        
        val editor = prefs.edit().putLong(lockKey, Math.max(existingLockUntilMs, newLockUntilMs))
        when (packageName) {
            Constants.FACEBOOK_PACKAGE -> editor.putBoolean(Constants.PREF_BLOCK_FB_REELS, true)
            Constants.INSTAGRAM_PACKAGE -> editor.putBoolean(Constants.PREF_BLOCK_INSTA_REELS, true)
            Constants.YOUTUBE_PACKAGE -> editor.putBoolean(Constants.PREF_BLOCK_YT_SHORTS, true)
        }
        editor.apply()
    }

    fun incrementPendingBlocks(context: Context) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val current = prefs.getInt(Constants.PREF_PENDING_BLOCKS, 0)
            prefs.edit().putInt(Constants.PREF_PENDING_BLOCKS, current + 1).apply()
        } catch (t: Throwable) {
            Log.w(Constants.TAG, "Failed to increment pending blocks", t)
        }
    }

    fun isFocusModeActive(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getLong(Constants.PREF_FOCUS_MODE_END_TIME_MS, 0L) > System.currentTimeMillis()
    }

    fun getFocusModeRemainingMinutes(context: Context): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val endTimeMs = prefs.getLong(Constants.PREF_FOCUS_MODE_END_TIME_MS, 0L)
        val nowMs = System.currentTimeMillis()
        if (endTimeMs <= nowMs) return 0
        return ((endTimeMs - nowMs) / 60 / 1000).toInt()
    }

    fun isDistractingApp(context: Context, packageName: String): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val apps = prefs.getString(Constants.PREF_DISTRACTING_APPS, "[]")
            ?.split(",")?.filter { it.isNotEmpty() } ?: emptyList()
        return apps.contains(packageName)
    }
}
