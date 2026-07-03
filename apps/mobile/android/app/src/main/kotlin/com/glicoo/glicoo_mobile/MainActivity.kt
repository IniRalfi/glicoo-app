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

    override fun onResume() {
        super.onResume()
        val filter = IntentFilter().apply {
            addAction(android.content.Intent.ACTION_SCREEN_ON)
            addAction(android.content.Intent.ACTION_SCREEN_OFF)
        }
        registerReceiver(screenTimeReceiver, filter)

        // WHY: app resuming = screen is on; seed the timestamp so live-elapsed works
        // even if the very first SCREEN_ON broadcast was missed before receiver registered.
        ScreenTimeReceiver.handleScreenOn(this)
    }

    override fun onPause() {
        super.onPause()
        try {
            unregisterReceiver(screenTimeReceiver)
        } catch (_: IllegalArgumentException) {
            // receiver was never registered — safe to ignore
        }
    }
}
