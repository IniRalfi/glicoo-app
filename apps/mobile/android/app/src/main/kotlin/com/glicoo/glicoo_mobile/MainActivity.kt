package com.glicoo.glicoo_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val SCREEN_CHANNEL = "com.glicoo.glico/screen_state"
    private var screenReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    screenReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            when (intent?.action) {
                                Intent.ACTION_SCREEN_ON -> events?.success("screen_on")
                                Intent.ACTION_SCREEN_OFF -> events?.success("screen_off")
                            }
                        }
                    }

                    val filter = IntentFilter().apply {
                        addAction(Intent.ACTION_SCREEN_ON)
                        addAction(Intent.ACTION_SCREEN_OFF)
                    }
                    registerReceiver(screenReceiver, filter)
                }

                override fun onCancel(arguments: Any?) {
                    if (screenReceiver != null) {
                        try {
                            unregisterReceiver(screenReceiver)
                        } catch (e: Exception) {
                            // Already unregistered
                        }
                        screenReceiver = null
                    }
                }
            }
        )
    }
}
