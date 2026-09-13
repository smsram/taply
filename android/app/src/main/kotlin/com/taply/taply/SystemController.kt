package com.taply.taply

import android.content.Context
import android.content.Intent
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log

class SystemController(private val context: Context) {

    companion object {
        private const val TAG = "TaplySystemController"
    }

    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
    private val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as? CameraManager

    private var isTorchOn = false
    private var torchCameraId: String? = null

    init {
        initTorch()
    }

    // ==========================================
    // 1. VOLUME & SOUND PROFILE
    // ==========================================

    fun getVolumeLevels(): Map<String, Any> {
        val am = audioManager ?: return emptyMap()

        val mediaCurrent = am.getStreamVolume(AudioManager.STREAM_MUSIC)
        val mediaMax = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)

        val ringCurrent = am.getStreamVolume(AudioManager.STREAM_RING)
        val ringMax = am.getStreamMaxVolume(AudioManager.STREAM_RING)

        val alarmCurrent = am.getStreamVolume(AudioManager.STREAM_ALARM)
        val alarmMax = am.getStreamMaxVolume(AudioManager.STREAM_ALARM)

        val ringerMode = when (am.ringerMode) {
            AudioManager.RINGER_MODE_SILENT -> "Silent"
            AudioManager.RINGER_MODE_VIBRATE -> "Vibrate"
            else -> "Normal"
        }

        return mapOf(
            "mediaVolume" to if (mediaMax > 0) mediaCurrent.toDouble() / mediaMax else 0.0,
            "ringVolume" to if (ringMax > 0) ringCurrent.toDouble() / ringMax else 0.0,
            "alarmVolume" to if (alarmMax > 0) alarmCurrent.toDouble() / alarmMax else 0.0,
            "ringerMode" to ringerMode
        )
    }

    fun setVolumeLevel(streamType: String, volumeFraction: Double): Boolean {
        val am = audioManager ?: return false
        val stream = when (streamType.lowercase()) {
            "media", "music" -> AudioManager.STREAM_MUSIC
            "ring" -> AudioManager.STREAM_RING
            "alarm" -> AudioManager.STREAM_ALARM
            else -> AudioManager.STREAM_MUSIC
        }
        val maxVol = am.getStreamMaxVolume(stream)
        val targetIndex = (volumeFraction.coerceIn(0.0, 1.0) * maxVol).toInt()
        return try {
            am.setStreamVolume(stream, targetIndex, 0)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error setting volume", e)
            false
        }
    }

    fun setSoundMode(mode: String): Boolean {
        val am = audioManager ?: return false
        return try {
            when (mode.lowercase()) {
                "silent" -> am.ringerMode = AudioManager.RINGER_MODE_SILENT
                "vibrate" -> am.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                "normal" -> am.ringerMode = AudioManager.RINGER_MODE_NORMAL
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error setting ringer mode", e)
            false
        }
    }

    // ==========================================
    // 2. BRIGHTNESS CONTROL
    // ==========================================

    fun getBrightness(): Double {
        return try {
            val brightness = Settings.System.getInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS
            )
            (brightness.toDouble() / 255.0).coerceIn(0.0, 1.0)
        } catch (e: Exception) {
            0.5
        }
    }

    fun setBrightness(brightnessFraction: Double): Boolean {
        if (!Settings.System.canWrite(context)) {
            // Permission required: open Write Settings page
            val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            try {
                context.startActivity(intent)
            } catch (_: Exception) {
                openSystemSetting("display")
            }
            return false
        }

        return try {
            val brightnessInt = (brightnessFraction.coerceIn(0.0, 1.0) * 255).toInt()
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                brightnessInt
            )
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to write system brightness", e)
            false
        }
    }

    // ==========================================
    // 3. FLASHLIGHT (CAMERA TORCH)
    // ==========================================

    private fun initTorch() {
        val cm = cameraManager ?: return
        try {
            for (id in cm.cameraIdList) {
                val characteristics = cm.getCameraCharacteristics(id)
                val hasFlash = characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) ?: false
                if (hasFlash) {
                    torchCameraId = id
                    break
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not initialize torch camera", e)
        }
    }

    fun toggleFlashlight(): Boolean {
        val cm = cameraManager ?: return false
        val camId = torchCameraId ?: return false

        return try {
            isTorchOn = !isTorchOn
            cm.setTorchMode(camId, isTorchOn)
            isTorchOn
        } catch (e: CameraAccessException) {
            Log.e(TAG, "Camera access error toggling torch", e)
            isTorchOn = false
            false
        } catch (e: Exception) {
            Log.e(TAG, "General error toggling torch", e)
            isTorchOn = false
            false
        }
    }

    fun isFlashlightOn(): Boolean = isTorchOn

    // ==========================================
    // 4. SYSTEM SETTINGS SHORTCUTS
    // ==========================================

    fun openSystemSetting(settingType: String): Boolean {
        val action = when (settingType.lowercase()) {
            "wifi" -> Settings.ACTION_WIFI_SETTINGS
            "bluetooth" -> Settings.ACTION_BLUETOOTH_SETTINGS
            "data", "mobile_data", "network" -> Settings.ACTION_WIRELESS_SETTINGS
            "hotspot", "tethering" -> "android.settings.TETHER_SETTINGS"
            "airplane" -> Settings.ACTION_AIRPLANE_MODE_SETTINGS
            "nfc" -> Settings.ACTION_NFC_SETTINGS
            "cast" -> Settings.ACTION_CAST_SETTINGS
            "location" -> Settings.ACTION_LOCATION_SOURCE_SETTINGS
            "vpn" -> Settings.ACTION_VPN_SETTINGS
            "display" -> Settings.ACTION_DISPLAY_SETTINGS
            "sound" -> Settings.ACTION_SOUND_SETTINGS
            "date" -> Settings.ACTION_DATE_SETTINGS
            "security" -> Settings.ACTION_SECURITY_SETTINGS
            else -> Settings.ACTION_SETTINGS
        }

        return try {
            val intent = Intent(action).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open setting $settingType", e)
            try {
                context.startActivity(Intent(Settings.ACTION_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    // ==========================================
    // 5. APPLICATION MANAGEMENT
    // ==========================================

    fun openAppDetails(packageName: String): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open app details for $packageName", e)
            false
        }
    }

    fun uninstallApp(packageName: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_UNINSTALL_PACKAGE).apply {
                data = Uri.parse("package:$packageName")
                putExtra(Intent.EXTRA_RETURN_RESULT, false)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to prompt uninstall for $packageName", e)
            false
        }
    }
}
