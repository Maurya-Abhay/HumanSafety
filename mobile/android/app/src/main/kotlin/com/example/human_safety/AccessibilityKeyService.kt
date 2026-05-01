package com.example.human_safety

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent
import androidx.core.app.NotificationCompat

class AccessibilityKeyService : AccessibilityService() {
    companion object {
        private const val TAG = "AccessibilityKeyService"
        private const val NOTIFICATION_CHANNEL_ID = "humansafety_sos_alert"
        private const val NOTIFICATION_ID = 10001
        private const val TRIPLE_PRESS_TIMEOUT_MS = 1500L
        private const val REQUIRED_PRESSES = 3
    }

    private var lastPressTime = 0L
    private var pressCount = 0
    private val handler = Handler(Looper.getMainLooper())
    private var resetRunnable: Runnable? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "✓ AccessibilityKeyService CONNECTED")

        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPES_ALL_MASK
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS
        info.packageNames = null
        serviceInfo = info

        createNotificationChannel()
        
        // Show a debug notification to prove service is running
        showDebugNotification()
        Log.d(TAG, "✓ Service setup complete - triple-press detection active")
    }

    private fun showDebugNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("✓ HumanSafety Monitoring Active")
            .setContentText("Accessibility service is running. Ready to detect volume key triple-press.")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(false)
            .setOngoing(true)
            .build()
        manager.notify(10000, notification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "HumanSafety Emergency Alert",
                NotificationManager.IMPORTANCE_MAX
            )
            channel.description = "Urgent SOS notifications"
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // not used
    }

    override fun onInterrupt() {}

    override fun onKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN) {
            when (event.keyCode) {
                KeyEvent.KEYCODE_VOLUME_DOWN, KeyEvent.KEYCODE_VOLUME_UP -> {
                    val keyName = if (event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) "VOLUME_DOWN" else "VOLUME_UP"
                    Log.d(TAG, "🔊 Key detected: $keyName")
                    handleVolumeKeyPress(event.keyCode)
                    return true
                }
            }
        }

        return super.onKeyEvent(event)
    }

    private fun handleVolumeKeyPress(keyCode: Int) {
        val now = System.currentTimeMillis()
        val key = if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) "volume_down" else "volume_up"

        // Reset counter if too much time has passed
        if (now - lastPressTime > TRIPLE_PRESS_TIMEOUT_MS) {
            pressCount = 0
        }

        lastPressTime = now
        pressCount++

        Log.d(TAG, "🔊 $key press #$pressCount (timeout: ${TRIPLE_PRESS_TIMEOUT_MS}ms)")

        // Cancel any pending reset
        resetRunnable?.let { handler.removeCallbacks(it) }

        // If triple-press detected, trigger the SOS
        if (pressCount >= REQUIRED_PRESSES) {
            pressCount = 0
            Log.d(TAG, "🚨🚨🚨 TRIPLE-PRESS DETECTED! Triggering SOS!")
            triggerSosAlert(key)
        } else {
            // Schedule a reset if no more presses come
            resetRunnable = Runnable {
                pressCount = 0
                Log.d(TAG, "ℹ️ Press counter reset")
            }
            handler.postDelayed(resetRunnable!!, TRIPLE_PRESS_TIMEOUT_MS)
        }
    }

    private fun triggerSosAlert(source: String) {
        Log.d(TAG, "🚨 Triggering SOS alert from $source")

        // Send sos_triggered event to EventChannel so Flutter can handle it
        try {
            HardwareEventDispatcher.send(
                mapOf(
                    "key" to "sos_triggered",
                    "source" to source,
                    "action" to "trigger",
                    "timestamp" to System.currentTimeMillis()
                )
            )
            Log.d(TAG, "✓ Event sent to Flutter")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to send event: ${e.message}")
        }

        // DIRECTLY launch MainActivity with SOS trigger immediately
        launchSosScreenDirectly(source)
    }

    private fun launchSosScreenDirectly(source: String) {
        try {
            Log.d(TAG, "🚀 Launching MainActivity directly with SOS screen")
            val intent = Intent(this, MainActivity::class.java)
            intent.action = Intent.ACTION_MAIN
            intent.addCategory(Intent.CATEGORY_LAUNCHER)
            intent.putExtra("source", source)
            intent.putExtra("sos_trigger", true)
            intent.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            )
            startActivity(intent)
            Log.d(TAG, "✓ MainActivity launched directly")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to launch MainActivity: ${e.message}")
        }
    }

    private fun showHighPriorityNotification(source: String) {
        Log.d(TAG, "📲 Showing high-priority notification")
        
        val intent = Intent(this, MainActivity::class.java)
        intent.action = Intent.ACTION_MAIN
        intent.addCategory(Intent.CATEGORY_LAUNCHER)
        intent.putExtra("source", source)
        intent.putExtra("sos_trigger", true)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("🚨 EMERGENCY ALERT 🚨")
            .setContentText("SOS triggered - tap to open emergency screen")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(pendingIntent, true)
            .setAutoCancel(true)
            .setVibrate(longArrayOf(0, 500, 200, 500))
            .setSound(null) // app will handle audio
            .build()

        try {
            manager.notify(NOTIFICATION_ID, notification)
            Log.d(TAG, "✓ Notification shown successfully")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to show notification: ${e.message}")
        }
    }
}

