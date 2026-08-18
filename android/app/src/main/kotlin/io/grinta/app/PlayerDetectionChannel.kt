package io.grinta.app

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Placeholder channel so the Dart stub can call `detectPeople` on Android.
 * Human-rectangle detection on Android is not wired yet (web + iOS first).
 */
object PlayerDetectionChannel {
    const val CHANNEL_NAME = "io.grinta.app/player_detection"

    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            if (call.method == "detectPeople") {
                result.success(emptyList<Map<String, Double>>())
            } else {
                result.notImplemented()
            }
        }
    }
}
