package com.taply.taply

import android.accessibilityservice.AccessibilityService
import android.os.Build
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class TaplyAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "TaplyAccessibility"
        var instance: TaplyAccessibilityService? = null
            private set

        val isRunning: Boolean
            get() = instance != null

        fun performAction(actionId: Int): Boolean {
            val service = instance
            if (service == null) {
                Log.w(TAG, "Cannot perform action $actionId: AccessibilityService is not running")
                return false
            }
            return service.performGlobalAction(actionId)
        }

        fun performBack(): Boolean = performAction(GLOBAL_ACTION_BACK)
        fun performHome(): Boolean = performAction(GLOBAL_ACTION_HOME)
        fun performRecents(): Boolean = performAction(GLOBAL_ACTION_RECENTS)

        fun performLockScreen(): Boolean {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                performAction(GLOBAL_ACTION_LOCK_SCREEN)
            } else {
                false
            }
        }

        fun performScreenshot(): Boolean {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                performAction(GLOBAL_ACTION_TAKE_SCREENSHOT)
            } else {
                false
            }
        }

        fun performNotifications(): Boolean = performAction(GLOBAL_ACTION_NOTIFICATIONS)
        fun performQuickSettings(): Boolean = performAction(GLOBAL_ACTION_QUICK_SETTINGS)
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.i(TAG, "Taply AccessibilityService connected and active")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // No unsolicited monitoring or tracking. We strictly use Accessibility for global navigation actions.
    }

    override fun onInterrupt() {
        Log.i(TAG, "Taply AccessibilityService interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        if (instance == this) {
            instance = null
        }
        Log.i(TAG, "Taply AccessibilityService destroyed")
    }
}

