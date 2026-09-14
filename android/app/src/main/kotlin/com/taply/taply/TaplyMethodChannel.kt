package com.taply.taply

import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class TaplyMethodChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.taply.taply/channel"
    }

    private val permissionManager = PermissionManager(context)
    private val appManager = AppManager(context)
    private val systemController = SystemController(context)
    private val mediaController = MediaController(context)
    private val screenshotManager = ScreenshotManager(context)
    private val deviceInfoManager = DeviceInfoManager(context)
    private val compassManager = CompassManager(context)

    private var methodChannel: MethodChannel? = null

    fun register(messenger: BinaryMessenger) {
        val channel = MethodChannel(messenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        methodChannel = channel

        SystemController.addTorchListener { enabled ->
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                try {
                    methodChannel?.invokeMethod("onTorchStateChanged", mapOf("enabled" to enabled))
                } catch (e: Exception) {
                    // Ignore if engine detached
                }
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // ==========================================
            // 1. OVERLAY SERVICE
            // ==========================================
            "startOverlay" -> {
                if (!permissionManager.checkOverlayPermission()) {
                    result.success(mapOf("success" to false, "requiresPermission" to true))
                } else {
                    OverlayService.start(context)
                    result.success(mapOf("success" to true))
                }
            }
            "stopOverlay" -> {
                OverlayService.stop(context)
                result.success(mapOf("success" to true))
            }
            "isOverlayRunning" -> {
                result.success(OverlayService.isRunning)
            }
            "updateOverlayConfig" -> {
                val intent = Intent(context, OverlayService::class.java).apply {
                    action = "UPDATE_CONFIG"
                    val size = (call.argument<Number>("size"))?.toInt()
                    val opacity = (call.argument<Number>("opacity"))?.toFloat()
                    val idleOpacity = (call.argument<Number>("idleOpacity"))?.toFloat()
                    val edgeSnapping = call.argument<Boolean>("edgeSnapping")
                    val hapticFeedback = call.argument<Boolean>("hapticFeedback")
                    val iconStyle = call.argument<String>("iconStyle")
                    val color = (call.argument<Number>("color"))?.toInt()
                    val idleTimeoutSeconds = (call.argument<Number>("idleTimeoutSeconds"))?.toInt()

                    if (size != null) putExtra("size", size)
                    if (opacity != null) putExtra("opacity", opacity)
                    if (idleOpacity != null) putExtra("idleOpacity", idleOpacity)
                    if (edgeSnapping != null) putExtra("edgeSnapping", edgeSnapping)
                    if (hapticFeedback != null) putExtra("hapticFeedback", hapticFeedback)
                    if (iconStyle != null) putExtra("iconStyle", iconStyle)
                    if (color != null) putExtra("color", color)
                    if (idleTimeoutSeconds != null) putExtra("idleTimeoutSeconds", idleTimeoutSeconds)

                    val actionOrder = call.argument<List<String>>("actionOrder")
                    if (actionOrder != null) {
                        putStringArrayListExtra("actionOrder", ArrayList(actionOrder))
                    }

                    val layoutStyle = call.argument<String>("layoutStyle")
                    if (layoutStyle != null) {
                        putExtra("layoutStyle", layoutStyle)
                    }

                    val animationType = call.argument<String>("animationType")
                    if (animationType != null) {
                        putExtra("animationType", animationType)
                    }

                    val favorites = call.argument<List<String>>("favorites")
                    if (favorites != null) {
                        putStringArrayListExtra("favorites", ArrayList(favorites))
                    }

                    val gestures = call.argument<Map<String, String>>("gestures")
                    if (gestures != null) {
                        val keys = ArrayList<String>()
                        val values = ArrayList<String>()
                        for ((trigger, target) in gestures) {
                            putExtra("gesture_$trigger", target)
                            keys.add(trigger)
                            values.add(target)
                        }
                        putStringArrayListExtra("gestures_keys", keys)
                        putStringArrayListExtra("gestures_values", values)
                    }
                }

                // 1. Persist to SharedPreferences immediately (source of truth across restarts)
                val prefs = context.getSharedPreferences(OverlayService.PREFS_NAME, Context.MODE_PRIVATE)
                val editor = prefs.edit()
                intent.extras?.let { bundle ->
                    for (key in bundle.keySet()) {
                        when (val v = bundle.get(key)) {
                            is Int -> editor.putInt(key, v)
                            is Float -> editor.putFloat(key, v)
                            is Boolean -> editor.putBoolean(key, v)
                            is String -> editor.putString(key, v)
                            is ArrayList<*> -> {
                                @Suppress("UNCHECKED_CAST")
                                val strList = v as? ArrayList<String>
                                if (strList != null) {
                                    editor.putString(key, strList.joinToString(","))
                                }
                            }
                        }
                    }
                    editor.apply()
                }

                // 2. If running, notify current instance directly on the main thread for zero latency
                if (OverlayService.isRunning) {
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                        OverlayService.currentInstance?.handleIntentConfig(intent)
                    }
                    try {
                        context.startService(intent)
                    } catch (e: Exception) {
                        // Direct in-memory invocation already applied
                    }
                }
                result.success(true)
            }

            // ==========================================
            // 2. PERMISSIONS
            // ==========================================
            "checkAllPermissions" -> {
                result.success(permissionManager.checkAllPermissions())
            }
            "checkPermission" -> {
                val type = call.argument<String>("type") ?: ""
                val granted = when (type.lowercase()) {
                    "overlay" -> permissionManager.checkOverlayPermission()
                    "accessibility" -> permissionManager.checkAccessibilityPermission()
                    "notifications" -> permissionManager.checkNotificationPermission()
                    "batteryoptimization", "battery" -> permissionManager.checkBatteryOptimization()
                    "writesettings", "write_settings" -> permissionManager.checkWriteSettingsPermission()
                    else -> false
                }
                result.success(granted)
            }
            "requestPermission" -> {
                val type = call.argument<String>("type") ?: ""
                when (type.lowercase()) {
                    "overlay" -> permissionManager.openOverlaySettings()
                    "accessibility" -> permissionManager.openAccessibilitySettings()
                    "notifications" -> permissionManager.openNotificationSettings()
                    "batteryoptimization", "battery" -> permissionManager.openBatteryOptimizationSettings()
                    "writesettings", "write_settings" -> permissionManager.openWriteSettings()
                }
                result.success(true)
            }

            // ==========================================
            // 3. APPS
            // ==========================================
            "getInstalledApps" -> {
                val includeIcons = call.argument<Boolean>("includeIcons") ?: true
                Thread {
                    try {
                        val apps = appManager.getInstalledApps(includeIcons)
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            result.success(apps)
                        }
                    } catch (e: Exception) {
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            result.success(emptyList<Map<String, Any?>>())
                        }
                    }
                }.start()
            }
            "launchApp" -> {
                val packageName = call.argument<String>("packageName") ?: ""
                val success = appManager.launchApp(packageName)
                result.success(success)
            }
            "openAppDetails" -> {
                val packageName = call.argument<String>("packageName") ?: ""
                result.success(systemController.openAppDetails(packageName))
            }
            "uninstallApp" -> {
                val packageName = call.argument<String>("packageName") ?: ""
                result.success(systemController.uninstallApp(packageName))
            }

            // ==========================================
            // 4. SYSTEM ACTIONS
            // ==========================================
            "executeSystemAction" -> {
                val action = call.argument<String>("action") ?: ""
                val success = when (action.lowercase()) {
                    "back" -> TaplyAccessibilityService.performBack()
                    "home" -> TaplyAccessibilityService.performHome()
                    "recents", "recent_apps" -> TaplyAccessibilityService.performRecents()
                    "lock_screen", "lockscreen" -> TaplyAccessibilityService.performLockScreen()
                    "screenshot" -> {
                        val res = screenshotManager.takeScreenshot()
                        res["success"] as? Boolean ?: false
                    }
                    "notifications" -> TaplyAccessibilityService.performNotifications()
                    "quick_settings", "quicksettings" -> TaplyAccessibilityService.performQuickSettings()
                    else -> false
                }
                result.success(mapOf(
                    "success" to success,
                    "action" to action,
                    "accessibilityRunning" to TaplyAccessibilityService.isRunning
                ))
            }
            "openSystemSetting" -> {
                val setting = call.argument<String>("setting") ?: ""
                val success = systemController.openSystemSetting(setting)
                result.success(success)
            }

            // ==========================================
            // 5. VOLUME & SOUND
            // ==========================================
            "getVolumeLevels" -> {
                result.success(systemController.getVolumeLevels())
            }
            "setVolumeLevel" -> {
                val stream = call.argument<String>("stream") ?: "media"
                val volume = call.argument<Double>("volume") ?: 0.5
                val success = systemController.setVolumeLevel(stream, volume)
                result.success(success)
            }
            "setSoundMode" -> {
                val mode = call.argument<String>("mode") ?: "Normal"
                val success = systemController.setSoundMode(mode)
                result.success(success)
            }

            // ==========================================
            // 6. BRIGHTNESS
            // ==========================================
            "getBrightness" -> {
                result.success(systemController.getBrightness())
            }
            "setBrightness" -> {
                val brightness = call.argument<Double>("brightness") ?: 0.5
                val success = systemController.setBrightness(brightness)
                result.success(success)
            }

            // ==========================================
            // 7. FLASHLIGHT
            // ==========================================
            "toggleFlashlight" -> {
                val isTorchOn = systemController.toggleFlashlight()
                result.success(isTorchOn)
            }
            "isFlashlightOn" -> {
                result.success(systemController.isFlashlightOn())
            }
            "setTorch" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val success = systemController.setTorch(enabled)
                result.success(success)
            }

            // ==========================================
            // 8. MEDIA CONTROLS
            // ==========================================
            "dispatchMediaKey" -> {
                val keyAction = call.argument<String>("keyAction") ?: "play_pause"
                val success = mediaController.dispatchMediaKey(keyAction)
                result.success(success)
            }
            "getMediaStatus" -> {
                result.success(mediaController.getMediaStatus())
            }

            // ==========================================
            // 9. CONNECTIVITY STATUS
            // ==========================================
            "getConnectivityStatus" -> {
                result.success(systemController.getConnectivityStatus())
            }

            // ==========================================
            // 10. SCREENSHOT
            // ==========================================
            "takeScreenshot" -> {
                result.success(screenshotManager.takeScreenshot())
            }

            // ==========================================
            // 11. DEVICE & DIAGNOSTICS INFO
            // ==========================================
            "getDeviceInfo" -> {
                result.success(deviceInfoManager.getDeviceInfo())
            }
            "getBatteryDiagnostics" -> {
                result.success(deviceInfoManager.getBatteryDiagnostics())
            }
            "getStorageDiagnostics" -> {
                result.success(deviceInfoManager.getStorageDiagnostics())
            }

            // ==========================================
            // 12. COMPASS SENSOR
            // ==========================================
            "getCompassHeading" -> {
                result.success(compassManager.getHeadingData())
            }
            "startCompass" -> {
                compassManager.startListening()
                result.success(true)
            }
            "stopCompass" -> {
                compassManager.stopListening()
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }
}

