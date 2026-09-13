package com.taply.taply

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.util.Log

class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "TaplyBootReceiver"
        private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_START_WITH_DEVICE = "flutter.taply_start_with_device"
        private const val KEY_ASSISTANT_ENABLED = "flutter.taply_assistant_enabled"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED || action == "android.intent.action.QUICKBOOT_POWERON") {
            Log.i(TAG, "Device boot completed broadcast received")

            val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            val startWithDevice = flutterPrefs.getBoolean(KEY_START_WITH_DEVICE, true)
            val isAssistantEnabled = flutterPrefs.getBoolean(KEY_ASSISTANT_ENABLED, true)

            if (!startWithDevice || !isAssistantEnabled) {
                Log.i(TAG, "User opted out of start-on-boot or assistant is disabled. Skipping start.")
                return
            }

            if (Settings.canDrawOverlays(context)) {
                Log.i(TAG, "Starting OverlayService after boot")
                OverlayService.start(context)
            } else {
                Log.w(TAG, "Cannot start OverlayService after boot: Overlay permission not granted")
            }
        }
    }
}

