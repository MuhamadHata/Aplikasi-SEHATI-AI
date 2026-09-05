package com.sehati.ai

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Boot Service
 * Starts the background step tracking service after boot completion.
 */
class BootService : Service() {

    companion object {
        private const val TAG = "BootService"
        private const val CHANNEL_ID = "boot_service_channel"
        private const val PREFS_NAME = "flutter_settings_reader"
        private const val KEY_PEDOMETER_ENABLED = "bg_pedo_auto_start"
        private const val NOTIFICATION_ID = 9999
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Boot service started")

        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        // Check if pedometer was enabled
        val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val isEnabled = prefs.getBoolean(KEY_PEDOMETER_ENABLED, false)

        if (isEnabled) {
            Log.d(TAG, "Pedometer auto-start is enabled, launching app...")
            startMainActivity()
        } else {
            Log.d(TAG, "Pedometer auto-start is disabled")
        }

        stopSelf()
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Boot Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply { description = "Service for initializing background step tracking" }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("SEHATI-AI")
            .setContentText("Menginisialisasi layanan langkah...")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(false)
            .build()
    }

    private fun startMainActivity() {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra("from_boot", true)
        }
        startActivity(intent)
    }
}
