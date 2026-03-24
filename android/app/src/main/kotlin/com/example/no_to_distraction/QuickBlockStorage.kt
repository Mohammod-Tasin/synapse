package com.example.no_to_distraction

import android.content.Context

data class QuickBlockRule(
    val packageName: String,
    val endTimeMs: Long
)

data class QuickBlockState(
    val packageEndTimes: Map<String, Long>
) {
    fun isActive(nowMs: Long = System.currentTimeMillis()): Boolean {
        return packageEndTimes.any { (_, endTimeMs) -> endTimeMs > nowMs }
    }

    fun isPackageBlocked(packageName: String, nowMs: Long = System.currentTimeMillis()): Boolean {
        val endTimeMs = packageEndTimes[packageName] ?: return false
        return endTimeMs > nowMs
    }

    fun packageEndTime(packageName: String): Long? {
        return packageEndTimes[packageName]
    }

    fun latestEndTimeMs(nowMs: Long = System.currentTimeMillis()): Long {
        return packageEndTimes.values.filter { it > nowMs }.maxOrNull() ?: 0L
    }

    fun activeRules(nowMs: Long = System.currentTimeMillis()): List<QuickBlockRule> {
        return packageEndTimes
            .filterValues { it > nowMs }
            .map { (packageName, endTimeMs) -> QuickBlockRule(packageName, endTimeMs) }
            .sortedByDescending { it.endTimeMs }
    }
}

object QuickBlockStorage {
    // SharedPreferences keys for native-only Quick Block persistence.
    private const val PREFS_NAME = "quick_block_prefs"
    private const val KEY_PACKAGE_END_ENTRIES = "package_end_entries"

    // Legacy keys kept for migration support from previous global-duration model.
    private const val KEY_PACKAGES = "blocked_packages"
    private const val KEY_END_TIME_MS = "block_end_time_ms"

    private const val ENTRY_SEPARATOR = "|||"

    fun save(context: Context, packages: List<String>, endTimeMs: Long) {
        // Backward-compatible path: assign same end-time to all packages.
        val packageEndTimes = packages.associateWith { endTimeMs }
        upsert(context, packageEndTimes)
    }

    fun upsert(context: Context, packageEndTimes: Map<String, Long>) {
        val nowMs = System.currentTimeMillis()
        val existing = readActive(context, nowMs).packageEndTimes.toMutableMap()

        packageEndTimes.forEach { (rawPackageName, rawEndTimeMs) ->
            val packageName = rawPackageName.trim()
            if (packageName.isEmpty()) {
                return@forEach
            }

            if (rawEndTimeMs <= nowMs) {
                existing.remove(packageName)
                return@forEach
            }

            existing[packageName] = rawEndTimeMs
        }

        persistPackageEndTimes(context, existing)
    }

    fun read(context: Context): QuickBlockState {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val entries = prefs.getStringSet(KEY_PACKAGE_END_ENTRIES, emptySet())?.toSet().orEmpty()

        val packageEndTimes = mutableMapOf<String, Long>()
        for (entry in entries) {
            val parts = entry.split(ENTRY_SEPARATOR)
            if (parts.size != 2) {
                continue
            }

            val packageName = parts[0].trim()
            val endTimeMs = parts[1].toLongOrNull() ?: continue
            if (packageName.isEmpty()) {
                continue
            }
            packageEndTimes[packageName] = endTimeMs
        }

        // Legacy migration: old model had one end-time for all packages.
        if (packageEndTimes.isEmpty()) {
            val legacyPackages = prefs.getStringSet(KEY_PACKAGES, emptySet())?.toSet().orEmpty()
            val legacyEndTimeMs = prefs.getLong(KEY_END_TIME_MS, 0L)
            if (legacyPackages.isNotEmpty() && legacyEndTimeMs > 0L) {
                legacyPackages.forEach { pkg ->
                    if (pkg.isNotBlank()) {
                        packageEndTimes[pkg] = legacyEndTimeMs
                    }
                }
                persistPackageEndTimes(context, packageEndTimes)
            }
        }

        return QuickBlockState(packageEndTimes = packageEndTimes)
    }

    fun readActive(context: Context, nowMs: Long = System.currentTimeMillis()): QuickBlockState {
        val state = read(context)
        val activeOnly = state.packageEndTimes.filterValues { it > nowMs }
        if (activeOnly.size != state.packageEndTimes.size) {
            persistPackageEndTimes(context, activeOnly)
        }
        return QuickBlockState(packageEndTimes = activeOnly)
    }

    fun activeRules(context: Context, nowMs: Long = System.currentTimeMillis()): List<QuickBlockRule> {
        return readActive(context, nowMs).activeRules(nowMs)
    }

    fun clear(context: Context) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove(KEY_PACKAGE_END_ENTRIES)
            .remove(KEY_PACKAGES)
            .remove(KEY_END_TIME_MS)
            .apply()
    }

    private fun persistPackageEndTimes(context: Context, packageEndTimes: Map<String, Long>) {
        val encodedEntries = packageEndTimes
            .map { (packageName, endTimeMs) -> "$packageName$ENTRY_SEPARATOR$endTimeMs" }
            .toSet()

        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putStringSet(KEY_PACKAGE_END_ENTRIES, encodedEntries)
            // Cleanup legacy keys once new format is written.
            .remove(KEY_PACKAGES)
            .remove(KEY_END_TIME_MS)
            .apply()
    }
}