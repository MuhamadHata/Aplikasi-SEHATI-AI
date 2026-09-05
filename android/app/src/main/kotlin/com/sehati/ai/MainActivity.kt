package com.sehati.ai

import android.app.AppOpsManager
import android.app.NotificationManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Process
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val CHANNEL = "com.sehati.ai/screen_time"
        private const val PREFS_NAME = "flutter_settings_reader"
        private const val KEY_PEDOMETER_ENABLED = "bg_pedo_auto_start"
        private var bootHandled = false
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleBootIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleBootIntent(intent)
    }

    private fun handleBootIntent(intent: Intent?) {
        if (!bootHandled && intent?.getBooleanExtra("from_boot", false) == true) {
            bootHandled = true
            android.util.Log.d("MainActivity", "Boot completed - pedometer auto-start is enabled")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "checkPermission" -> {
                        result.success(hasUsageStatsPermission())
                    }

                    "openPermissionSettings" -> {
                        openBestPermissionPage()
                        result.success(null)
                    }

                    "openRestrictedSettingsGuide" -> {
                        openSamsungInstallSettings()
                        result.success(null)
                    }

                    "getUsageStats" -> {
                        val daysBack = call.argument<Int>("daysBack") ?: 1
                        try {
                            val stats = getUsageStatsNative(daysBack)
                            result.success(stats)
                        } catch (e: Exception) {
                            result.error("USAGE_ERROR", e.message, null)
                        }
                    }

                    "calculateWellnessScore" -> {
                        val totalMinutes = call.argument<Int>("totalMinutes") ?: 0
                        val targetMinutes = call.argument<Int>("targetMinutes") ?: 240
                        val socialMinutes = call.argument<Int>("socialMinutes") ?: 0
                        val productiveMinutes = call.argument<Int>("productiveMinutes") ?: 0
                        val entertainmentMinutes = call.argument<Int>("entertainmentMinutes") ?: 0
                        val score = calculateWellnessScore(
                            totalMinutes, targetMinutes,
                            socialMinutes, productiveMinutes, entertainmentMinutes
                        )
                        result.success(score)
                    }

                    "isSamsungDevice" -> {
                        val isSamsung = Build.MANUFACTURER.equals("samsung", ignoreCase = true)
                        result.success(isSamsung)
                    }

                    "isRestrictedBySettings" -> {
                        result.success(isRestrictedBySamsungSettings())
                    }

                    "openSamsungDeviceCare" -> {
                        openSamsungDeviceCare()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // Permission checks
    private fun hasUsageStatsPermission(): Boolean {
        return try {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            false
        }
    }

    private fun openBestPermissionPage() {
        val directIntent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                data = Uri.parse("package:$packageName")
            }
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        try {
            startActivity(directIntent); return
        } catch (_: Exception) {}

        try {
            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            })
        } catch (_: Exception) {}
    }

    private fun openSamsungInstallSettings() {
        val intents = listOf(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
            Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                data = Uri.parse("package:packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        )

        for (intent in intents) {
            try {
                startActivity(intent); return
            } catch (_: Exception) {}
        }
    }

    private fun openSamsungDeviceCare() {
        val intents = listOf(
            Intent().apply {
                action = Intent.ACTION_MAIN
                setClassName("com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        )

        for (intent in intents) {
            try {
                startActivity(intent); return
            } catch (_: Exception) {}
        }
    }

    private fun isRestrictedBySamsungSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return false
        return try {
            val pm = packageManager
            val installSource = pm.getPackageInfo(packageName, 0).let { info ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    pm.getInstallSourceInfo(packageName).initiatingPackageName
                } else {
                    @Suppress("DEPRECATION")
                    pm.getInstallerPackageName(packageName)
                }
            }
            installSource == null || installSource == "adb" || installSource == "com.android.packageinstaller"
        } catch (e: Exception) {
            false
        }
    }

    private fun getUsageStatsNative(daysBack: Int): List<Map<String, Any>> {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val start = now - (daysBack * 24L * 60 * 60 * 1000)

        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, now)
        if (stats.isNullOrEmpty()) return emptyList()

        val aggregated = mutableMapOf<String, Long>()
        for (stat in stats) {
            val pkg = stat.packageName ?: continue
            val time = stat.totalTimeInForeground
            if (time < 60_000L) continue
            aggregated[pkg] = (aggregated[pkg] ?: 0L) + time
        }

        return aggregated.entries
            .filter { it.value >= 60_000L }
            .sortedByDescending { it.value }
            .map { entry ->
                mapOf(
                    "packageName" to entry.key,
                    "totalTimeMs" to entry.value,
                    "totalMinutes" to (entry.value / 60_000L).toInt()
                )
            }
    }

    private fun calculateWellnessScore(
        totalMinutes: Int,
        targetMinutes: Int,
        socialMinutes: Int,
        productiveMinutes: Int,
        entertainmentMinutes: Int
    ): Map<String, Any> {
        val usageRatio = if (targetMinutes > 0) totalMinutes.toDouble() / targetMinutes else 1.0
        val baseScore = when {
            usageRatio <= 0.5 -> 100.0
            usageRatio <= 0.75 -> 90.0
            usageRatio <= 1.0 -> 75.0
            usageRatio <= 1.25 -> 60.0
            usageRatio <= 1.5 -> 45.0
            else -> 15.0
        }

        val total = (socialMinutes + productiveMinutes + entertainmentMinutes).coerceAtLeast(1)
        val productiveRatio = productiveMinutes.toDouble() / total
        val entertainmentRatio = entertainmentMinutes.toDouble() / total
        val socialRatio = socialMinutes.toDouble() / total

        val compositionScore = when {
            productiveRatio >= 0.4 -> 10
            productiveRatio >= 0.2 -> 5
            else -> 0
        } + when {
            entertainmentRatio >= 0.7 -> -15
            entertainmentRatio >= 0.5 -> -8
            else -> 0
        } + when {
            socialRatio >= 0.6 -> -10
            else -> 0
        }

        val finalScore = (baseScore + compositionScore).coerceIn(0.0, 100.0).toInt()

        val (kategori, deskripsi, saran) = when {
            finalScore >= 85 -> Triple("Sangat Baik", "Penggunaan layar Anda sangat seimbang! 🌟", "Pertahankan pola ini.")
            finalScore >= 70 -> Triple("Baik", "Penggunaan layar dalam batas wajar 👍", "Tambah produktif, kurang hiburan.")
            finalScore >= 55 -> Triple("Cukup", "Penggunaan mulai mendekati batas ⚠️", "Batasi sosmed & layar setiap 45 menit.")
            finalScore >= 40 -> Triple("Perlu Perhatian", "Penggunaan cukup tinggi 😰", "Jeda layar 1 jam sebelum tidur.")
            else -> Triple("Tidak Sehat", "Penggunaan berlebihan! 🚨", "Kurangi & konsultasi profesional jika perlu.")
        }

        return mapOf(
            "score" to finalScore,
            "kategori" to kategori,
            "deskripsi" to deskripsi,
            "saran" to saran,
            "productiveRatio" to (productiveRatio * 100).toInt(),
            "entertainmentRatio" to (entertainmentRatio * 100).toInt(),
            "socialRatio" to (socialRatio * 100).toInt()
        )
    }
}
