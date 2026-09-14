package com.taply.taply

import android.content.Intent
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var methodChannelHandler: TaplyMethodChannel? = null
    private var isFlutterReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        // Keep Android splash on screen until Flutter finishes rendering its first frame
        splashScreen.setKeepOnScreenCondition {
            !isFlutterReady
        }
        super.onCreate(savedInstanceState)
    }

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        // Triggered when Flutter paints its very first frame
        isFlutterReady = true
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannelHandler = TaplyMethodChannel(applicationContext).apply {
            register(flutterEngine.dartExecutor.binaryMessenger)
        }
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val route = intent?.getStringExtra("route")
        if (route != null) {
            flutterEngine?.let { engine ->
                val channel = MethodChannel(engine.dartExecutor.binaryMessenger, TaplyMethodChannel.CHANNEL_NAME)
                channel.invokeMethod("onNavigateRoute", route)
            }
        }
    }
}
