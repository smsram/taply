package com.taply.taply

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Base64
import android.util.Log
import java.io.ByteArrayOutputStream

class AppManager(private val context: Context) {

    companion object {
        private const val TAG = "TaplyAppManager"
    }

    fun getInstalledApps(includeIcons: Boolean = true): List<Map<String, Any?>> {
        val pm = context.packageManager
        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }

        val resolveInfos: List<ResolveInfo> = try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                pm.queryIntentActivities(mainIntent, PackageManager.ResolveInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                pm.queryIntentActivities(mainIntent, 0)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error querying intent activities", e)
            emptyList()
        }

        val appList = ArrayList<Map<String, Any?>>()
        val processedPackages = HashSet<String>()

        for (info in resolveInfos) {
            val pkgName = info.activityInfo?.packageName ?: continue
            if (processedPackages.contains(pkgName)) continue
            processedPackages.add(pkgName)

            val appName = try {
                info.loadLabel(pm)?.toString() ?: pkgName
            } catch (e: Exception) {
                pkgName
            }

            val isSystemApp = try {
                val appInfo = pm.getApplicationInfo(pkgName, 0)
                (appInfo.flags and (ApplicationInfo.FLAG_SYSTEM or ApplicationInfo.FLAG_UPDATED_SYSTEM_APP)) != 0
            } catch (e: Exception) {
                false
            }

            val iconBase64 = if (includeIcons) {
                try {
                    val drawable = info.loadIcon(pm)
                    drawableToBase64(drawable)
                } catch (e: Exception) {
                    null
                }
            } else {
                null
            }

            val appMap = HashMap<String, Any?>().apply {
                put("packageName", pkgName)
                put("appName", appName)
                put("isSystemApp", isSystemApp)
                put("iconBase64", iconBase64)
            }
            appList.add(appMap)
        }

        // Sort alphabetically by app name
        appList.sortBy { (it["appName"] as? String)?.lowercase() ?: "" }
        return appList
    }

    fun launchApp(packageName: String): Boolean {
        return try {
            val pm = context.packageManager
            val intent = pm.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                true
            } else {
                Log.w(TAG, "No launch intent available for package: $packageName")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch application: $packageName", e)
            false
        }
    }

    private fun drawableToBase64(drawable: Drawable): String? {
        val bitmap = when (drawable) {
            is BitmapDrawable -> {
                if (drawable.bitmap != null && !drawable.bitmap.isRecycled) {
                    drawable.bitmap
                } else {
                    renderDrawableToBitmap(drawable)
                }
            }
            else -> renderDrawableToBitmap(drawable)
        } ?: return null

        val outputStream = ByteArrayOutputStream()
        // Compress to PNG at manageable size (64x64 max) to prevent IPC Binder TransactionTooLargeException
        val scaledBitmap = if (bitmap.width > 64 || bitmap.height > 64) {
            Bitmap.createScaledBitmap(bitmap, 64, 64, true)
        } else {
            bitmap
        }
        scaledBitmap.compress(Bitmap.CompressFormat.PNG, 75, outputStream)
        return Base64.encodeToString(outputStream.toByteArray(), Base64.NO_WRAP)
    }

    private fun renderDrawableToBitmap(drawable: Drawable): Bitmap? {
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 64
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 64
        val bitmap = Bitmap.createBitmap(width.coerceAtMost(96), height.coerceAtMost(96), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }
}

