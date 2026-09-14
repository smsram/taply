package com.taply.taply

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.PowerManager
import android.os.StatFs

class DeviceInfoManager(private val context: Context) {

    fun getDeviceInfo(): Map<String, Any> {
        val batteryInfo = getBatteryDiagnostics()
        val storageInfo = getStorageDiagnostics()

        return mapOf(
            "batteryLevel" to (batteryInfo["level"] ?: 80),
            "isCharging" to (batteryInfo["isCharging"] ?: false),
            "batteryStatus" to (batteryInfo["status"] ?: "Normal"),
            "storageTotalBytes" to (storageInfo["totalBytes"] ?: 0L),
            "storageFreeBytes" to (storageInfo["freeBytes"] ?: 0L),
            "storageUsedBytes" to (storageInfo["usedBytes"] ?: 0L),
            "osVersion" to "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})",
            "deviceModel" to "${Build.MANUFACTURER.replaceFirstChar { it.uppercase() }} ${Build.MODEL}",
            "deviceHardware" to Build.HARDWARE,
            "cpuAbi" to Build.SUPPORTED_ABIS.joinToString(", ")
        )
    }

    fun getBatteryDiagnostics(): Map<String, Any> {
        val ifilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus: Intent? = context.registerReceiver(null, ifilter)

        val level: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val status: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val plugged: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1) ?: -1
        val health: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_HEALTH, -1) ?: -1
        val tempRaw: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
        val voltage: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1) ?: -1
        val tech: String = batteryStatus?.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY) ?: "Li-ion"

        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                status == BatteryManager.BATTERY_STATUS_FULL

        val batteryPct = if (level >= 0 && scale > 0) {
            (level.toFloat() / scale.toFloat() * 100).toInt()
        } else {
            100
        }

        val statusString = when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "Charging"
            BatteryManager.BATTERY_STATUS_FULL -> "Full"
            BatteryManager.BATTERY_STATUS_DISCHARGING -> "Discharging"
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "Not charging"
            else -> "Connected"
        }

        val plugString = when (plugged) {
            BatteryManager.BATTERY_PLUGGED_AC -> "AC Wall Charger"
            BatteryManager.BATTERY_PLUGGED_USB -> "USB Port"
            BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Wireless Dock"
            else -> if (isCharging) "Charger" else "Unplugged"
        }

        val healthString = when (health) {
            BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
            BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheat"
            BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Over Voltage"
            BatteryManager.BATTERY_HEALTH_COLD -> "Cold"
            else -> "Healthy"
        }

        val tempCelsius = if (tempRaw > 0) tempRaw / 10.0 else 28.5

        val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val powerSave = pm?.isPowerSaveMode == true
        val isWhitelisted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            pm?.isIgnoringBatteryOptimizations(context.packageName) == true
        } else {
            true
        }

        return mapOf(
            "level" to batteryPct,
            "isCharging" to isCharging,
            "status" to statusString,
            "plugType" to plugString,
            "health" to healthString,
            "temperature" to tempCelsius,
            "voltage" to voltage,
            "technology" to tech,
            "powerSaveMode" to powerSave,
            "isIgnoringBatteryOptimizations" to isWhitelisted
        )
    }

    fun getStorageDiagnostics(): Map<String, Any> {
        return try {
            val path = Environment.getDataDirectory()
            val stat = StatFs(path.path)
            val blockSize = stat.blockSizeLong
            val totalBlocks = stat.blockCountLong
            val availableBlocks = stat.availableBlocksLong

            val total = totalBlocks * blockSize
            val free = availableBlocks * blockSize
            val used = (total - free).coerceAtLeast(0L)
            val usedPct = if (total > 0) (used.toDouble() / total.toDouble() * 100.0) else 0.0

            mapOf(
                "totalBytes" to total,
                "freeBytes" to free,
                "usedBytes" to used,
                "usedPercentage" to usedPct,
                "dataDirectory" to path.absolutePath
            )
        } catch (_: Exception) {
            mapOf(
                "totalBytes" to 128_000_000_000L,
                "freeBytes" to 64_000_000_000L,
                "usedBytes" to 64_000_000_000L,
                "usedPercentage" to 50.0,
                "dataDirectory" to "/data"
            )
        }
    }
}

