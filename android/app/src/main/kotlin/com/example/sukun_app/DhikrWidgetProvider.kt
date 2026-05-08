package com.example.sukun_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray
import java.util.Calendar

class DhikrWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        // When the user deletes the widget, delete the preference associated with it.
        for (appWidgetId in appWidgetIds) {
            val prefs = context.getSharedPreferences("com.example.sukun_app.DhikrWidgetProvider", 0).edit()
            prefs.remove("dhikr_type_" + appWidgetId)
            prefs.apply()
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.widget_dhikr)

            // Read preference
            val selectedType = WidgetConfigureActivity.loadTypePref(context, appWidgetId)

            try {
                val assetManager = context.assets
                val inputStream = assetManager.open("flutter_assets/assets/data/quotes.json")
                val jsonString = inputStream.bufferedReader().use { it.readText() }
                val fullArray = JSONArray(jsonString)

                // Filter by type
                val filteredList = mutableListOf<org.json.JSONObject>()
                for (i in 0 until fullArray.length()) {
                    val obj = fullArray.getJSONObject(i)
                    if (selectedType == "all" || obj.optString("type", "") == selectedType) {
                        filteredList.add(obj)
                    }
                }

                if (filteredList.isNotEmpty()) {
                    val calendar = Calendar.getInstance()
                    val year = calendar.get(Calendar.YEAR)
                    val month = calendar.get(Calendar.MONTH) + 1 // Calendar.MONTH is 0-based
                    val day = calendar.get(Calendar.DAY_OF_MONTH)

                    val seed = year * 10000 + month * 100 + day
                    val index = seed % filteredList.size

                    val quoteObj = filteredList[index]
                    val textAr = quoteObj.optString("text_ar", "")
                    val textEn = quoteObj.optString("text_en", "")

                    views.setTextViewText(R.id.tv_dhikr_ar, textAr)
                    views.setTextViewText(R.id.tv_dhikr_en, textEn)
                }
            } catch (e: Exception) {
                e.printStackTrace()
                // Fallback or error state
                views.setTextViewText(R.id.tv_dhikr_ar, "سُبْحَانَ اللَّهِ")
                views.setTextViewText(R.id.tv_dhikr_en, "Glory be to Allah")
            }

            // Create an Intent to launch the app when the widget is clicked
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (intent != null) {
                val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
