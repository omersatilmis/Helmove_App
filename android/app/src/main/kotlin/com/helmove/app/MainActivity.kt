package com.helmove.app

import android.media.AudioManager
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var toneGenerator: ToneGenerator? = null
    private val CHANNEL = "com.motoapp/audio"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playTone" -> {
                    playTone()
                    result.success(null)
                }
                "stopTone" -> {
                    stopTone()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playTone() {
        if (toneGenerator == null) {
            // STREAM_MUSIC hoparlörden çalması için daha uygundur
            toneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 80)
        }
        toneGenerator?.startTone(ToneGenerator.TONE_SUP_RINGTONE)
    }

    private fun stopTone() {
        toneGenerator?.stopTone()
        toneGenerator?.release()
        toneGenerator = null
    }
}
