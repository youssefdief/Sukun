package com.example.sukun_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.sukun_app/widgets"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "refreshWidgets") {
                refreshWidgets()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun refreshWidgets() {
        val intent = Intent(this, PrayerWidgetProvider::class.java)
        intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        val ids = AppWidgetManager.getInstance(application)
            .getAppWidgetIds(ComponentName(application, PrayerWidgetProvider::class.java))
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        sendBroadcast(intent)

        val intentDhikr = Intent(this, DhikrWidgetProvider::class.java)
        intentDhikr.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        val idsDhikr = AppWidgetManager.getInstance(application)
            .getAppWidgetIds(ComponentName(application, DhikrWidgetProvider::class.java))
        intentDhikr.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, idsDhikr)
        sendBroadcast(intentDhikr)
    }
}
