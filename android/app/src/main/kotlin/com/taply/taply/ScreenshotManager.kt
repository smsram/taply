package com.taply.taply

import android.content.Context
import android.os.Build
import android.util.Log

class ScreenshotManager(private val context: Context) {

    companion object {
        private const val TAG = "TaplyScreenshotManager"
    }

    fun takeScreenshot(): Map<String, Any> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            if (TaplyAccessibilityService.isRunning) {
                val success = TaplyAccessibilityService.performScreenshot()
                mapOf(
                    "success" to success,
                    "message" to if (success) "Screenshot captured successfully" else "Failed to capture screenshot"
                )
            } else {
                Log.w(TAG, "Screenshot requested but AccessibilityService is not enabled")
                mapOf(
                    "success" to false,
                    "requiresAccessibility" to true,
                    "message" to "Accessibility Service must be enabled in Android Settings to capture screenshots"
                )
            }
        } else {
            mapOf(
                "success" to false,
                "unsupported" to true,
                "message" to "Native global screenshot requires Android 9 (Pie) or newer"
            )
        }
    }
}

