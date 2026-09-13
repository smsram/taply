package com.taply.taply

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs

class DeviceInfoManager(private val context: Context) {

    fun getDeviceInfo(): Map<String, Any> {
        val batteryInfo = getBatteryInfo()
        val storageInfo = getStorageInfo()

        return mapOf(
            "batteryLevel" to batteryInfo["level"] as Any,
            "isCharging" to batteryInfo["isCharging"] as Any,
            "batteryStatus" to batteryInfo["status"] as Any,
            "storageTotalBytes" to storageInfo["totalBytes"] as Any,
            "storageFreeBytes" to storageInfo["freeBytes"] as Any,
            "osVersion" to "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})",
            "deviceModel" to "${Build.MANUFACTURER.replaceFirstChar { it.uppercase() }} ${Build.MODEL}",
            "deviceHardware" to Build.HARDWARE
        )
    }

    private fun getBatteryInfo(): Map<String, Any> {
        val ifilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus: Intent? = context.registerReceiver(null, ifilter)

        val level: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val status: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1

        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                status == BatteryManager.BATTERY_STATUS_FULL

        val batteryPct = if (level >= 0 && scale > 0) {
            (level.toFloat() / scale.toFloat() * 100).toInt()
        } else {
            80
        }

        val statusString = when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "Charging"
            BatteryManager.BATTERY_STATUS_FULL -> "Full"
            BatteryManager.BATTERY_STATUS_DISCHARGING -> "Discharging"
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "Not charging"
            else -> "Unknown"
        }

        return mapOf(
            "level" to batteryPct,
            "isCharging" to isCharging,
            "status" to statusString
        )
    }

    private fun getStorageInfo(): Map<String, Long> {
        return try {
            val path = Environment.getDataDirectory()
            val stat = StatFs(path.path)
            val blockSize = stat.blockSizeLong
            val totalBlocks = stat.blockCountLong
            val availableBlocks = stat.availableBlocksLong

            mapOf(
                "totalBytes" to totalBlocks * blockSize,
                "freeBytes" to availableBlocks * blockSize
            )
        } catch (_: Exception) {
            mapOf(
                "totalBytes" to 128_000_000_000L,
                "freeBytes" to 64_000_000_000L
            )
        }
    }
}

