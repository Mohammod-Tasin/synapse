package com.example.no_to_distraction

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Context
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import androidx.core.content.ContextCompat

object AccessibilityUtils {
    private const val SERVICE_SIMPLE_NAME = "ShortVideoAccessibilityService"

    fun isShortVideoServiceEnabled(context: Context): Boolean {
        val manager = ContextCompat.getSystemService(context, AccessibilityManager::class.java)
        val expectedClass = ShortVideoAccessibilityService::class.java.name
        val expectedPackage = context.packageName

        if (manager != null) {
            val enabledServices = manager.getEnabledAccessibilityServiceList(
                AccessibilityServiceInfo.FEEDBACK_ALL_MASK
            )
            val matched = enabledServices.any { serviceInfo ->
                val resolveInfo = serviceInfo.resolveInfo?.serviceInfo
                val packageName = resolveInfo?.packageName.orEmpty()
                val className = resolveInfo?.name.orEmpty()
                val classMatches =
                    className == expectedClass ||
                        className == ".$SERVICE_SIMPLE_NAME" ||
                        className.endsWith(".$SERVICE_SIMPLE_NAME")
                packageName == expectedPackage && classMatches
            }
            if (matched) {
                return true
            }
        }

        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ).orEmpty()

        if (enabledServices.isEmpty()) {
            return false
        }

        val component = ComponentName(context, ShortVideoAccessibilityService::class.java)
        val fullId = component.flattenToString()
        val shortId = component.flattenToShortString()

        return enabledServices
            .split(':')
            .map { it.trim() }
            .any { token ->
                token.equals(fullId, ignoreCase = true) ||
                    token.equals(shortId, ignoreCase = true)
            }
    }
}
