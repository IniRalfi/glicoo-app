package com.glicoo.glicoo_mobile

import android.content.IntentFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SCREEN_TIME_CHANNEL = "com.glicoo.glico/screen_time"

    // WHY: receiver must be registered in code (not manifest) for SCREEN_ON/SCREEN_OFF —
    // those broadcasts are not delivered to manifest-declared receivers since API 26.
    private val screenTimeReceiver = ScreenTimeReceiver()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCREEN_TIME_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getScreenTimeToday" -> {
                    val seconds = ScreenTimeReceiver.getTodaySeconds(this)
                    result.success(seconds)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter().apply {
            addAction(android.content.Intent.ACTION_SCREEN_ON)
            addAction(android.content.Intent.ACTION_SCREEN_OFF)
        }
        // Use applicationContext so the receiver outlives the activity if possible
        applicationContext.registerReceiver(screenTimeReceiver, filter)
        
        ScreenTimeReceiver.handleScreenOn(this)
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            applicationContext.unregisterReceiver(screenTimeReceiver)
        } catch (_: IllegalArgumentException) {
            // safe to ignore
        }
    }
}
