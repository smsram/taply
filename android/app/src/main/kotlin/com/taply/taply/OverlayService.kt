package com.taply.taply

import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.app.ActivityManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorFilter
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.text.Editable
import android.text.TextWatcher
import android.util.DisplayMetrics
import android.util.Log
import android.view.GestureDetector
import android.view.Gravity
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import android.view.animation.OvershootInterpolator
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.SeekBar
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
    private var idleTimeoutSeconds = 3
    private var buttonColor = Color.parseColor("#2563EB")
    private var edgeSnapping = true
    private var hapticFeedback = true
    private var iconStyle = "default"
    private var layoutStyle = "multiPage"
    private var animationType = "fadeScale"

    private var actionOrder = arrayListOf(
        "back", "home", "recents", "screenshot", "lockScreen", "volume", "flashlight", "settings"
    )
    private var favoritesList = arrayListOf<String>()

    // Gesture targets map: trigger -> target action
    private val gestureActions = HashMap<String, String>().apply {
        put("singleTap", "openPanel")
        put("doubleTap", "screenshot")
        put("longPress", "quickControls")
        put("swipeUp", "appDrawer")
        put("swipeDown", "flashlight")
        put("swipeLeft", "none")
        put("swipeRight", "none")
    }

    // Overlay carousel / tool state
    private var activeCarouselTabIndex = 0
    private var activeOverlayTool: String? = null // "calculator", "stopwatch", "timer", "notes", "device_info"

    // Stopwatch state
    private var stopwatchRunning = false
    private var stopwatchStartTime = 0L
    private var stopwatchElapsedTime = 0L
    private val stopwatchHandler = Handler(Looper.getMainLooper())
    private var stopwatchRunnable: Runnable? = null
    private var stopwatchTextView: TextView? = null

    // Timer state
    private var timerRunning = false
    private var timerTotalSeconds = 300 // default 5 min
    private var timerRemainingSeconds = 300
    private val timerHandler = Handler(Looper.getMainLooper())
    private var timerRunnable: Runnable? = null
    private var timerTextView: TextView? = null

    // Idle timer
    private val idleHandler = Handler(Looper.getMainLooper())
    private val idleRunnable = Runnable {
        floatingView?.let { view ->
            view.animate()
                .alpha(idleOpacity)
                .setDuration(400)
                .start()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        loadPersistedConfig()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildForegroundNotification())
        initOverlay()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let { handleIntentConfig(it) }
        return START_STICKY
    }

    private fun loadPersistedConfig() {
        buttonSizeDp = prefs.getInt("size", 56)
        buttonOpacity = prefs.getFloat("opacity", 0.85f)
        idleOpacity = prefs.getFloat("idleOpacity", 0.45f)
        idleTimeoutSeconds = prefs.getInt("idleTimeoutSeconds", 3)
        buttonColor = prefs.getInt("color", Color.parseColor("#2563EB"))
        edgeSnapping = prefs.getBoolean("edgeSnapping", true)
        hapticFeedback = prefs.getBoolean("hapticFeedback", true)
        iconStyle = prefs.getString("iconStyle", "default") ?: "default"
        layoutStyle = prefs.getString("layoutStyle", "multiPage") ?: "multiPage"
        animationType = prefs.getString("animationType", "fadeScale") ?: "fadeScale"

        val rawActions = prefs.getString("actionOrder", null)
        if (!rawActions.isNullOrEmpty()) {
            actionOrder.clear()
            actionOrder.addAll(rawActions.split(",").filter { it.isNotBlank() })
        }

        val rawFavs = prefs.getString("favorites", null)
        if (!rawFavs.isNullOrEmpty()) {
            favoritesList.clear()
            favoritesList.addAll(rawFavs.split(",").filter { it.isNotBlank() })
        }

        for (trigger in listOf("singleTap", "doubleTap", "longPress", "swipeUp", "swipeDown", "swipeLeft", "swipeRight")) {
            val savedTarget = prefs.getString("gesture_$trigger", null)
            if (savedTarget != null) {
                gestureActions[trigger] = savedTarget
            }
        }
    }

    private fun handleIntentConfig(intent: Intent) {
        val editor = prefs.edit()
        var changed = false

        if (intent.hasExtra("size")) {
            buttonSizeDp = intent.getIntExtra("size", buttonSizeDp)
            editor.putInt("size", buttonSizeDp)
            changed = true
        }
        if (intent.hasExtra("opacity")) {
            buttonOpacity = intent.getFloatExtra("opacity", buttonOpacity)
            editor.putFloat("opacity", buttonOpacity)
            changed = true
        }
        if (intent.hasExtra("idleOpacity")) {
            idleOpacity = intent.getFloatExtra("idleOpacity", idleOpacity)
            editor.putFloat("idleOpacity", idleOpacity)
            changed = true
        }
        if (intent.hasExtra("idleTimeoutSeconds")) {
            idleTimeoutSeconds = intent.getIntExtra("idleTimeoutSeconds", idleTimeoutSeconds)
            editor.putInt("idleTimeoutSeconds", idleTimeoutSeconds)
            changed = true
        }
        if (intent.hasExtra("color")) {
            buttonColor = intent.getIntExtra("color", buttonColor)
            editor.putInt("color", buttonColor)
            changed = true
        }
        if (intent.hasExtra("edgeSnapping")) {
            edgeSnapping = intent.getBooleanExtra("edgeSnapping", edgeSnapping)
            editor.putBoolean("edgeSnapping", edgeSnapping)
            changed = true
        }
        if (intent.hasExtra("hapticFeedback")) {
            hapticFeedback = intent.getBooleanExtra("hapticFeedback", hapticFeedback)
            editor.putBoolean("hapticFeedback", hapticFeedback)
            changed = true
        }
        if (intent.hasExtra("iconStyle")) {
            iconStyle = intent.getStringExtra("iconStyle") ?: iconStyle
            editor.putString("iconStyle", iconStyle)
            changed = true
        }
        if (intent.hasExtra("layoutStyle")) {
            layoutStyle = intent.getStringExtra("layoutStyle") ?: layoutStyle
            editor.putString("layoutStyle", layoutStyle)
            changed = true
        }
        if (intent.hasExtra("animationType")) {
            animationType = intent.getStringExtra("animationType") ?: animationType
            editor.putString("animationType", animationType)
            changed = true
        }

        intent.getStringArrayListExtra("actionOrder")?.let { list ->
            actionOrder.clear()
            actionOrder.addAll(list)
            editor.putString("actionOrder", list.joinToString(","))
            changed = true
        }

        intent.getStringArrayListExtra("favorites")?.let { list ->
            favoritesList.clear()
            favoritesList.addAll(list)
            editor.putString("favorites", list.joinToString(","))
            changed = true
        }

        intent.getStringArrayListExtra("gestures_keys")?.let { keys ->
            intent.getStringArrayListExtra("gestures_values")?.let { values ->
                for (i in 0 until keys.size.coerceAtMost(values.size)) {
                    gestureActions[keys[i]] = values[i]
                    editor.putString("gesture_${keys[i]}", values[i])
                }
                changed = true
            }
        }

        editor.apply()

        if (changed) {
            updateOverlayViewProperties()
            if (overlayPanelView != null) {
                rebuildPanelCard()
            }
        }
    }

    private fun clampX(x: Int, sizePx: Int): Int {
        val screenW = getScreenWidth()
        val minX = dpToPx(8)
        val maxX = (screenW - sizePx - dpToPx(8)).coerceAtLeast(minX)
        return x.coerceIn(minX, maxX)
    }

    private fun clampY(y: Int, sizePx: Int): Int {
        val screenH = getScreenHeight()
        val minY = dpToPx(28)
        val maxY = (screenH - sizePx - dpToPx(48)).coerceAtLeast(minY)
        return y.coerceIn(minY, maxY)
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        layoutParams?.let { lp ->
            val sizePx = dpToPx(buttonSizeDp)
            val clampedX = clampX(lp.x, sizePx)
            val clampedY = clampY(lp.y, sizePx)
            if (lp.x != clampedX || lp.y != clampedY) {
                lp.x = clampedX
                lp.y = clampedY
                savePosition(clampedX, clampedY)
                floatingView?.let { view ->
                    try {
                        windowManager?.updateViewLayout(view, lp)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error updating layout on configuration changed", e)
                    }
                }
            }
        }
        if (overlayPanelView != null) {
            dismissOverlayPanel()
            showOverlayPanel()
        }
    }

    private fun initOverlay() {
        val sizePx = dpToPx(buttonSizeDp)
        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val savedX = prefs.getInt(KEY_POS_X, dpToPx(20))
        val savedY = prefs.getInt(KEY_POS_Y, dpToPx(150))
        val clampedX = clampX(savedX, sizePx)
        val clampedY = clampY(savedY, sizePx)

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
            x = clampedX
            y = clampedY
        }

        floatingView = FloatingButtonView(this).apply {
            alpha = buttonOpacity
            setupTouchListener()
        }

        try {
            windowManager?.addView(floatingView, layoutParams)
            resetIdleTimer()
        } catch (e: Exception) {
            Log.e(TAG, "Error adding floating view to WindowManager", e)
        }
    }

    private fun updateOverlayViewProperties() {
        val sizePx = dpToPx(buttonSizeDp)
        layoutParams?.let { lp ->
            lp.width = sizePx
            lp.height = sizePx
            floatingView?.let { view ->
                view.alpha = buttonOpacity
                view.invalidate()
                try {
                    windowManager?.updateViewLayout(view, lp)
                } catch (e: Exception) {
                    Log.e(TAG, "Error updating overlay view layout", e)
                }
            }
        }
        resetIdleTimer()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Taply Assistant Service"
            val descriptionText = "Displays the persistent floating assistive touch button"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(false)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun buildForegroundNotification(): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("Taply – Assistive Touch")
            .setContentText("Everything, one tap away.")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun FloatingButtonView.setupTouchListener() {
        val gestureDetector = GestureDetector(context, object : GestureDetector.SimpleOnGestureListener() {
            override fun onSingleTapConfirmed(e: MotionEvent): Boolean {
                performHaptic()
                handleTriggeredGesture("singleTap")
                return true
            }

            override fun onDoubleTap(e: MotionEvent): Boolean {
                performHaptic()
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
                val diffX = e2.x - e1.x
                val diffY = e2.y - e1.y
                if (abs(diffX) > abs(diffY)) {
                    if (abs(diffX) > 100 && abs(velocityX) > 200) {
                        performHaptic()
                        if (diffX > 0) handleTriggeredGesture("swipeRight")
                        else handleTriggeredGesture("swipeLeft")
                        return true
                    }
                } else {
                    if (abs(diffY) > 100 && abs(velocityY) > 200) {
                        performHaptic()
                        if (diffY > 0) handleTriggeredGesture("swipeDown")
                        else handleTriggeredGesture("swipeUp")
                        return true
                    }
                }
                return false
            }
        })

        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var isDragging = false

        setOnTouchListener { _, event ->
            gestureDetector.onTouchEvent(event)
            resetIdleTimer()

            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = this@OverlayService.layoutParams?.x ?: 0
                    initialY = this@OverlayService.layoutParams?.y ?: 0
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isDragging = false
                    alpha = buttonOpacity
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val deltaX = (event.rawX - initialTouchX).toInt()
                    val deltaY = (event.rawY - initialTouchY).toInt()

                    if (abs(deltaX) > 10 || abs(deltaY) > 10) {
                        isDragging = true
                    }

                    if (isDragging) {
                        this@OverlayService.layoutParams?.let { lp ->
                            lp.x = initialX + deltaX
                            lp.y = initialY + deltaY
                            val sizePx = dpToPx(buttonSizeDp)
                            lp.x = clampX(initialX + deltaX, sizePx)
                            lp.y = clampY(initialY + deltaY, sizePx)
                            try {
                                windowManager?.updateViewLayout(this@setupTouchListener, lp)
                            } catch (e: Exception) {
                                Log.e(TAG, "Error moving floating view", e)
                            }
                        }
                    }
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    if (isDragging && edgeSnapping) {
                        snapToEdge()
                    } else if (isDragging) {
                        this@OverlayService.layoutParams?.let { lp ->
                            savePosition(lp.x, lp.y)
                            val sizePx = dpToPx(buttonSizeDp)
                            val clampedX = clampX(lp.x, sizePx)
                            val clampedY = clampY(lp.y, sizePx)
                            lp.x = clampedX
                            lp.y = clampedY
                            savePosition(clampedX, clampedY)
                        }
                    }
                    resetIdleTimer()
                    true
                }
                else -> false
            }
        }
    }

    fun resetIdleTimer() {
        idleHandler.removeCallbacks(idleRunnable)
        floatingView?.let { view ->
            if (view.alpha != buttonOpacity) {
                view.alpha = buttonOpacity
            }
        }
        if (idleTimeoutSeconds > 0) {
            idleHandler.postDelayed(idleRunnable, (idleTimeoutSeconds * 1000).toLong())
        }
    }

    private fun snapToEdge() {
        val lp = layoutParams ?: return
        val screenWidth = getScreenWidth()
        val buttonWidth = dpToPx(buttonSizeDp)

        val targetX = if (lp.x + buttonWidth / 2 < screenWidth / 2) {
            dpToPx(12) // snap left
            clampX(dpToPx(12), buttonWidth) // snap left
        } else {
            screenWidth - buttonWidth - dpToPx(12) // snap right
            clampX(screenWidth - buttonWidth - dpToPx(12), buttonWidth) // snap right
        }
        val targetY = clampY(lp.y, buttonWidth)
        lp.y = targetY

        val animator = ValueAnimator.ofInt(lp.x, targetX).apply {
            duration = 250
            interpolator = DecelerateInterpolator()
            addUpdateListener { animation ->
                lp.x = animation.animatedValue as Int
                try {
                    floatingView?.let { windowManager?.updateViewLayout(it, lp) }
                } catch (e: Exception) {
                    Log.e(TAG, "Error snapping to edge", e)
                }
            }
        }
        animator.start()
        savePosition(targetX, lp.y)
        savePosition(targetX, targetY)
    }

    private fun savePosition(x: Int, y: Int) {
        prefs.edit().putInt(KEY_POS_X, x).putInt(KEY_POS_Y, y).apply()
    }

    private fun handleTriggeredGesture(trigger: String) {
        val target = gestureActions[trigger] ?: "openPanel"
        when (target) {
            "openPanel" -> toggleOverlayPanel()
            "quickControls" -> openTaplyApp(route = "/quick-controls")
            "appDrawer" -> openTaplyApp(route = "/app-drawer")
            "flashlight" -> SystemController(this).toggleFlashlight()
            "screenshot" -> ScreenshotManager(this).takeScreenshot()
            "back" -> TaplyAccessibilityService.performBack()
            "home" -> TaplyAccessibilityService.performHome()
            "recents" -> TaplyAccessibilityService.performRecents()
            "lockScreen" -> TaplyAccessibilityService.performLockScreen()
            "notifications" -> TaplyAccessibilityService.performNotifications()
            "none" -> { /* No-op */ }
            else -> openTaplyApp(route = "/home")
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
        stopwatchRunning = false
        stopwatchRunnable?.let { stopwatchHandler.removeCallbacks(it) }
        timerRunning = false
        timerRunnable?.let { timerHandler.removeCallbacks(it) }
        activeOverlayTool = null

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
                    if (activeOverlayTool != null) {
                        activeOverlayTool = null
                        rebuildPanelCard()
                        return true
                    }
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

        val screenWidth = getScreenWidth()
        val isLandscape = resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        val targetWidth = if (isLandscape) {
            dpToPx(380).coerceAtMost((screenWidth * 0.75f).toInt())
        } else {
            dpToPx(350).coerceAtMost(screenWidth - dpToPx(32))
        }

        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            tag = "panel_card"
            layoutParams = FrameLayout.LayoutParams(
                targetWidth,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER
                val hMargin = dpToPx(16)
                setMargins(hMargin, dpToPx(16), hMargin, dpToPx(16))
            }
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(20).toFloat()
                setColor(Color.parseColor("#111827"))
                setStroke(dpToPx(1), Color.parseColor("#1F2937"))
            }
            setPadding(dpToPx(16), dpToPx(16), dpToPx(16), dpToPx(16))
            setOnClickListener {
                // Prevent card taps from dismissing overlay
            }
        }

        renderPanelCard(card)
        root.addView(card)
        overlayPanelView = root

        try {
            wm.addView(root, lp)
            applyPanelEnterAnimation(card)
        } catch (e: Exception) {
            Log.e(TAG, "Error adding overlay panel view to WindowManager", e)
            overlayPanelView = null
        }
    }

    private fun applyPanelEnterAnimation(card: View) {
        when (animationType.lowercase()) {
            "slideup" -> {
                card.translationY = dpToPx(250).toFloat()
                card.alpha = 0f
                val animSet = AnimatorSet()
                animSet.playTogether(
                    ObjectAnimator.ofFloat(card, "translationY", 0f),
                    ObjectAnimator.ofFloat(card, "alpha", 1f)
                )
                animSet.duration = 260
                animSet.interpolator = DecelerateInterpolator()
                animSet.start()
            }
            "spring" -> {
                card.scaleX = 0.65f
                card.scaleY = 0.65f
                card.alpha = 0f
                val animSet = AnimatorSet()
                animSet.playTogether(
                    ObjectAnimator.ofFloat(card, "scaleX", 1f),
                    ObjectAnimator.ofFloat(card, "scaleY", 1f),
                    ObjectAnimator.ofFloat(card, "alpha", 1f)
                )
                animSet.duration = 320
                animSet.interpolator = OvershootInterpolator(1.4f)
                animSet.start()
            }
            "none" -> {
                card.alpha = 1f
            }
            else -> {
                // Default "fadeScale"
                card.scaleX = 0.85f
                card.scaleY = 0.85f
                card.alpha = 0f
                val animSet = AnimatorSet()
                animSet.playTogether(
                    ObjectAnimator.ofFloat(card, "scaleX", 1f),
                    ObjectAnimator.ofFloat(card, "scaleY", 1f),
                    ObjectAnimator.ofFloat(card, "alpha", 1f)
                )
                animSet.duration = 220
                animSet.interpolator = DecelerateInterpolator()
                animSet.start()
            }
        }
    }

    private fun rebuildPanelCard() {
        val root = overlayPanelView as? FrameLayout ?: return
        val card = root.findViewWithTag<LinearLayout>("panel_card") ?: return
        renderPanelCard(card)
    }

    private fun renderPanelCard(card: LinearLayout) {
        card.removeAllViews()

        // 1. Header
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        if (activeOverlayTool != null) {
            val backBtn = TextView(this).apply {
                text = "← Back"
                textSize = 13f
                setTextColor(buttonColor)
                typeface = Typeface.DEFAULT_BOLD
                setPadding(dpToPx(4), dpToPx(6), dpToPx(8), dpToPx(6))
                setOnClickListener {
                    performHaptic()
                    activeOverlayTool = null
                    rebuildPanelCard()
                }
            }
            header.addView(backBtn)

            val title = TextView(this).apply {
                text = when (activeOverlayTool) {
                    "calculator" -> "Calculator"
                    "stopwatch" -> "Stopwatch"
                    "timer" -> "Timer"
                    "notes" -> "Quick Notes"
                    "device_info" -> "Device Telemetry"
                    else -> "Tool"
                }
                textSize = 15f
                setTextColor(Color.WHITE)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            }
            header.addView(title)
        } else {
            val dot = View(this).apply {
                layoutParams = LinearLayout.LayoutParams(dpToPx(8), dpToPx(8)).apply {
                    rightMargin = dpToPx(8)
                }
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(Color.parseColor("#10B981"))
                }
            }
            header.addView(dot)

            val title = TextView(this).apply {
                text = "Taply Assistant"
                textSize = 15f
                setTextColor(Color.WHITE)
                typeface = Typeface.DEFAULT_BOLD
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            }
            header.addView(title)
        }

        if (activeOverlayTool == null) {
            val settingsBtn = ImageView(this).apply {
                val iconSize = dpToPx(32)
                layoutParams = LinearLayout.LayoutParams(iconSize, iconSize).apply {
                    rightMargin = dpToPx(4)
                }
                setPadding(dpToPx(6), dpToPx(6), dpToPx(6), dpToPx(6))
                setImageDrawable(ActionIconDrawable("settings", Color.parseColor("#9CA3AF"), dpToPx(20)))
                setOnClickListener {
                    performHaptic()
                    dismissOverlayPanel()
                    openTaplyApp(route = "/settings")
                }
            }
            header.addView(settingsBtn)
        }

        val closeBtn = ImageView(this).apply {
            val closeSize = dpToPx(32)
            layoutParams = LinearLayout.LayoutParams(closeSize, closeSize)
            setPadding(dpToPx(6), dpToPx(6), dpToPx(6), dpToPx(6))
            setImageDrawable(ActionIconDrawable("close", Color.parseColor("#9CA3AF"), dpToPx(20)))
            setOnClickListener {
                performHaptic()
                dismissOverlayPanel()
            }
        }
        header.addView(closeBtn)
        card.addView(header)

        card.addView(createDivider())

        // 2. Body based on active tool or layout style
        if (activeOverlayTool != null) {
            val toolScroll = ScrollView(this).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
                isFillViewport = true
            }
            val toolContainer = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }
            when (activeOverlayTool) {
                "calculator" -> renderCalculatorTool(toolContainer)
                "stopwatch" -> renderStopwatchTool(toolContainer)
                "timer" -> renderTimerTool(toolContainer)
                "notes" -> renderNotesTool(toolContainer)
                "device_info" -> renderDeviceInfoTool(toolContainer)
            }
            toolScroll.addView(toolContainer)
            card.addView(toolScroll)
            return
        }

        when (layoutStyle.lowercase()) {
            "grid3x3" -> renderGrid3x3(card)
            "grid4x2" -> renderGrid4x2(card)
            "compactwheel" -> renderCompactWheel(card)
            "verticallist" -> renderVerticalList(card)
            else -> renderMultiPageLayout(card) // default "multiPage"
        }
    }

    // ==========================================
    // MULTI-PAGE CAROUSEL LAYOUT & TABS
    // ==========================================

    private fun renderMultiPageLayout(card: LinearLayout) {
        val tabScroll = HorizontalScrollView(this).apply {
            isHorizontalScrollBarEnabled = false
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(12)
            }
        }

        val tabRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        val tabTitles = listOf("Actions", "Apps", "Tools", "Controls")
        if (activeCarouselTabIndex >= tabTitles.size) {
            activeCarouselTabIndex = 0
        }
        for (i in tabTitles.indices) {
            val isSelected = (i == activeCarouselTabIndex)
            val tabPill = TextView(this).apply {
                text = tabTitles[i]
                textSize = 12f
                typeface = if (isSelected) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
                setTextColor(if (isSelected) Color.WHITE else Color.parseColor("#9CA3AF"))
                setPadding(dpToPx(12), dpToPx(6), dpToPx(12), dpToPx(6))
                background = GradientDrawable().apply {
                    shape = GradientDrawable.RECTANGLE
                    cornerRadius = dpToPx(14).toFloat()
                    setColor(if (isSelected) buttonColor else Color.parseColor("#1F2937"))
                }
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    rightMargin = dpToPx(6)
                }
                setOnClickListener {
                    performHaptic()
                    activeCarouselTabIndex = i
                    rebuildPanelCard()
                }
            }
            tabRow.addView(tabPill)
        }
        tabScroll.addView(tabRow)
        card.addView(tabScroll)

        when (activeCarouselTabIndex) {
            0 -> renderActionsAndFavoritesTab(card)
            1 -> renderAppsTab(card)
            2 -> renderToolsTab(card)
            3 -> renderControlsTab(card)
        }
    }

    private fun renderActionsAndFavoritesTab(card: LinearLayout) {
        val actionsToRender = if (actionOrder.isNotEmpty()) actionOrder else listOf(
            "back", "home", "recents", "screenshot", "lockScreen", "volume", "flashlight", "settings"
        )

        // Row 1 (Actions 0..3)
        val row1 = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        for (i in 0 until 4) {
            if (i < actionsToRender.size) {
                row1.addView(buildActionTile(actionsToRender[i]))
            }
        }
        card.addView(row1)

        // Row 2 (Actions 4..7)
        if (actionsToRender.size > 4) {
            val row2 = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(8)
                }
            }
            for (i in 4 until 8) {
                if (i < actionsToRender.size) {
                    row2.addView(buildActionTile(actionsToRender[i]))
                }
            }
            card.addView(row2)
        }

        // Favorites Bar
        if (favoritesList.isNotEmpty()) {
            card.addView(createDivider())

            val favHeader = TextView(this).apply {
                text = "★ FAVORITES"
                textSize = 10f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(Color.parseColor("#9CA3AF"))
                setPadding(dpToPx(2), dpToPx(2), 0, dpToPx(6))
            }
            card.addView(favHeader)

            val favScroll = HorizontalScrollView(this).apply {
                isHorizontalScrollBarEnabled = false
            }
            val favRow = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
            }

            val pm = packageManager
            for (pkg in favoritesList) {
                val appLabel = try {
                    val appInfo = pm.getApplicationInfo(pkg, 0)
                    pm.getApplicationLabel(appInfo).toString()
                } catch (e: Exception) {
                    pkg.substringAfterLast(".")
                }
                val iconDrawable = try {
                    pm.getApplicationIcon(pkg)
                } catch (e: Exception) {
                    pm.defaultActivityIcon
                }
                val favView = LinearLayout(this).apply {
                    orientation = LinearLayout.VERTICAL
                    gravity = Gravity.CENTER
                    layoutParams = LinearLayout.LayoutParams(dpToPx(56), LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                        rightMargin = dpToPx(8)
                    }
                    val iconView = ImageView(context).apply {
                        val iconSize = dpToPx(38)
                        layoutParams = LinearLayout.LayoutParams(iconSize, iconSize)
                        setImageDrawable(iconDrawable)
                    }
                    val nameView = TextView(context).apply {
                        text = appLabel
                        textSize = 10f
                        setTextColor(Color.parseColor("#D1D5DB"))
                        gravity = Gravity.CENTER
                        setLines(1)
                    }
                    addView(iconView)
                    addView(nameView)
                    setOnClickListener {
                        performHaptic()
                        dismissOverlayPanel()
                        AppManager(this@OverlayService).launchApp(pkg)
                    }
                }
                favRow.addView(favView)
            }
            favScroll.addView(favRow)
            card.addView(favScroll)
        }

        card.addView(createDivider())
        card.addView(createFooterPills())
    }

    private fun buildActionTile(actionKey: String): View {
        return when (actionKey.lowercase()) {
            "back" -> createActionButton("back", "Back", Color.parseColor("#2563EB")) {
                TaplyAccessibilityService.performBack()
                dismissOverlayPanel()
            }
            "home" -> createActionButton("home", "Home", Color.parseColor("#2563EB")) {
                TaplyAccessibilityService.performHome()
                dismissOverlayPanel()
            }
            "recents" -> createActionButton("recents", "Recents", Color.parseColor("#2563EB")) {
                TaplyAccessibilityService.performRecents()
                dismissOverlayPanel()
            }
            "screenshot" -> createActionButton("screenshot", "Screenshot", Color.parseColor("#14B8A6")) {
                ScreenshotManager(this).takeScreenshot()
                dismissOverlayPanel()
            }
            "lockscreen", "lock_screen", "lock" -> createActionButton("lock", "Lock", Color.parseColor("#EF4444")) {
                TaplyAccessibilityService.performLockScreen()
                dismissOverlayPanel()
            }
            "volume" -> createActionButton("volume", "Volume", Color.parseColor("#8B5CF6")) {
                SystemController(this).openSystemSetting("sound")
                dismissOverlayPanel()
            }
            "flashlight" -> createActionButton("flashlight", "Flashlight", Color.parseColor("#F59E0B")) {
                SystemController(this).toggleFlashlight()
            }
            "notifications" -> createActionButton("notifications", "Notifs", Color.parseColor("#3B82F6")) {
                TaplyAccessibilityService.performNotifications()
                dismissOverlayPanel()
            }
            "quicksettings", "quick_settings" -> createActionButton("quick_settings", "Quick", Color.parseColor("#06B6D4")) {
                TaplyAccessibilityService.performQuickSettings()
                dismissOverlayPanel()
            }
            "calculator" -> createActionButton("calculator", "Calc", buttonColor) {
                activeOverlayTool = "calculator"
                rebuildPanelCard()
            }
            "timer" -> createActionButton("timer", "Timer", Color.parseColor("#F59E0B")) {
                activeOverlayTool = "timer"
                rebuildPanelCard()
            }
            "stopwatch" -> createActionButton("stopwatch", "Stopwatch", Color.parseColor("#10B981")) {
                activeOverlayTool = "stopwatch"
                rebuildPanelCard()
            }
            "notes" -> createActionButton("notes", "Notes", Color.parseColor("#8B5CF6")) {
                activeOverlayTool = "notes"
                rebuildPanelCard()
            }
            "deviceinfo", "device_info" -> createActionButton("device_info", "Device", Color.parseColor("#06B6D4")) {
                activeOverlayTool = "device_info"
                rebuildPanelCard()
            }
            else -> createActionButton("settings", "Settings", Color.parseColor("#64748B")) {
                SystemController(this).openSystemSetting("settings")
                dismissOverlayPanel()
            }
        }
    }

    private fun renderAppsTab(card: LinearLayout) {
        val appManager = AppManager(this)
        val allApps = appManager.getInstalledApps(includeIcons = false).sortedBy {
            (it["appName"] as? String)?.lowercase() ?: ""
        }

        // Search bar
        val searchBox = EditText(this).apply {
            hint = "Search apps..."
            setHintTextColor(Color.parseColor("#6B7280"))
            setTextColor(Color.WHITE)
            textSize = 13f
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(10).toFloat()
                setColor(Color.parseColor("#1F2937"))
            }
            setPadding(dpToPx(12), dpToPx(8), dpToPx(12), dpToPx(8))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(8)
            }
        }
        card.addView(searchBox)

        val appScroll = ScrollView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(200)
            )
        }
        val appListContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }

        fun populateList(filter: String = "") {
            appListContainer.removeAllViews()
            val filtered = if (filter.isBlank()) allApps else allApps.filter {
                val name = (it["appName"] as? String) ?: ""
                val pkg = (it["packageName"] as? String) ?: ""
                name.contains(filter, ignoreCase = true) || pkg.contains(filter, ignoreCase = true)
            }

            val pm = packageManager
            for (app in filtered.take(20)) {
                val pkgName = (app["packageName"] as? String) ?: continue
                val appName = (app["appName"] as? String) ?: pkgName
                val iconDrawable = try {
                    pm.getApplicationIcon(pkgName)
                } catch (e: Exception) {
                    pm.defaultActivityIcon
                }

                val row = LinearLayout(this).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    setPadding(dpToPx(6), dpToPx(6), dpToPx(6), dpToPx(6))
                    val icon = ImageView(context).apply {
                        val s = dpToPx(32)
                        layoutParams = LinearLayout.LayoutParams(s, s)
                        setImageDrawable(iconDrawable)
                    }
                    val label = TextView(context).apply {
                        text = appName
                        textSize = 13f
                        setTextColor(Color.WHITE)
                        layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
                            leftMargin = dpToPx(10)
                        }
                    }
                    val favIndicator = TextView(context).apply {
                        val isFav = favoritesList.contains(pkgName)
                        text = if (isFav) "★" else "☆"
                        textSize = 16f
                        setTextColor(if (isFav) Color.parseColor("#F59E0B") else Color.parseColor("#6B7280"))
                        setPadding(dpToPx(8), 0, dpToPx(4), 0)
                        setOnClickListener {
                            performHaptic()
                            if (favoritesList.contains(pkgName)) {
                                favoritesList.remove(pkgName)
                            } else {
                                favoritesList.add(pkgName)
                            }
                            prefs.edit().putString("favorites", favoritesList.joinToString(",")).apply()
                            populateList(searchBox.text.toString())
                        }
                    }
                    addView(icon)
                    addView(label)
                    addView(favIndicator)
                    setOnClickListener {
                        performHaptic()
                        dismissOverlayPanel()
                        appManager.launchApp(pkgName)
                    }
                }
                appListContainer.addView(row)
            }
        }

        populateList()
        searchBox.addTextChangedListener(object : TextWatcher {
            override fun afterTextChanged(s: Editable?) {
                populateList(s?.toString() ?: "")
            }
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
        })

        appScroll.addView(appListContainer)
        card.addView(appScroll)
    }

    private fun renderToolsTab(card: LinearLayout) {
        val scroll = ScrollView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            isFillViewport = true
        }
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        val row1 = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        row1.addView(createActionButton("calculator", "Calculator", buttonColor) {
            activeOverlayTool = "calculator"
            rebuildPanelCard()
        })
        row1.addView(createActionButton("stopwatch", "Stopwatch", Color.parseColor("#10B981")) {
            activeOverlayTool = "stopwatch"
            rebuildPanelCard()
        })
        row1.addView(createActionButton("timer", "Timer", Color.parseColor("#F59E0B")) {
            activeOverlayTool = "timer"
            rebuildPanelCard()
        })
        row1.addView(createActionButton("notes", "Notes", Color.parseColor("#8B5CF6")) {
            activeOverlayTool = "notes"
            rebuildPanelCard()
        })
        container.addView(row1)

        val row2 = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dpToPx(8)
            }
        }
        row2.addView(createActionButton("device_info", "Device Info", Color.parseColor("#06B6D4")) {
            activeOverlayTool = "device_info"
            rebuildPanelCard()
        })
        row2.addView(createActionButton("flashlight", "Flashlight", Color.parseColor("#F59E0B")) {
            SystemController(this).toggleFlashlight()
        })
        row2.addView(createActionButton("magnifier", "Magnifier", Color.parseColor("#3B82F6")) {
            dismissOverlayPanel()
            openTaplyApp("/screen-magnifier")
        })
        row2.addView(createActionButton("compass", "Compass", Color.parseColor("#EC4899")) {
            dismissOverlayPanel()
            openTaplyApp("/compass")
        })
        container.addView(row2)

        val row3 = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dpToPx(8)
            }
        }
        row3.addView(createActionButton("battery", "Battery", Color.parseColor("#10B981")) {
            dismissOverlayPanel()
            openTaplyApp("/battery-diagnostics")
        })
        row3.addView(createActionButton("storage", "Storage", Color.parseColor("#F59E0B")) {
            dismissOverlayPanel()
            openTaplyApp("/storage-analyzer")
        })
        row3.addView(createActionButton("customize", "Customize", Color.parseColor("#8B5CF6")) {
            dismissOverlayPanel()
            openTaplyApp("/customize")
        })
        row3.addView(createActionButton("taply", "Taply App", buttonColor) {
            dismissOverlayPanel()
            openTaplyApp("/home")
        })
        container.addView(row3)

        scroll.addView(container)
        card.addView(scroll)
    }

    private fun renderControlsTab(card: LinearLayout) {
        val sys = SystemController(this)
        val volLevels = sys.getVolumeLevels()
        val curMedia = (volLevels["mediaVolume"] as? Double ?: 0.5) * 100
        val curRing = (volLevels["ringVolume"] as? Double ?: 0.5) * 100
        val curBri = sys.getBrightness() * 100

        card.addView(createSliderRow("Media Volume", curMedia.toInt(), 100) { progress ->
            sys.setVolumeLevel("media", progress / 100.0)
        })
        card.addView(createSliderRow("Ring Volume", curRing.toInt(), 100) { progress ->
            sys.setVolumeLevel("ring", progress / 100.0)
        })
        card.addView(createSliderRow("Brightness", curBri.toInt(), 100) { progress ->
            sys.setBrightness(progress / 100.0)
        })

        val soundRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dpToPx(8)
            }
        }
        soundRow.addView(createPillButton("Silent") {
            sys.setSoundMode("silent")
        })
        soundRow.addView(createPillButton("Vibrate") {
            sys.setSoundMode("vibrate")
        })
        soundRow.addView(createPillButton("Normal") {
            sys.setSoundMode("normal")
        })
        card.addView(soundRow)
    }

    // ==========================================
    // IN-OVERLAY TOOLS
    // ==========================================

    private fun renderCalculatorTool(card: LinearLayout) {
        var currentInput = "0"
        var firstOperand = 0.0
        var pendingOp = ""
        var isNewInput = true

        val display = TextView(this).apply {
            text = currentInput
            textSize = 28f
            setTextColor(Color.WHITE)
            gravity = Gravity.END
            typeface = Typeface.MONOSPACE
            setPadding(dpToPx(8), dpToPx(8), dpToPx(8), dpToPx(8))
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(10).toFloat()
                setColor(Color.parseColor("#1F2937"))
            }
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(10)
            }
        }
        card.addView(display)

        val buttons = listOf(
            listOf("C", "±", "%", "÷"),
            listOf("7", "8", "9", "×"),
            listOf("4", "5", "6", "-"),
            listOf("1", "2", "3", "+"),
            listOf("0", ".", "=", "")
        )

        for (row in buttons) {
            val rowLayout = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    bottomMargin = dpToPx(4)
                }
            }

            for (btnText in row) {
                if (btnText.isEmpty()) continue
                val btn = TextView(this).apply {
                    text = btnText
                    textSize = 18f
                    setTextColor(Color.WHITE)
                    gravity = Gravity.CENTER
                    val isOp = btnText in listOf("÷", "×", "-", "+", "=")
                    background = GradientDrawable().apply {
                        shape = GradientDrawable.RECTANGLE
                        cornerRadius = dpToPx(8).toFloat()
                        setColor(if (isOp) buttonColor else Color.parseColor("#374151"))
                    }
                    val weight = if (btnText == "0") 2f else 1f
                    layoutParams = LinearLayout.LayoutParams(0, dpToPx(42), weight).apply {
                        setMargins(dpToPx(2), 0, dpToPx(2), 0)
                    }
                    setOnClickListener {
                        performHaptic()
                        when (btnText) {
                            "C" -> {
                                currentInput = "0"
                                firstOperand = 0.0
                                pendingOp = ""
                                isNewInput = true
                            }
                            "±" -> {
                                val v = currentInput.toDoubleOrNull() ?: 0.0
                                currentInput = if (v % 1.0 == 0.0) (-v.toInt()).toString() else (-v).toString()
                            }
                            "%" -> {
                                val v = (currentInput.toDoubleOrNull() ?: 0.0) / 100.0
                                currentInput = v.toString()
                            }
                            "+", "-", "×", "÷" -> {
                                firstOperand = currentInput.toDoubleOrNull() ?: 0.0
                                pendingOp = btnText
                                isNewInput = true
                            }
                            "=" -> {
                                val secondOperand = currentInput.toDoubleOrNull() ?: 0.0
                                val result = when (pendingOp) {
                                    "+" -> firstOperand + secondOperand
                                    "-" -> firstOperand - secondOperand
                                    "×" -> firstOperand * secondOperand
                                    "÷" -> if (secondOperand != 0.0) firstOperand / secondOperand else 0.0
                                    else -> secondOperand
                                }
                                currentInput = if (result % 1.0 == 0.0) result.toInt().toString() else "%.4f".format(result).trimEnd('0').trimEnd('.')
                                pendingOp = ""
                                isNewInput = true
                            }
                            else -> {
                                if (isNewInput) {
                                    currentInput = if (btnText == ".") "0." else btnText
                                    isNewInput = false
                                } else {
                                    if (btnText == "." && currentInput.contains(".")) {
                                        // Ignore multiple dots
                                    } else {
                                        currentInput += btnText
                                    }
                                }
                            }
                        }
                        display.text = currentInput
                    }
                }
                rowLayout.addView(btn)
            }
            card.addView(rowLayout)
        }
    }

    private fun renderStopwatchTool(card: LinearLayout) {
        val display = TextView(this).apply {
            text = "00:00.0"
            textSize = 34f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            typeface = Typeface.MONOSPACE
            setPadding(0, dpToPx(16), 0, dpToPx(16))
        }
        stopwatchTextView = display
        card.addView(display)

        val btnRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dpToPx(8)
            }
        }

        val startBtn = TextView(this).apply {
            text = if (stopwatchRunning) "Pause" else "Start"
            textSize = 14f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(12).toFloat()
                setColor(if (stopwatchRunning) Color.parseColor("#EF4444") else Color.parseColor("#10B981"))
            }
            layoutParams = LinearLayout.LayoutParams(0, dpToPx(42), 1f).apply {
                rightMargin = dpToPx(4)
            }
            setOnClickListener {
                performHaptic()
                if (stopwatchRunning) {
                    stopwatchRunning = false
                    stopwatchElapsedTime += SystemClock.elapsedRealtime() - stopwatchStartTime
                    stopwatchRunnable?.let { stopwatchHandler.removeCallbacks(it) }
                    text = "Resume"
                    (background as? GradientDrawable)?.setColor(Color.parseColor("#10B981"))
                } else {
                    stopwatchRunning = true
                    stopwatchStartTime = SystemClock.elapsedRealtime()
                    text = "Pause"
                    (background as? GradientDrawable)?.setColor(Color.parseColor("#EF4444"))

                    stopwatchRunnable = object : Runnable {
                        override fun run() {
                            if (stopwatchRunning) {
                                val total = stopwatchElapsedTime + (SystemClock.elapsedRealtime() - stopwatchStartTime)
                                val mins = (total / 60000)
                                val secs = (total % 60000) / 1000
                                val tenths = (total % 1000) / 100
                                stopwatchTextView?.text = "%02d:%02d.%01d".format(mins, secs, tenths)
                                stopwatchHandler.postDelayed(this, 100)
                            }
                        }
                    }
                    stopwatchHandler.post(stopwatchRunnable!!)
                }
            }
        }

        val resetBtn = TextView(this).apply {
            text = "Reset"
            textSize = 14f
            setTextColor(Color.parseColor("#9CA3AF"))
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(12).toFloat()
                setColor(Color.parseColor("#1F2937"))
            }
            layoutParams = LinearLayout.LayoutParams(0, dpToPx(42), 1f).apply {
                leftMargin = dpToPx(4)
            }
            setOnClickListener {
                performHaptic()
                stopwatchRunning = false
                stopwatchRunnable?.let { stopwatchHandler.removeCallbacks(it) }
                stopwatchElapsedTime = 0L
                stopwatchTextView?.text = "00:00.0"
                startBtn.text = "Start"
                (startBtn.background as? GradientDrawable)?.setColor(Color.parseColor("#10B981"))
            }
        }

        btnRow.addView(startBtn)
        btnRow.addView(resetBtn)
        card.addView(btnRow)
    }

    private fun renderTimerTool(card: LinearLayout) {
        val display = TextView(this).apply {
            val mins = timerRemainingSeconds / 60
            val secs = timerRemainingSeconds % 60
            text = "%02d:%02d".format(mins, secs)
            textSize = 34f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            typeface = Typeface.MONOSPACE
            setPadding(0, dpToPx(12), 0, dpToPx(12))
        }
        timerTextView = display
        card.addView(display)

        // Presets row
        val presetRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(8)
            }
        }
        for (mins in listOf(1, 5, 10, 15)) {
            val pBtn = TextView(this).apply {
                text = "${mins}m"
                textSize = 12f
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                background = GradientDrawable().apply {
                    shape = GradientDrawable.RECTANGLE
                    cornerRadius = dpToPx(10).toFloat()
                    setColor(Color.parseColor("#1F2937"))
                }
                layoutParams = LinearLayout.LayoutParams(0, dpToPx(34), 1f).apply {
                    setMargins(dpToPx(2), 0, dpToPx(2), 0)
                }
                setOnClickListener {
                    performHaptic()
                    timerRunning = false
                    timerRunnable?.let { timerHandler.removeCallbacks(it) }
                    timerTotalSeconds = mins * 60
                    timerRemainingSeconds = timerTotalSeconds
                    timerTextView?.text = "%02d:00".format(mins)
                }
            }
            presetRow.addView(pBtn)
        }
        card.addView(presetRow)

        // Start / Reset row
        val btnRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
        }
        val startBtn = TextView(this).apply {
            text = if (timerRunning) "Pause" else "Start"
            textSize = 14f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(12).toFloat()
                setColor(if (timerRunning) Color.parseColor("#EF4444") else Color.parseColor("#F59E0B"))
            }
            layoutParams = LinearLayout.LayoutParams(0, dpToPx(42), 1f).apply {
                rightMargin = dpToPx(4)
            }
            setOnClickListener {
                performHaptic()
                if (timerRunning) {
                    timerRunning = false
                    timerRunnable?.let { timerHandler.removeCallbacks(it) }
                    text = "Resume"
                    (background as? GradientDrawable)?.setColor(Color.parseColor("#F59E0B"))
                } else {
                    timerRunning = true
                    text = "Pause"
                    (background as? GradientDrawable)?.setColor(Color.parseColor("#EF4444"))

                    timerRunnable = object : Runnable {
                        override fun run() {
                            if (timerRunning && timerRemainingSeconds > 0) {
                                timerRemainingSeconds--
                                val m = timerRemainingSeconds / 60
                                val s = timerRemainingSeconds % 60
                                timerTextView?.text = "%02d:%02d".format(m, s)
                                timerHandler.postDelayed(this, 1000)
                            } else if (timerRemainingSeconds <= 0) {
                                timerRunning = false
                                text = "Start"
                                (background as? GradientDrawable)?.setColor(Color.parseColor("#F59E0B"))
                                performHaptic()
                            }
                        }
                    }
                    timerHandler.post(timerRunnable!!)
                }
            }
        }

        val resetBtn = TextView(this).apply {
            text = "Reset"
            textSize = 14f
            setTextColor(Color.parseColor("#9CA3AF"))
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(12).toFloat()
                setColor(Color.parseColor("#1F2937"))
            }
            layoutParams = LinearLayout.LayoutParams(0, dpToPx(42), 1f).apply {
                leftMargin = dpToPx(4)
            }
            setOnClickListener {
                performHaptic()
                timerRunning = false
                timerRunnable?.let { timerHandler.removeCallbacks(it) }
                timerRemainingSeconds = timerTotalSeconds
                val m = timerRemainingSeconds / 60
                val s = timerRemainingSeconds % 60
                timerTextView?.text = "%02d:%02d".format(m, s)
                startBtn.text = "Start"
                (startBtn.background as? GradientDrawable)?.setColor(Color.parseColor("#F59E0B"))
            }
        }
        btnRow.addView(startBtn)
        btnRow.addView(resetBtn)
        card.addView(btnRow)
    }

    private fun renderNotesTool(card: LinearLayout) {
        val notesEdit = EditText(this).apply {
            hint = "Quick scratchpad note..."
            setHintTextColor(Color.parseColor("#6B7280"))
            setTextColor(Color.WHITE)
            textSize = 13f
            val savedNote = prefs.getString("overlay_quick_notes", "")
            setText(savedNote)
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(10).toFloat()
                setColor(Color.parseColor("#1F2937"))
            }
            setPadding(dpToPx(12), dpToPx(12), dpToPx(12), dpToPx(12))
            minLines = 5
            maxLines = 8
            gravity = Gravity.TOP or Gravity.START
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(10)
            }
            addTextChangedListener(object : TextWatcher {
                override fun afterTextChanged(s: Editable?) {
                    prefs.edit().putString("overlay_quick_notes", s?.toString() ?: "").apply()
                }
                override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
                override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            })
        }
        card.addView(notesEdit)

        val clearBtn = TextView(this).apply {
            text = "Clear Note"
            textSize = 12f
            setTextColor(Color.parseColor("#EF4444"))
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(6), 0, dpToPx(6))
            setOnClickListener {
                performHaptic()
                notesEdit.setText("")
                prefs.edit().remove("overlay_quick_notes").apply()
            }
        }
        card.addView(clearBtn)
    }

    private fun renderDeviceInfoTool(card: LinearLayout) {
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, dpToPx(4), 0, dpToPx(4))
        }

        fun addRow(label: String, value: String) {
            val row = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                setPadding(0, dpToPx(3), 0, dpToPx(3))
                val l = TextView(context).apply {
                    text = label
                    textSize = 12f
                    setTextColor(Color.parseColor("#9CA3AF"))
                    layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                }
                val v = TextView(context).apply {
                    text = value
                    textSize = 12f
                    setTextColor(Color.WHITE)
                    typeface = Typeface.DEFAULT_BOLD
                }
                addView(l)
                addView(v)
            }
            container.addView(row)
        }

        // Battery
        val bm = getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        val level = bm?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1
        val isCharging = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            bm?.isCharging == true
        } else false
        addRow("Battery", if (level >= 0) "$level% ${if (isCharging) "(Charging)" else ""}" else "Unavailable")

        // RAM
        val am = getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
        val mi = ActivityManager.MemoryInfo()
        am?.getMemoryInfo(mi)
        val availMb = mi.availMem / (1024 * 1024)
        val totalMb = mi.totalMem / (1024 * 1024)
        addRow("Memory", "$availMb MB free / $totalMb MB")

        // Display
        addRow("Screen", "${getScreenWidth()} × ${getScreenHeight()} px")

        // OS
        addRow("Android", "API ${Build.VERSION.SDK_INT} (${Build.VERSION.RELEASE})")
        addRow("Device", "${Build.MANUFACTURER} ${Build.MODEL}")

        card.addView(container)
    }

    // ==========================================
    // OTHER PANEL STYLES (Grid, Wheel, List)
    // ==========================================

    private fun renderGrid3x3(card: LinearLayout) {
        val actions = actionOrder.take(9)
        for (rowIndex in 0 until 3) {
            val row = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    if (rowIndex > 0) topMargin = dpToPx(8)
                }
            }
            for (colIndex in 0 until 3) {
                val idx = rowIndex * 3 + colIndex
                if (idx < actions.size) {
                    row.addView(buildActionTile(actions[idx]))
                }
            }
            card.addView(row)
        }
        card.addView(createDivider())
        card.addView(createFooterPills())
    }

    private fun renderGrid4x2(card: LinearLayout) {
        val actions = actionOrder.take(8)
        for (rowIndex in 0 until 2) {
            val row = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    if (rowIndex > 0) topMargin = dpToPx(8)
                }
            }
            for (colIndex in 0 until 4) {
                val idx = rowIndex * 4 + colIndex
                if (idx < actions.size) {
                    row.addView(buildActionTile(actions[idx]))
                }
            }
            card.addView(row)
        }
        card.addView(createDivider())
        card.addView(createFooterPills())
    }

    private fun renderCompactWheel(card: LinearLayout) {
        val wheelContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(8), 0, dpToPx(8))
        }

        val row1 = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        row1.addView(buildActionTile(actionOrder.getOrElse(0) { "back" }))
        row1.addView(buildActionTile(actionOrder.getOrElse(1) { "home" }))
        row1.addView(buildActionTile(actionOrder.getOrElse(2) { "recents" }))
        wheelContainer.addView(row1)

        val row2 = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dpToPx(8)
            }
        }
        row2.addView(buildActionTile(actionOrder.getOrElse(3) { "screenshot" }))
        row2.addView(createActionButton("taply", "Taply", buttonColor) {
            dismissOverlayPanel()
            openTaplyApp("/home")
        })
        row2.addView(buildActionTile(actionOrder.getOrElse(4) { "lockScreen" }))
        wheelContainer.addView(row2)

        val row3 = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dpToPx(8)
            }
        }
        row3.addView(buildActionTile(actionOrder.getOrElse(5) { "volume" }))
        row3.addView(buildActionTile(actionOrder.getOrElse(6) { "flashlight" }))
        row3.addView(buildActionTile(actionOrder.getOrElse(7) { "settings" }))
        wheelContainer.addView(row3)

        card.addView(wheelContainer)
        card.addView(createDivider())
        card.addView(createFooterPills())
    }

    private fun renderVerticalList(card: LinearLayout) {
        val scroll = ScrollView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(220)
            )
        }
        val list = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }
        for (act in actionOrder.take(8)) {
            val tile = buildActionTile(act).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    bottomMargin = dpToPx(4)
                }
            }
            list.addView(tile)
        }
        scroll.addView(list)
        card.addView(scroll)
        card.addView(createDivider())
        card.addView(createFooterPills())
    }

    private fun createFooterPills(): View {
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
        return footerRow
    }

    private fun createSliderRow(label: String, currentVal: Int, maxVal: Int, onProgress: (Int) -> Unit): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, dpToPx(4), 0, dpToPx(4))
        }
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            val l = TextView(context).apply {
                text = label
                textSize = 12f
                setTextColor(Color.WHITE)
                typeface = Typeface.DEFAULT_BOLD
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            }
            val v = TextView(context).apply {
                text = "$currentVal%"
                textSize = 11f
                setTextColor(buttonColor)
            }
            addView(l)
            addView(v)
        }
        row.addView(header)

        val seek = SeekBar(this).apply {
            max = maxVal
            progress = currentVal
            setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                    if (fromUser) {
                        (header.getChildAt(1) as? TextView)?.text = "$progress%"
                        onProgress(progress)
                    }
                }
                override fun onStartTrackingTouch(seekBar: SeekBar?) {}
                override fun onStopTrackingTouch(seekBar: SeekBar?) {}
            })
        }
        row.addView(seek)
        return row
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

            val badge = ImageView(context).apply {
                val badgeSize = dpToPx(42)
                layoutParams = LinearLayout.LayoutParams(badgeSize, badgeSize).apply {
                    gravity = Gravity.CENTER_HORIZONTAL
                }
                setPadding(dpToPx(10), dpToPx(10), dpToPx(10), dpToPx(10))
                setImageDrawable(ActionIconDrawable(icon, accentColor, dpToPx(22)))
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
                setMargins(0, dpToPx(10), 0, dpToPx(10))
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
        } catch (e: Exception) {}
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
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    // Custom floating button rendering
    inner class FloatingButtonView(context: Context) : View(context) {
        private val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = buttonColor
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
            bgPaint.color = buttonColor
            val w = width.toFloat()
            val h = height.toFloat()
            val cx = w / 2f
            val cy = h / 2f
            val radius = (w.coerceAtMost(h) / 2f) - 6f

            when (iconStyle.lowercase()) {
                "minimal" -> {
                    canvas.drawCircle(cx, cy, radius, bgPaint)
                    canvas.drawCircle(cx, cy, radius * 0.32f, innerPaint)
                }
                "circle" -> {
                    canvas.drawCircle(cx, cy, radius, bgPaint)
                    canvas.drawCircle(cx, cy, radius, borderPaint)
                    innerPaint.style = Paint.Style.STROKE
                    innerPaint.strokeWidth = 4f
                    canvas.drawCircle(cx, cy, radius * 0.5f, innerPaint)
                    innerPaint.style = Paint.Style.FILL
                }
                "gesture" -> {
                    canvas.drawCircle(cx, cy, radius, bgPaint)
                    canvas.drawCircle(cx, cy, radius, borderPaint)
                    innerPaint.style = Paint.Style.STROKE
                    innerPaint.strokeWidth = 3f
                    canvas.drawCircle(cx, cy, radius * 0.45f, innerPaint)
                    // Reticle lines
                    canvas.drawLine(cx - radius * 0.65f, cy, cx + radius * 0.65f, cy, innerPaint)
                    canvas.drawLine(cx, cy - radius * 0.65f, cx, cy + radius * 0.65f, innerPaint)
                    innerPaint.style = Paint.Style.FILL
                }
                "assistive" -> {
                    canvas.drawCircle(cx, cy, radius, bgPaint)
                    canvas.drawCircle(cx, cy, radius, borderPaint)
                    innerPaint.style = Paint.Style.STROKE
                    innerPaint.strokeWidth = 3.5f
                    canvas.drawCircle(cx, cy, radius * 0.55f, innerPaint)
                    innerPaint.style = Paint.Style.FILL
                    canvas.drawCircle(cx, cy, radius * 0.28f, innerPaint)
                }
                else -> {
                    // Default concentric Assistive Rings
                    canvas.drawCircle(cx, cy, radius, bgPaint)
                    canvas.drawCircle(cx, cy, radius, borderPaint)
                    innerPaint.style = Paint.Style.STROKE
                    innerPaint.strokeWidth = 3f
                    canvas.drawCircle(cx, cy, radius * 0.55f, innerPaint)
                    innerPaint.style = Paint.Style.FILL
                    canvas.drawCircle(cx, cy, radius * 0.26f, innerPaint)
                }
            }
        }
    }

    // Clean vector icon renderer replacing emojis
    class ActionIconDrawable(
        private val iconKey: String,
        private val color: Int,
        private val sizePx: Int = 48
    ) : Drawable() {

        private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = this@ActionIconDrawable.color
            style = Paint.Style.STROKE
            strokeWidth = 3f
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
        }

        private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = this@ActionIconDrawable.color
            style = Paint.Style.FILL
        }

        override fun draw(canvas: Canvas) {
            val b = bounds
            val cx = b.exactCenterX()
            val cy = b.exactCenterY()
            val w = if (b.width() > 0) b.width().toFloat() else sizePx.toFloat()
            val h = if (b.height() > 0) b.height().toFloat() else sizePx.toFloat()
            val r = (minOf(w, h) / 2f) * 0.75f
            strokePaint.strokeWidth = maxOf(2.5f, r * 0.14f)

            when (iconKey.lowercase()) {
                "back", "◀" -> {
                    val p = Path().apply {
                        moveTo(cx + r * 0.6f, cy)
                        lineTo(cx - r * 0.6f, cy)
                        moveTo(cx - r * 0.1f, cy - r * 0.5f)
                        lineTo(cx - r * 0.6f, cy)
                        lineTo(cx - r * 0.1f, cy + r * 0.5f)
                    }
                    canvas.drawPath(p, strokePaint)
                }
                "home", "⌂" -> {
                    val roof = Path().apply {
                        moveTo(cx, cy - r * 0.75f)
                        lineTo(cx - r * 0.8f, cy - r * 0.05f)
                        lineTo(cx + r * 0.8f, cy - r * 0.05f)
                        close()
                    }
                    canvas.drawPath(roof, fillPaint)
                    val base = RectF(cx - r * 0.55f, cy - r * 0.05f, cx + r * 0.55f, cy + r * 0.75f)
                    canvas.drawRoundRect(base, 2f, 2f, fillPaint)
                    fillPaint.color = Color.parseColor("#111827")
                    canvas.drawRect(cx - r * 0.2f, cy + r * 0.25f, cx + r * 0.2f, cy + r * 0.75f, fillPaint)
                    fillPaint.color = color
                }
                "recents", "▢" -> {
                    val rect = RectF(cx - r * 0.6f, cy - r * 0.6f, cx + r * 0.6f, cy + r * 0.6f)
                    canvas.drawRoundRect(rect, r * 0.15f, r * 0.15f, strokePaint)
                }
                "screenshot", "⚲" -> {
                    val cam = RectF(cx - r * 0.75f, cy - r * 0.45f, cx + r * 0.75f, cy + r * 0.65f)
                    canvas.drawRoundRect(cam, r * 0.15f, r * 0.15f, strokePaint)
                    canvas.drawCircle(cx, cy + r * 0.1f, r * 0.28f, strokePaint)
                    val topBump = RectF(cx - r * 0.35f, cy - r * 0.7f, cx - r * 0.05f, cy - r * 0.45f)
                    canvas.drawRoundRect(topBump, 2f, 2f, fillPaint)
                }
                "lockscreen", "lock_screen", "lock", "🔒" -> {
                    val body = RectF(cx - r * 0.55f, cy - r * 0.15f, cx + r * 0.55f, cy + r * 0.7f)
                    canvas.drawRoundRect(body, r * 0.15f, r * 0.15f, fillPaint)
                    val shackle = RectF(cx - r * 0.35f, cy - r * 0.65f, cx + r * 0.35f, cy + r * 0.05f)
                    canvas.drawArc(shackle, 180f, 180f, false, strokePaint)
                    fillPaint.color = Color.parseColor("#111827")
                    canvas.drawCircle(cx, cy + r * 0.15f, r * 0.12f, fillPaint)
                    canvas.drawRect(cx - r * 0.05f, cy + r * 0.15f, cx + r * 0.05f, cy + r * 0.45f, fillPaint)
                    fillPaint.color = color
                }
                "volume", "🔊" -> {
                    val cone = Path().apply {
                        moveTo(cx - r * 0.6f, cy - r * 0.25f)
                        lineTo(cx - r * 0.3f, cy - r * 0.25f)
                        lineTo(cx + r * 0.05f, cy - r * 0.6f)
                        lineTo(cx + r * 0.05f, cy + r * 0.6f)
                        lineTo(cx - r * 0.3f, cy + r * 0.25f)
                        lineTo(cx - r * 0.6f, cy + r * 0.25f)
                        close()
                    }
                    canvas.drawPath(cone, fillPaint)
                    val wave1 = RectF(cx - r * 0.25f, cy - r * 0.4f, cx + r * 0.45f, cy + r * 0.4f)
                    canvas.drawArc(wave1, -45f, 90f, false, strokePaint)
                    val wave2 = RectF(cx - r * 0.45f, cy - r * 0.7f, cx + r * 0.75f, cy + r * 0.7f)
                    canvas.drawArc(wave2, -45f, 90f, false, strokePaint)
                }
                "flashlight", "🔦" -> {
                    val body = RectF(cx - r * 0.25f, cy - r * 0.1f, cx + r * 0.25f, cy + r * 0.75f)
                    canvas.drawRoundRect(body, 3f, 3f, fillPaint)
                    val head = Path().apply {
                        moveTo(cx - r * 0.45f, cy - r * 0.5f)
                        lineTo(cx + r * 0.45f, cy - r * 0.5f)
                        lineTo(cx + r * 0.25f, cy - r * 0.1f)
                        lineTo(cx - r * 0.25f, cy - r * 0.1f)
                        close()
                    }
                    canvas.drawPath(head, fillPaint)
                    canvas.drawLine(cx, cy - r * 0.8f, cx, cy - r * 0.6f, strokePaint)
                    canvas.drawLine(cx - r * 0.5f, cy - r * 0.75f, cx - r * 0.35f, cy - r * 0.58f, strokePaint)
                    canvas.drawLine(cx + r * 0.5f, cy - r * 0.75f, cx + r * 0.35f, cy - r * 0.58f, strokePaint)
                }
                "settings", "quicksettings", "quick_settings", "⚙" -> {
                    canvas.drawCircle(cx, cy, r * 0.45f, strokePaint)
                    canvas.drawCircle(cx, cy, r * 0.18f, fillPaint)
                    for (i in 0 until 6) {
                        val angle = (i * 60.0) * Math.PI / 180.0
                        val x1 = cx + (r * 0.42f * Math.cos(angle)).toFloat()
                        val y1 = cy + (r * 0.42f * Math.sin(angle)).toFloat()
                        val x2 = cx + (r * 0.72f * Math.cos(angle)).toFloat()
                        val y2 = cy + (r * 0.72f * Math.sin(angle)).toFloat()
                        canvas.drawLine(x1, y1, x2, y2, strokePaint)
                    }
                }
                "notifications", "notifs", "🔔" -> {
                    val bell = Path().apply {
                        moveTo(cx, cy - r * 0.7f)
                        cubicTo(cx + r * 0.5f, cy - r * 0.7f, cx + r * 0.6f, cy + r * 0.2f, cx + r * 0.7f, cy + r * 0.45f)
                        lineTo(cx - r * 0.7f, cy + r * 0.45f)
                        cubicTo(cx - r * 0.6f, cy + r * 0.2f, cx - r * 0.5f, cy - r * 0.7f, cx, cy - r * 0.7f)
                        close()
                    }
                    canvas.drawPath(bell, fillPaint)
                    canvas.drawCircle(cx, cy + r * 0.6f, r * 0.15f, fillPaint)
                }
                "calculator", "calc", "🖩" -> {
                    val body = RectF(cx - r * 0.6f, cy - r * 0.75f, cx + r * 0.6f, cy + r * 0.75f)
                    canvas.drawRoundRect(body, r * 0.15f, r * 0.15f, strokePaint)
                    canvas.drawLine(cx - r * 0.45f, cy - r * 0.45f, cx + r * 0.45f, cy - r * 0.45f, strokePaint)
                    val rad = r * 0.08f
                    canvas.drawCircle(cx - r * 0.3f, cy - r * 0.1f, rad, fillPaint)
                    canvas.drawCircle(cx + r * 0.3f, cy - r * 0.1f, rad, fillPaint)
                    canvas.drawCircle(cx - r * 0.3f, cy + r * 0.2f, rad, fillPaint)
                    canvas.drawCircle(cx + r * 0.3f, cy + r * 0.2f, rad, fillPaint)
                    canvas.drawCircle(cx - r * 0.3f, cy + r * 0.5f, rad, fillPaint)
                    canvas.drawCircle(cx + r * 0.3f, cy + r * 0.5f, rad, fillPaint)
                }
                "timer", "⏳" -> {
                    val circle = RectF(cx - r * 0.6f, cy - r * 0.6f, cx + r * 0.6f, cy + r * 0.6f)
                    canvas.drawArc(circle, 0f, 360f, false, strokePaint)
                    canvas.drawLine(cx, cy - r * 0.8f, cx, cy - r * 0.6f, strokePaint)
                    canvas.drawLine(cx, cy, cx, cy - r * 0.35f, strokePaint)
                    canvas.drawLine(cx, cy, cx + r * 0.25f, cy, strokePaint)
                }
                "stopwatch", "⏱" -> {
                    val dial = RectF(cx - r * 0.6f, cy - r * 0.55f, cx + r * 0.6f, cy + r * 0.65f)
                    canvas.drawArc(dial, 0f, 360f, false, strokePaint)
                    canvas.drawLine(cx, cy - r * 0.78f, cx, cy - r * 0.55f, strokePaint)
                    canvas.drawLine(cx - r * 0.2f, cy - r * 0.78f, cx + r * 0.2f, cy - r * 0.78f, strokePaint)
                    canvas.drawLine(cx, cy + r * 0.05f, cx + r * 0.28f, cy - r * 0.25f, strokePaint)
                }
                "notes", "📝" -> {
                    val sheet = Path().apply {
                        moveTo(cx - r * 0.55f, cy - r * 0.7f)
                        lineTo(cx + r * 0.25f, cy - r * 0.7f)
                        lineTo(cx + r * 0.55f, cy - r * 0.4f)
                        lineTo(cx + r * 0.55f, cy + r * 0.7f)
                        lineTo(cx - r * 0.55f, cy + r * 0.7f)
                        close()
                    }
                    canvas.drawPath(sheet, strokePaint)
                    canvas.drawLine(cx - r * 0.35f, cy - r * 0.15f, cx + r * 0.35f, cy - r * 0.15f, strokePaint)
                    canvas.drawLine(cx - r * 0.35f, cy + r * 0.15f, cx + r * 0.35f, cy + r * 0.15f, strokePaint)
                    canvas.drawLine(cx - r * 0.35f, cy + r * 0.45f, cx + r * 0.15f, cy + r * 0.45f, strokePaint)
                }
                "deviceinfo", "device_info", "📊" -> {
                    val phone = RectF(cx - r * 0.45f, cy - r * 0.75f, cx + r * 0.45f, cy + r * 0.75f)
                    canvas.drawRoundRect(phone, r * 0.15f, r * 0.15f, strokePaint)
                    canvas.drawCircle(cx, cy - r * 0.55f, 2f, fillPaint)
                    canvas.drawCircle(cx, cy + r * 0.55f, 3f, fillPaint)
                }
                "magnifier", "🔍" -> {
                    canvas.drawCircle(cx - r * 0.15f, cy - r * 0.15f, r * 0.45f, strokePaint)
                    canvas.drawLine(cx + r * 0.2f, cy + r * 0.2f, cx + r * 0.7f, cy + r * 0.7f, strokePaint)
                }
                "compass", "🧭" -> {
                    canvas.drawCircle(cx, cy, r * 0.7f, strokePaint)
                    val north = Path().apply {
                        moveTo(cx, cy - r * 0.55f)
                        lineTo(cx + r * 0.2f, cy)
                        lineTo(cx, cy)
                        close()
                    }
                    canvas.drawPath(north, fillPaint)
                    val south = Path().apply {
                        moveTo(cx, cy + r * 0.55f)
                        lineTo(cx - r * 0.2f, cy)
                        lineTo(cx, cy)
                        close()
                    }
                    canvas.drawPath(south, strokePaint)
                }
                "battery", "🔋" -> {
                    val bat = RectF(cx - r * 0.7f, cy - r * 0.35f, cx + r * 0.5f, cy + r * 0.35f)
                    canvas.drawRoundRect(bat, 3f, 3f, strokePaint)
                    canvas.drawRect(cx + r * 0.5f, cy - r * 0.15f, cx + r * 0.65f, cy + r * 0.15f, fillPaint)
                    val level = RectF(cx - r * 0.55f, cy - r * 0.22f, cx + r * 0.25f, cy + r * 0.22f)
                    canvas.drawRoundRect(level, 2f, 2f, fillPaint)
                }
                "storage", "💾" -> {
                    val d1 = RectF(cx - r * 0.65f, cy - r * 0.65f, cx + r * 0.65f, cy - r * 0.1f)
                    canvas.drawRoundRect(d1, r * 0.2f, r * 0.2f, strokePaint)
                    val d2 = RectF(cx - r * 0.65f, cy + r * 0.05f, cx + r * 0.65f, cy + r * 0.6f)
                    canvas.drawRoundRect(d2, r * 0.2f, r * 0.2f, strokePaint)
                }
                "customize", "🎨" -> {
                    val palette = RectF(cx - r * 0.65f, cy - r * 0.65f, cx + r * 0.65f, cy + r * 0.65f)
                    canvas.drawRoundRect(palette, r * 0.3f, r * 0.3f, strokePaint)
                    canvas.drawCircle(cx - r * 0.25f, cy - r * 0.2f, r * 0.12f, fillPaint)
                    canvas.drawCircle(cx + r * 0.2f, cy - r * 0.2f, r * 0.12f, fillPaint)
                    canvas.drawCircle(cx, cy + r * 0.25f, r * 0.12f, fillPaint)
                }
                "taply", "✦", "star" -> {
                    val spark = Path().apply {
                        moveTo(cx, cy - r * 0.7f)
                        quadTo(cx, cy, cx + r * 0.7f, cy)
                        quadTo(cx, cy, cx, cy + r * 0.7f)
                        quadTo(cx, cy, cx - r * 0.7f, cy)
                        quadTo(cx, cy, cx, cy - r * 0.7f)
                        close()
                    }
                    canvas.drawPath(spark, fillPaint)
                }
                "close", "✕", "x" -> {
                    canvas.drawLine(cx - r * 0.5f, cy - r * 0.5f, cx + r * 0.5f, cy + r * 0.5f, strokePaint)
                    canvas.drawLine(cx + r * 0.5f, cy - r * 0.5f, cx - r * 0.5f, cy + r * 0.5f, strokePaint)
                }
                else -> {
                    canvas.drawCircle(cx, cy, r * 0.4f, fillPaint)
                }
            }
        }

        override fun setAlpha(alpha: Int) {
            strokePaint.alpha = alpha
            fillPaint.alpha = alpha
        }

        override fun setColorFilter(colorFilter: ColorFilter?) {
            strokePaint.colorFilter = colorFilter
            fillPaint.colorFilter = colorFilter
        }

        override fun getOpacity(): Int = PixelFormat.TRANSLUCENT
        override fun getIntrinsicWidth(): Int = sizePx
        override fun getIntrinsicHeight(): Int = sizePx
    }
}
