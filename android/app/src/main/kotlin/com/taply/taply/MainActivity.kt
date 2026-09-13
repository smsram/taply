package com.taply.taply

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var methodChannelHandler: TaplyMethodChannel? = null

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
