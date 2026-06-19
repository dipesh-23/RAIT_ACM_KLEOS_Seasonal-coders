package com.asha.triage

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.ComponentName
import android.content.Intent
import android.provider.Settings

class MainActivity : FlutterActivity() {
  private val CHANNEL = "com.asha.triage/settings"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      CHANNEL
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "openGoogleOfflineSpeech" -> {
          var opened = false

          // Intent 1 — Direct Google offline speech settings
          try {
            val intent = Intent(Intent.ACTION_MAIN)
            intent.component = ComponentName(
              "com.google.android.googlequicksearchbox",
              "com.google.android.apps.gsa.settingsui.VoiceSearchPreferences"
            )
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
            opened = true
          } catch (e: Exception) {
          }

          // Intent 2 — Google app voice settings
          if (!opened) {
            try {
              val intent = Intent("android.intent.action.VIEW")
              intent.setPackage("com.google.android.googlequicksearchbox")
              intent.putExtra("SETTINGS_TYPE", "VOICE")
              intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
              startActivity(intent)
              opened = true
            } catch (e: Exception) {
            }
          }

          // Intent 3 — Generic text to speech settings
          if (!opened) {
            try {
              val intent = Intent(Settings.ACTION_VOICE_INPUT_SETTINGS)
              intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
              startActivity(intent)
              opened = true
            } catch (e: Exception) {
            }
          }

          // Intent 4 — Final fallback, general settings
          if (!opened) {
            try {
              val intent = Intent(Settings.ACTION_SETTINGS)
              intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
              startActivity(intent)
              opened = true
            } catch (e: Exception) {
            }
          }

          if (opened) {
            result.success("opened")
          } else {
            result.success("fallback")
          }
        }
        "openSpeechSettings" -> {
          try {
            val intent = Intent(Settings.ACTION_VOICE_INPUT_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
            result.success("opened")
          } catch (e: Exception) {
            result.success("failed")
          }
        }
        else -> result.notImplemented()
      }
    }
  }
}
