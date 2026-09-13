package com.taply.taply

import android.animation.ValueAnimator
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.RectF
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.util.DisplayMetrics
import android.util.Log
import android.view.GestureDetector
import android.view.Gravity
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.abs

class OverlayService : Service() {

    companion object {
        private const val TAG = "TaplyOverlayService"
        const val CHANNEL_ID = "taply_overlay_service_channel"
        const val NOTIFICATION_ID = 1001

        const val PREFS_NAME = "taply_native_prefs"
        const val KEY_POS_X = "overlay_pos_x"
        const val KEY_POS_Y = "overlay_pos_y"

        var isRunning = false
            private set

        fun start(context: Context) {
            if (!Settings.canDrawOverlays(context)) {
                Log.w(TAG, "Cannot start OverlayService: SYSTEM_ALERT_WINDOW permission missing")
                return
            }
            val intent = Intent(context, OverlayService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, OverlayService::class.java)
            context.stopService(intent)
        }
    }

    private var windowManager: WindowManager? = null
    private var floatingView: FloatingButtonView? = null
    private var layoutParams: WindowManager.LayoutParams? = null
    private var overlayPanelView: View? = null
    private lateinit var prefs: SharedPreferences

    // Config parameters
    private var buttonSizeDp = 56
    private var buttonOpacity = 0.85f
    private var idleOpacity = 0.45f
    private var edgeSnapping = true
    private var hapticFeedback = true
    private var iconStyle = "default" // default, minimal, circle, square, custom

    // Gesture targets map: trigger -> target action
    // "singleTap", "doubleTap", "longPress", "swipeUp", "swipeDown", "swipeLeft", "swipeRight"
    private val gestureActions = HashMap<String, String>().apply {
        put("singleTap", "openPanel")
        put("doubleTap", "screenshot")
        put("longPress", "quickControls")
        put("swipeUp", "appDrawer")
        put("swipeDown", "flashlight")
        put("swipeLeft", "none")
        put("swipeRight", "none")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildForegroundNotification())

        if (Settings.canDrawOverlays(this)) {
            initOverlay()
        } else {
            stopSelf()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let { handleIntentConfig(it) }
        return START_STICKY
    }

    private fun handleIntentConfig(intent: Intent) {
        if (intent.hasExtra("size")) {
            buttonSizeDp = intent.getIntExtra("size", 56)
        }
        if (intent.hasExtra("opacity")) {
            buttonOpacity = intent.getFloatExtra("opacity", 0.85f)
        }
        if (intent.hasExtra("idleOpacity")) {
            idleOpacity = intent.getFloatExtra("idleOpacity", 0.45f)
        }
        if (intent.hasExtra("edgeSnapping")) {
            edgeSnapping = intent.getBooleanExtra("edgeSnapping", true)
        }
        if (intent.hasExtra("hapticFeedback")) {
            hapticFeedback = intent.getBooleanExtra("hapticFeedback", true)
        }
        if (intent.hasExtra("iconStyle")) {
            iconStyle = intent.getStringExtra("iconStyle") ?: "default"
        }

        // Gesture updates
        val triggers = listOf("singleTap", "doubleTap", "longPress", "swipeUp", "swipeDown", "swipeLeft", "swipeRight")
        for (trigger in triggers) {
            if (intent.hasExtra("gesture_$trigger")) {
                gestureActions[trigger] = intent.getStringExtra("gesture_$trigger") ?: "none"
            }
        }

        updateOverlayViewProperties()
    }

    private fun initOverlay() {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as? WindowManager ?: return

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val sizePx = dpToPx(buttonSizeDp)
        val savedX = prefs.getInt(KEY_POS_X, getScreenWidth() - sizePx - dpToPx(8))
        val savedY = prefs.getInt(KEY_POS_Y, getScreenHeight() / 3)

        layoutParams = WindowManager.LayoutParams(
            sizePx,
            sizePx,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = savedX
            y = savedY
        }

        floatingView = FloatingButtonView(this).apply {
            alpha = buttonOpacity
            setupTouchListener()
        }

        try {
            windowManager?.addView(floatingView, layoutParams)
        } catch (e: Exception) {
            Log.e(TAG, "Error adding overlay view to WindowManager", e)
        }
    }

    private fun updateOverlayViewProperties() {
        val view = floatingView ?: return
        val wm = windowManager ?: return
        val lp = layoutParams ?: return

        val sizePx = dpToPx(buttonSizeDp)
        lp.width = sizePx
        lp.height = sizePx
        view.alpha = buttonOpacity
        view.invalidate()

        try {
            wm.updateViewLayout(view, lp)
        } catch (e: Exception) {
            Log.e(TAG, "Error updating overlay layout", e)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.overlay_notification_channel_name),
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = getString(R.string.overlay_notification_channel_desc)
                setShowBadge(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            nm?.createNotificationChannel(channel)
        }
    }

    private fun buildForegroundNotification(): Notification {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle(getString(R.string.overlay_notification_title))
            .setContentText(getString(R.string.overlay_notification_text))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    // ==========================================
    // TOUCH, DRAG, EDGE SNAPPING, AND GESTURES
    // ==========================================

    private fun FloatingButtonView.setupTouchListener() {
        val gestureDetector = GestureDetector(context, object : GestureDetector.SimpleOnGestureListener() {
            override fun onSingleTapConfirmed(e: MotionEvent): Boolean {
                handleTriggeredGesture("singleTap")
                return true
            }

            override fun onDoubleTap(e: MotionEvent): Boolean {
                handleTriggeredGesture("doubleTap")
                return true
            }

            override fun onLongPress(e: MotionEvent) {
                performHaptic()
                handleTriggeredGesture("longPress")
            }

            override fun onFling(
                e1: MotionEvent?,
                e2: MotionEvent,
                velocityX: Float,
                velocityY: Float
            ): Boolean {
                if (e1 == null) return false
                val diffX = e2.rawX - e1.rawX
                val diffY = e2.rawY - e1.rawY

                if (abs(diffX) > abs(diffY) && abs(diffX) > 80 && abs(velocityX) > 200) {
                    if (diffX > 0) {
                        handleTriggeredGesture("swipeRight")
                    } else {
                        handleTriggeredGesture("swipeLeft")
                    }
                    return true
                } else if (abs(diffY) > abs(diffX) && abs(diffY) > 80 && abs(velocityY) > 200) {
                    if (diffY > 0) {
                        handleTriggeredGesture("swipeDown")
                    } else {
                        handleTriggeredGesture("swipeUp")
                    }
                    return true
                }
                return false
            }
        })

        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var isDragging = false

        contentDescription = "Taply Floating Assistant Button"

        val idleHandler = Handler(Looper.getMainLooper())
        val idleDimRunnable = Runnable {
            try {
                animate().alpha(buttonOpacity * 0.45f).setDuration(400).start()
                animate().alpha(buttonOpacity * idleOpacity).setDuration(400).start()
            } catch (_: Exception) {}
        }

        fun resetIdleTimer() {
            idleHandler.removeCallbacks(idleDimRunnable)
            idleHandler.postDelayed(idleDimRunnable, 3500)
        }

        resetIdleTimer()

        setOnTouchListener { _, event ->
            gestureDetector.onTouchEvent(event)

            val lp = this@OverlayService.layoutParams ?: return@setOnTouchListener false
            val wm = windowManager ?: return@setOnTouchListener false

            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    idleHandler.removeCallbacks(idleDimRunnable)
                    animate().scaleX(0.92f).scaleY(0.92f).alpha(1.0f).setDuration(80).start()
                    initialX = lp.x
                    initialY = lp.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isDragging = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val deltaX = (event.rawX - initialTouchX).toInt()
                    val deltaY = (event.rawY - initialTouchY).toInt()

                    if (abs(deltaX) > 10 || abs(deltaY) > 10) {
                        isDragging = true
                    }

                    if (isDragging) {
                        lp.x = initialX + deltaX
                        lp.y = initialY + deltaY
                        try {
                            wm.updateViewLayout(this, lp)
                        } catch (_: Exception) {}
                    }
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    animate().scaleX(1.0f).scaleY(1.0f).alpha(buttonOpacity).setDuration(120).start()
                    resetIdleTimer()
                    if (isDragging && edgeSnapping) {
                        snapToEdge()
                    } else {
                        savePosition(lp.x, lp.y)
                    }
                    true
                }
                else -> false
            }
        }
    }

    private fun snapToEdge() {
        val lp = layoutParams ?: return
        val wm = windowManager ?: return
        val screenWidth = getScreenWidth()
        val sizePx = dpToPx(buttonSizeDp)
        val margin = dpToPx(8)

        val targetX = if (lp.x + (sizePx / 2) < screenWidth / 2) {
            margin
        } else {
            screenWidth - sizePx - margin
        }

        val startX = lp.x
        val animator = ValueAnimator.ofInt(startX, targetX).apply {
            duration = 220
            interpolator = DecelerateInterpolator()
            addUpdateListener { va ->
                lp.x = va.animatedValue as Int
                try {
                    wm.updateViewLayout(floatingView, lp)
                } catch (_: Exception) {}
            }
        }
        animator.start()
        savePosition(targetX, lp.y)
        performHaptic()
    }

    private fun savePosition(x: Int, y: Int) {
        prefs.edit().putInt(KEY_POS_X, x).putInt(KEY_POS_Y, y).apply()
    }

    private fun handleTriggeredGesture(trigger: String) {
        val target = gestureActions[trigger] ?: "none"
        Log.i(TAG, "Triggered gesture: $trigger -> target: $target")

        when (target) {
            "openPanel" -> openTaplyApp(route = "/floating-panel")
            "openPanel" -> toggleOverlayPanel()
            "screenshot" -> {
                dismissOverlayPanel()
                ScreenshotManager(this).takeScreenshot()
            }
            "flashlight" -> {
                SystemController(this).toggleFlashlight()
            }
            "appDrawer" -> {
                dismissOverlayPanel()
                openTaplyApp(route = "/app-drawer")
            }
            "quickControls" -> {
                dismissOverlayPanel()
                openTaplyApp(route = "/quick-controls")
            }
            "systemAction" -> {
                dismissOverlayPanel()
                TaplyAccessibilityService.performBack()
            }
            "none" -> {}
            else -> {
                dismissOverlayPanel()
                openTaplyApp()
            }
        }
    }

    fun toggleOverlayPanel() {
        if (overlayPanelView != null) {
            dismissOverlayPanel()
        } else {
            showOverlayPanel()
        }
    }

    fun dismissOverlayPanel() {
        overlayPanelView?.let { view ->
            try {
                windowManager?.removeView(view)
            } catch (e: Exception) {
                Log.e(TAG, "Error removing overlay panel view from WindowManager", e)
            }
        }
        overlayPanelView = null
    }

    fun showOverlayPanel() {
        if (overlayPanelView != null) return
        val wm = windowManager ?: return

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val lp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        val root = object : FrameLayout(this) {
            override fun dispatchKeyEvent(event: KeyEvent): Boolean {
                if (event.keyCode == KeyEvent.KEYCODE_BACK && event.action == KeyEvent.ACTION_UP) {
                    dismissOverlayPanel()
                    return true
                }
                return super.dispatchKeyEvent(event)
            }
        }.apply {
            setBackgroundColor(Color.argb(160, 11, 18, 32))
            isFocusableInTouchMode = true
            requestFocus()
            setOnClickListener {
                dismissOverlayPanel()
            }
        }

        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER
                val hMargin = dpToPx(24)
                setMargins(hMargin, 0, hMargin, 0)
            }
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(20).toFloat()
                setColor(Color.parseColor("#111827"))
                setStroke(dpToPx(1), Color.parseColor("#1F2937"))
            }
            setPadding(dpToPx(16), dpToPx(16), dpToPx(16), dpToPx(16))
            setOnClickListener {
                // Prevent tap on card from closing panel
            }
        }

        // Header
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )

            val dot = View(context).apply {
                layoutParams = LinearLayout.LayoutParams(dpToPx(8), dpToPx(8)).apply {
                    rightMargin = dpToPx(8)
                }
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(Color.parseColor("#10B981"))
                }
            }
            addView(dot)

            val title = TextView(context).apply {
                text = "Taply Assistant"
                textSize = 15f
                setTextColor(Color.WHITE)
                typeface = android.graphics.Typeface.DEFAULT_BOLD
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            }
            addView(title)

            val closeBtn = TextView(context).apply {
                text = "✕"
                textSize = 16f
                setTextColor(Color.parseColor("#9CA3AF"))
                gravity = Gravity.CENTER
                val closeSize = dpToPx(32)
                layoutParams = LinearLayout.LayoutParams(closeSize, closeSize)
                setOnClickListener {
                    dismissOverlayPanel()
                }
            }
            addView(closeBtn)
        }
        card.addView(header)

        // Divider 1
        card.addView(createDivider())

        // Row 1: Back, Home, Recents, Screenshot
        val row1 = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        row1.addView(createActionButton("◀", "Back", Color.parseColor("#2563EB")) {
            TaplyAccessibilityService.performBack()
            dismissOverlayPanel()
        })
        row1.addView(createActionButton("⌂", "Home", Color.parseColor("#2563EB")) {
            TaplyAccessibilityService.performHome()
            dismissOverlayPanel()
        })
        row1.addView(createActionButton("▢", "Recents", Color.parseColor("#2563EB")) {
            TaplyAccessibilityService.performRecents()
            dismissOverlayPanel()
        })
        row1.addView(createActionButton("⚲", "Screenshot", Color.parseColor("#14B8A6")) {
            ScreenshotManager(this@OverlayService).takeScreenshot()
            dismissOverlayPanel()
        })
        card.addView(row1)

        // Row 2: Lock, Volume, Flashlight, Settings
        val row2 = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dpToPx(8)
            }
        }
        row2.addView(createActionButton("🔒", "Lock", Color.parseColor("#EF4444")) {
            TaplyAccessibilityService.performLockScreen()
            dismissOverlayPanel()
        })
        row2.addView(createActionButton("🔊", "Volume", Color.parseColor("#8B5CF6")) {
            SystemController(this@OverlayService).openSystemSetting("sound")
            dismissOverlayPanel()
        })
        row2.addView(createActionButton("🔦", "Flashlight", Color.parseColor("#F59E0B")) {
            SystemController(this@OverlayService).toggleFlashlight()
        })
        row2.addView(createActionButton("⚙", "Settings", Color.parseColor("#64748B")) {
            SystemController(this@OverlayService).openSystemSetting("settings")
            dismissOverlayPanel()
        })
        card.addView(row2)

        // Divider 2
        card.addView(createDivider())

        // Footer pills: All Apps, Controls, Open Taply
        val footerRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        footerRow.addView(createPillButton("All Apps") {
            dismissOverlayPanel()
            openTaplyApp(route = "/app-drawer")
        })
        footerRow.addView(createPillButton("Controls") {
            dismissOverlayPanel()
            openTaplyApp(route = "/quick-controls")
        })
        footerRow.addView(createPillButton("Taply Home") {
            dismissOverlayPanel()
            openTaplyApp(route = "/home")
        })
        card.addView(footerRow)

        root.addView(card)

        overlayPanelView = root
        try {
            wm.addView(root, lp)
        } catch (e: Exception) {
            Log.e(TAG, "Error adding overlay panel view to WindowManager", e)
            overlayPanelView = null
        }
    }

    private fun createActionButton(
        icon: String,
        label: String,
        accentColor: Int,
        onClick: () -> Unit
    ): View {
        val itemLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            setPadding(dpToPx(4), dpToPx(8), dpToPx(4), dpToPx(8))
            isClickable = true
            isFocusable = true

            val badge = TextView(context).apply {
                text = icon
                textSize = 20f
                gravity = Gravity.CENTER
                setTextColor(accentColor)
                val badgeSize = dpToPx(44)
                layoutParams = LinearLayout.LayoutParams(badgeSize, badgeSize).apply {
                    gravity = Gravity.CENTER_HORIZONTAL
                }
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(Color.argb(35, Color.red(accentColor), Color.green(accentColor), Color.blue(accentColor)))
                }
            }
            addView(badge)

            val text = TextView(context).apply {
                text = label
                textSize = 11f
                setTextColor(Color.parseColor("#D1D5DB"))
                gravity = Gravity.CENTER_HORIZONTAL
                setLines(1)
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(4)
                    gravity = Gravity.CENTER_HORIZONTAL
                }
            }
            addView(text)

            setOnClickListener {
                performHaptic()
                onClick()
            }
        }
        return itemLayout
    }

    private fun createPillButton(
        label: String,
        onClick: () -> Unit
    ): View {
        val pill = TextView(this).apply {
            text = label
            textSize = 12f
            setTextColor(Color.parseColor("#9CA3AF"))
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(0, dpToPx(34), 1f).apply {
                setMargins(dpToPx(4), 0, dpToPx(4), 0)
            }
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(17).toFloat()
                setColor(Color.parseColor("#1F2937"))
            }
            setOnClickListener {
                performHaptic()
                onClick()
            }
        }
        return pill
    }

    private fun createDivider(): View {
        return View(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(1)
            ).apply {
                setMargins(0, dpToPx(12), 0, dpToPx(12))
            }
            setBackgroundColor(Color.parseColor("#1F2937"))
        }
    }

    private fun openTaplyApp(route: String? = null) {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            if (route != null) {
                putExtra("route", route)
            }
        }
        startActivity(intent)
    }

    private fun performHaptic() {
        if (!hapticFeedback) return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vm?.defaultVibrator?.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK))
            } else {
                @Suppress("DEPRECATION")
                val v = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    v?.vibrate(VibrationEffect.createOneShot(30, VibrationEffect.DEFAULT_AMPLITUDE))
                } else {
                    @Suppress("DEPRECATION")
                    v?.vibrate(30)
                }
            }
        } catch (_: Exception) {}
    }

    private fun getScreenWidth(): Int {
        val wm = getSystemService(Context.WINDOW_SERVICE) as? WindowManager ?: return 1080
        val dm = DisplayMetrics()
        @Suppress("DEPRECATION")
        wm.defaultDisplay.getMetrics(dm)
        return dm.widthPixels
    }

    private fun getScreenHeight(): Int {
        val wm = getSystemService(Context.WINDOW_SERVICE) as? WindowManager ?: return 1920
        val dm = DisplayMetrics()
        @Suppress("DEPRECATION")
        wm.defaultDisplay.getMetrics(dm)
        return dm.heightPixels
    }

    private fun dpToPx(dp: Int): Int {
        val density = resources.displayMetrics.density
        return (dp * density).toInt()
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        dismissOverlayPanel()
        floatingView?.let { view ->
            try {
                windowManager?.removeView(view)
            } catch (e: Exception) {
                Log.e(TAG, "Error removing floating view on service destroy", e)
            }
        }
        floatingView = null
        stopForeground(true)
    }

    // Custom floating button rendering
    inner class FloatingButtonView(context: Context) : View(context) {
        private val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#2563EB")
            style = Paint.Style.FILL
            setShadowLayer(12f, 0f, 6f, Color.argb(80, 0, 0, 0))
        }

        private val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(120, 255, 255, 255)
            style = Paint.Style.STROKE
            strokeWidth = 3f
        }

        private val innerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            style = Paint.Style.FILL
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            val w = width.toFloat()
            val h = height.toFloat()
            val cx = w / 2f
            val cy = h / 2f
            val radius = (w.coerceAtMost(h) / 2f) - 6f

            when (iconStyle.lowercase()) {
                "square" -> {
                    val rect = RectF(6f, 6f, w - 6f, h - 6f)
                    canvas.drawRoundRect(rect, 20f, 20f, bgPaint)
                    canvas.drawRoundRect(rect, 20f, 20f, borderPaint)
                    canvas.drawCircle(cx, cy, radius * 0.4f, innerPaint)
                }
                "minimal" -> {
                    canvas.drawCircle(cx, cy, radius, bgPaint)
                    canvas.drawCircle(cx, cy, radius * 0.35f, innerPaint)
                }
                "circle" -> {
                    canvas.drawCircle(cx, cy, radius, bgPaint)
                    canvas.drawCircle(cx, cy, radius, borderPaint)
                    innerPaint.style = Paint.Style.STROKE
                    innerPaint.strokeWidth = 5f
                    canvas.drawCircle(cx, cy, radius * 0.45f, innerPaint)
                    innerPaint.style = Paint.Style.FILL
                }
                else -> {
                    // Default Dot
                    canvas.drawCircle(cx, cy, radius, bgPaint)
                    canvas.drawCircle(cx, cy, radius, borderPaint)
                    canvas.drawCircle(cx, cy, radius * 0.45f, innerPaint)
                }
            }
        }
    }
}
