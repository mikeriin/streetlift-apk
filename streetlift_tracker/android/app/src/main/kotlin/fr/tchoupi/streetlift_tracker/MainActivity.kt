package fr.tchoupi.streetlift_tracker

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kalis_track/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "timeZoneName" -> result.success(TimeZone.getDefault().id)
                    "openSettings" -> {
                        val page = call.argument<String>("page")
                        val appDetails = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName"))
                        val intent = when {
                            page == "battery" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
                                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                            page == "channel" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ->
                                Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                    .putExtra(Settings.EXTRA_CHANNEL_ID, "kalis_daily")
                            page == "notifications" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ->
                                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            else -> appDetails
                        }
                        try {
                            startActivity(intent)
                            result.success(true)
                        } catch (_: ActivityNotFoundException) {
                            try {
                                startActivity(appDetails)
                                result.success(true)
                            } catch (_: Exception) { result.success(false) }
                        } catch (_: SecurityException) { result.success(false) }
                    }
                    "highRefreshRate" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            @Suppress("DEPRECATION")
                            val screen = windowManager.defaultDisplay
                            val current = screen.mode
                            val best = screen.supportedModes.filter {
                                it.physicalWidth == current.physicalWidth && it.physicalHeight == current.physicalHeight
                            }.maxByOrNull { it.refreshRate }
                            if (best != null) {
                                val params = window.attributes
                                params.preferredDisplayModeId = best.modeId
                                window.attributes = params
                            }
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
