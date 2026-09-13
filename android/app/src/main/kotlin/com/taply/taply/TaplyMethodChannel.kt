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

    fun register(messenger: BinaryMessenger) {
        val channel = MethodChannel(messenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
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
                    val size = call.argument<Double>("size")
                    val opacity = call.argument<Double>("opacity")
                    val idleOpacity = call.argument<Double>("idleOpacity")
                    val edgeSnapping = call.argument<Boolean>("edgeSnapping")
                    val hapticFeedback = call.argument<Boolean>("hapticFeedback")
                    val iconStyle = call.argument<String>("iconStyle")

                    if (size != null) putExtra("size", size.toInt())
                    if (opacity != null) putExtra("opacity", opacity.toFloat())
                    if (idleOpacity != null) putExtra("idleOpacity", idleOpacity.toFloat())
                    if (edgeSnapping != null) putExtra("edgeSnapping", edgeSnapping)
                    if (hapticFeedback != null) putExtra("hapticFeedback", hapticFeedback)
                    if (iconStyle != null) putExtra("iconStyle", iconStyle)

                    val gestures = call.argument<Map<String, String>>("gestures")
                    if (gestures != null) {
                        for ((trigger, target) in gestures) {
                            putExtra("gesture_$trigger", target)
                        }
                    }
                }
                if (OverlayService.isRunning) {
                    context.startService(intent)
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
                    val apps = appManager.getInstalledApps(includeIcons)
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                        result.success(apps)
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
            // 9. SCREENSHOT
            // ==========================================
            "takeScreenshot" -> {
                result.success(screenshotManager.takeScreenshot())
            }

            // ==========================================
            // 10. DEVICE INFO
            // ==========================================
            "getDeviceInfo" -> {
                result.success(deviceInfoManager.getDeviceInfo())
            }

            // ==========================================
            // 11. COMPASS SENSOR
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

