package com.example.human_safety

import android.content.Intent
import android.util.Log
import android.view.KeyEvent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private var hardwareEventSink: EventChannel.EventSink? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		EventChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			HARDWARE_CHANNEL
		).setStreamHandler(object : EventChannel.StreamHandler {
			override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
				hardwareEventSink = events
				// expose to other Android components
				HardwareEventDispatcher.sink = events
			}

			override fun onCancel(arguments: Any?) {
				hardwareEventSink = null
				HardwareEventDispatcher.sink = null
			}
		})

		// MethodChannel to allow Flutter to request bringing the app to foreground
		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"humansafety/hardware_actions"
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"bringToForeground" -> {
					try {
						val intent = intent
						intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_SINGLE_TOP or android.content.Intent.FLAG_ACTIVITY_CLEAR_TOP)
						startActivity(intent)
						result.success(true)
					} catch (t: Throwable) {
						result.error("error", t.message, null)
					}
				}
				"setSosTrigger" -> {
					// Receive SOS trigger request from native layer to set in Flutter
					result.success(true)
				}
				else -> result.notImplemented()
			}
		}

		// Check if this activity was launched with SOS trigger intent
		checkForSosTrigger()
	}

	private fun checkForSosTrigger() {
		val intent = intent
		if (intent != null && intent.getBooleanExtra("sos_trigger", false)) {
			val source = intent.getStringExtra("source") ?: "volume_down"
			intent.removeExtra("sos_trigger")
			intent.removeExtra("source")
			
			// Set the SOS trigger in Flutter controller BEFORE app renders
			try {
				val channel = MethodChannel(
					flutterEngine!!.dartExecutor.binaryMessenger,
					"humansafety/hardware_actions"
				)
				channel.invokeMethod("setSosTrigger", mapOf("source" to source))
				Log.d("MainActivity", "✓ Set SOS trigger in Flutter: $source")
			} catch (e: Exception) {
				Log.e("MainActivity", "❌ Failed to set SOS trigger: ${e.message}")
			}
		}
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		setIntent(intent)
		checkForSosTrigger()
	}

	override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
		when (keyCode) {
			KeyEvent.KEYCODE_VOLUME_DOWN -> {
				HardwareEventDispatcher.send(
					mapOf(
						"key" to "volume_down",
						"action" to "down",
						"timestamp" to System.currentTimeMillis(),
					)
				)
				return true
			}

			KeyEvent.KEYCODE_VOLUME_UP -> {
				HardwareEventDispatcher.send(
					mapOf(
						"key" to "volume_up",
						"action" to "down",
						"timestamp" to System.currentTimeMillis(),
					)
				)
				return true
			}
		}

		return super.onKeyDown(keyCode, event)
	}

	companion object {
		private const val HARDWARE_CHANNEL = "humansafety/hardware_buttons"
	}
}
