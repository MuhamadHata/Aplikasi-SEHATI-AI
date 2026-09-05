package com.sehati.ai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Boot Completed Receiver
 * Starts BootService after device boot if pedometer tracking was enabled.
 */
class BootCompletedReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED ||
            intent?.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent?.action == "android.intent.action.MY_PACKAGE_REPLACED") {

            context?.let { ctx ->
                Log.d(TAG, "Boot completed, starting BootService...")

                val serviceIntent = Intent(ctx, BootService::class.java)
                ctx.startForegroundService(serviceIntent)
            }
        }
    }

    companion object {
        private const val TAG = "BootCompletedReceiver"
    }
}

/**
 * Battery Optimization Receiver - monitors power state changes.
 */
class BatteryOptimizationReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_POWER_CONNECTED -> {
                Log.d(TAG, "Power connected")
            }
            Intent.ACTION_POWER_DISCONNECTED -> {
                Log.d(TAG, "Power disconnected")
            }
        }
    }

    companion object {
        private const val TAG = "BatteryOptReceiver"
    }
}
