package com.example.no_to_distraction

import android.app.AppOpsManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private var accessibilityControlChannel: MethodChannel? = null

	private fun updateReelsBlockToggles(
		blockFbReels: Boolean,
		blockInstaReels: Boolean,
		blockYtShorts: Boolean
	) {
		getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
			.edit()
			.putBoolean(PREF_BLOCK_FB_REELS, blockFbReels)
			.putBoolean(PREF_BLOCK_INSTA_REELS, blockInstaReels)
			.putBoolean(PREF_BLOCK_YT_SHORTS, blockYtShorts)
			.apply()
	}

	private fun isReelsLockActiveForKey(lockKey: String, nowMs: Long = System.currentTimeMillis()): Boolean {
		val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
		val lockUntilMs = prefs.getLong(lockKey, 0L)
		return lockUntilMs > nowMs
	}

	private fun getRemainingLockHours(lockKey: String, nowMs: Long = System.currentTimeMillis()): Int {
		val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
		val lockUntilMs = prefs.getLong(lockKey, 0L)
		val remainingMs = maxOf(0L, lockUntilMs - nowMs)
		return ((remainingMs + 3_599_999L) / 3_600_000L).toInt()
	}

	private fun getReelsLockStatus(nowMs: Long = System.currentTimeMillis()): Map<String, Any> {
		val fbLocked = isReelsLockActiveForKey(PREF_FB_REELS_LOCK_UNTIL_MS, nowMs)
		val instaLocked = isReelsLockActiveForKey(PREF_INSTA_REELS_LOCK_UNTIL_MS, nowMs)
		val ytLocked = isReelsLockActiveForKey(PREF_YT_SHORTS_LOCK_UNTIL_MS, nowMs)

		return mapOf(
			"fbLocked" to fbLocked,
			"instaLocked" to instaLocked,
			"ytLocked" to ytLocked,
			"fbRemainingHours" to getRemainingLockHours(PREF_FB_REELS_LOCK_UNTIL_MS, nowMs),
			"instaRemainingHours" to getRemainingLockHours(PREF_INSTA_REELS_LOCK_UNTIL_MS, nowMs),
			"ytRemainingHours" to getRemainingLockHours(PREF_YT_SHORTS_LOCK_UNTIL_MS, nowMs)
		)
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		ReelDetectionChannelBridge.attachFlutterEngine(flutterEngine)

		accessibilityControlChannel = MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			ACCESSIBILITY_CONTROL_CHANNEL
		).apply {
			setMethodCallHandler { call, result ->
				when (call.method) {
					"getSdkInt" -> result.success(Build.VERSION.SDK_INT)
					"setReelsBlockToggles" -> {
						val blockFbReels = call.argument<Boolean>("block_fb_reels") ?: false
						val blockInstaReels = call.argument<Boolean>("block_insta_reels") ?: false
						val blockYtShorts = call.argument<Boolean>("block_yt_shorts") ?: false
						val fbLocked = isReelsLockActiveForKey(PREF_FB_REELS_LOCK_UNTIL_MS)
						val instaLocked = isReelsLockActiveForKey(PREF_INSTA_REELS_LOCK_UNTIL_MS)
						val ytLocked = isReelsLockActiveForKey(PREF_YT_SHORTS_LOCK_UNTIL_MS)

						updateReelsBlockToggles(
							blockFbReels = if (fbLocked) true else blockFbReels,
							blockInstaReels = if (instaLocked) true else blockInstaReels,
							blockYtShorts = if (ytLocked) true else blockYtShorts
						)
						result.success(true)
					}
					"getReelsBlockToggles" -> {
						val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
						val fbLocked = isReelsLockActiveForKey(PREF_FB_REELS_LOCK_UNTIL_MS)
						val instaLocked = isReelsLockActiveForKey(PREF_INSTA_REELS_LOCK_UNTIL_MS)
						val ytLocked = isReelsLockActiveForKey(PREF_YT_SHORTS_LOCK_UNTIL_MS)
						result.success(
							hashMapOf(
								"block_fb_reels" to if (fbLocked) true else prefs.getBoolean(PREF_BLOCK_FB_REELS, false),
								"block_insta_reels" to if (instaLocked) true else prefs.getBoolean(PREF_BLOCK_INSTA_REELS, false),
								"block_yt_shorts" to if (ytLocked) true else prefs.getBoolean(PREF_BLOCK_YT_SHORTS, false)
							)
						)
					}
					"getReelsLockStatus" -> result.success(getReelsLockStatus())
					"getAndResetPendingBlocks" -> {
						val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
						val count = prefs.getInt("pending_blocks", 0)
						if (count > 0) {
							prefs.edit().putInt("pending_blocks", 0).apply()
						}
						result.success(count)
					}
					"getQuickBlockStatus" -> {
						val nowMs = System.currentTimeMillis()
						val state = QuickBlockStorage.readActive(this@MainActivity, nowMs)
						val rules = state.activeRules(nowMs).map { rule ->
							hashMapOf(
								"packageName" to rule.packageName,
								"endTimeMs" to rule.endTimeMs,
								"remainingMs" to (rule.endTimeMs - nowMs)
							)
						}

						result.success(
							hashMapOf(
								"isActive" to state.isActive(nowMs),
								"endTimeMs" to state.latestEndTimeMs(nowMs),
								"blockedCount" to rules.size,
								"rules" to rules
							)
						)
					}
					"startQuickBlock" -> {
						// Supports both old payload (packages + endTimeMs) and new payload
						// (packageEndTimes map) for per-app durations.
						val nowMs = System.currentTimeMillis()
						val packageEndTimesAny = call.argument<Map<*, *>>("packageEndTimes")

						val parsedPackageEndTimes = mutableMapOf<String, Long>()
						if (packageEndTimesAny != null) {
							for ((rawKey, rawValue) in packageEndTimesAny) {
								val packageName = rawKey?.toString()?.trim().orEmpty()
								val endTimeMs = (rawValue as? Number)?.toLong() ?: continue
								if (packageName.isNotEmpty() && endTimeMs > nowMs) {
									parsedPackageEndTimes[packageName] = endTimeMs
								}
							}
						}

						if (parsedPackageEndTimes.isEmpty()) {
							val packages = call.argument<List<String>>("packages").orEmpty()
							val endTimeMs = call.argument<Number>("endTimeMs")?.toLong() ?: 0L
							if (endTimeMs > nowMs) {
								packages
									.map { it.trim() }
									.filter { it.isNotEmpty() }
									.forEach { pkg -> parsedPackageEndTimes[pkg] = endTimeMs }
							}
						}

						if (parsedPackageEndTimes.isEmpty()) {
							result.success(false)
						} else {
							QuickBlockStorage.upsert(this@MainActivity, parsedPackageEndTimes)
							result.success(true)
						}
					}
					"isAccessibilityServiceEnabled" -> result.success(isAccessibilityServiceEnabled())
					"openAccessibilitySettings" -> result.success(openAccessibilitySettings())
					"isOverlayPermissionGranted" -> result.success(isOverlayPermissionGranted())
					"openOverlaySettings" -> result.success(openOverlaySettings())
					"isUsageAccessGranted" -> result.success(isUsageAccessGranted())
					"openUsageAccessSettings" -> result.success(openUsageAccessSettings())
					"isIgnoringBatteryOptimizations" -> result.success(isIgnoringBatteryOptimizations())
					"openBatteryOptimizationSettings" -> result.success(openBatteryOptimizationSettings())
					"openAutoStartSettings" -> result.success(openAutoStartSettings())
					"getInstalledApps" -> {
						val apps = getInstalledApps()
						result.success(apps)
					}
					"getDistractingApps" -> {
						val apps = getDistractingApps()
						result.success(apps)
					}
					"setDistractingApps" -> {
						val packages = call.argument<List<String>>("packages").orEmpty()
						setDistractingApps(packages)
						result.success(true)
					}
					"startFocusMode" -> {
						val durationMinutes = call.argument<Int>("durationMinutes") ?: 25
						startFocusMode(durationMinutes)
						result.success(true)
					}
					"getFocusModeStatus" -> {
						val status = getFocusModeStatus()
						result.success(status)
					}
					"stopFocusMode" -> {
						result.success(false)
					}
					else -> result.notImplemented()
				}
			}
		}
	}

	override fun onDestroy() {
		accessibilityControlChannel?.setMethodCallHandler(null)
		accessibilityControlChannel = null
		ReelDetectionChannelBridge.detachChannel()
		super.onDestroy()
	}

	private fun isAccessibilityServiceEnabled(): Boolean {
		return AccessibilityUtils.isShortVideoServiceEnabled(this)
	}

	private fun openAccessibilitySettings(): Boolean {
		return try {
			startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
				addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			})
			true
		} catch (_: Throwable) {
			false
		}
	}

	private fun isOverlayPermissionGranted(): Boolean {
		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
			Settings.canDrawOverlays(this)
		} else {
			true
		}
	}

	private fun openOverlaySettings(): Boolean {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
			return true
		}

		return try {
			startActivity(Intent(
				Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
				Uri.parse("package:$packageName")
			).apply {
				addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			})
			true
		} catch (_: Throwable) {
			false
		}
	}

	private fun isUsageAccessGranted(): Boolean {
		val appOps = ContextCompat.getSystemService(this, AppOpsManager::class.java)
			?: return false

		val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
		} else {
			appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
		}

		return mode == AppOpsManager.MODE_ALLOWED
	}

	private fun openUsageAccessSettings(): Boolean {
		return try {
			startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
				addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			})
			true
		} catch (_: Throwable) {
			false
		}
	}

	private fun isIgnoringBatteryOptimizations(): Boolean {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
			return true
		}

		val powerManager = ContextCompat.getSystemService(this, PowerManager::class.java)
			?: return false
		return powerManager.isIgnoringBatteryOptimizations(packageName)
	}

	private fun openBatteryOptimizationSettings(): Boolean {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
			return true
		}

		val directIntent = Intent(
			Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
			Uri.parse("package:$packageName")
		).apply {
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}

		val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}

		return try {
			startActivity(directIntent)
			true
		} catch (_: Throwable) {
			try {
				startActivity(fallbackIntent)
				true
			} catch (_: Throwable) {
				false
			}
		}
	}

	private fun openAutoStartSettings(): Boolean {
		val brand = Build.BRAND?.lowercase().orEmpty()

		val candidates = when {
			brand.contains("xiaomi") || brand.contains("redmi") || brand.contains("poco") -> listOf(
				Intent().setComponent(ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"))
			)
			brand.contains("oppo") || brand.contains("realme") -> listOf(
				Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")),
				Intent().setComponent(ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"))
			)
			brand.contains("vivo") -> listOf(
				Intent().setComponent(ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")),
				Intent().setComponent(ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"))
			)
			brand.contains("huawei") || brand.contains("honor") -> listOf(
				Intent().setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"))
			)
			else -> emptyList()
		}

		for (intent in candidates) {
			intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			try {
				startActivity(intent)
				return true
			} catch (_: ActivityNotFoundException) {
			} catch (_: Throwable) {
			}
		}

		return try {
			startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")).apply {
				addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			})
			true
		} catch (_: Throwable) {
			false
		}
	}

	private fun getInstalledApps(): List<Map<String, String>> {
		val pm = packageManager
		val apps = mutableListOf<Map<String, String>>()
		val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)

		for (app in packages) {
			// Skip system apps
			if ((app.flags and ApplicationInfo.FLAG_SYSTEM) != 0 && (app.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) == 0) {
				continue
			}

			val appName = pm.getApplicationLabel(app).toString()
			apps.add(mapOf(
				"packageName" to app.packageName,
				"appName" to appName
			))
		}

		// Sort by name
		apps.sortBy { it["appName"] }
		return apps
	}

	private fun getDistractingApps(): List<String> {
		val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
		val json = prefs.getString(PREF_DISTRACTING_APPS, "[]")
		return try {
			json?.split(",")?.filter { it.isNotEmpty() } ?: emptyList()
		} catch (_: Exception) {
			emptyList()
		}
	}

	private fun setDistractingApps(packages: List<String>) {
		val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
		prefs.edit()
			.putString(PREF_DISTRACTING_APPS, packages.joinToString(","))
			.apply()
	}

	private fun startFocusMode(durationMinutes: Int) {
		val endTimeMs = System.currentTimeMillis() + (durationMinutes * 60 * 1000L)
		val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
		prefs.edit()
			.putLong(PREF_FOCUS_MODE_END_TIME_MS, endTimeMs)
			.apply()
	}

	private fun getFocusModeStatus(): Map<String, Any> {
		val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
		val endTimeMs = prefs.getLong(PREF_FOCUS_MODE_END_TIME_MS, 0L)
		val nowMs = System.currentTimeMillis()
		val isActive = endTimeMs > nowMs
		val remainingMs = if (isActive) endTimeMs - nowMs else 0L
		val remainingMinutes = (remainingMs / 60 / 1000).toInt()

		return mapOf(
			"isActive" to isActive,
			"endTimeMs" to endTimeMs,
			"remainingMinutes" to remainingMinutes
		)
	}

	companion object {
		private const val ACCESSIBILITY_CONTROL_CHANNEL = "no_to_distraction/accessibility_control"
		private const val PREFS_NAME = "reels_block_prefs"
		private const val PREF_BLOCK_FB_REELS = "block_fb_reels"
		private const val PREF_BLOCK_INSTA_REELS = "block_insta_reels"
		private const val PREF_BLOCK_YT_SHORTS = "block_yt_shorts"
		private const val PREF_DISTRACTING_APPS = "distracting_apps"
		private const val PREF_FOCUS_MODE_END_TIME_MS = "focus_mode_end_ms"
		private const val PREF_FB_REELS_LOCK_UNTIL_MS = "fb_reels_lock_until_ms"
		private const val PREF_INSTA_REELS_LOCK_UNTIL_MS = "insta_reels_lock_until_ms"
		private const val PREF_YT_SHORTS_LOCK_UNTIL_MS = "yt_shorts_lock_until_ms"
	}
}
