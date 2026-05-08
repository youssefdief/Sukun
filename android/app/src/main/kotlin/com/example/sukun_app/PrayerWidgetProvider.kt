package com.example.sukun_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.widget.RemoteViews
import org.json.JSONObject
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class PrayerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.widget_prayer)

            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val prayerDataJson = prefs.getString("flutter.prayer_data_v2", null)

            var nextPrayerTimeMs: Long = 0
            var currentPrayerName = "None"
            var nextPrayerName = "None"
            var nextPrayerTimeStr = "--:--"
            var activePrayerIndex = -1

            if (prayerDataJson != null) {
                try {
                    val root = JSONObject(prayerDataJson)
                    val data = root.opt("data")

                    val calendar = Calendar.getInstance()
                    val todayFormat = SimpleDateFormat("dd-MM-yyyy", Locale.US)
                    val todayStr = todayFormat.format(calendar.time)

                    var todayData: JSONObject? = null
                    
                    if (data is JSONArray) {
                        for (i in 0 until data.length()) {
                            val dayObj = data.getJSONObject(i)
                            val dateObj = dayObj.optJSONObject("date")?.optJSONObject("gregorian")
                            if (dateObj?.optString("date") == todayStr) {
                                todayData = dayObj
                                break
                            }
                        }
                    } else if (data is JSONObject) {
                        todayData = data as JSONObject
                    }

                    if (todayData != null) {
                        val timings = todayData.getJSONObject("timings")
                        val prayerNames = arrayOf("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")
                        val prayerIds = arrayOf(
                            R.id.tv_fajr_time to R.id.dot_fajr,
                            R.id.tv_dhuhr_time to R.id.dot_dhuhr,
                            R.id.tv_asr_time to R.id.dot_asr,
                            R.id.tv_maghrib_time to R.id.dot_maghrib,
                            R.id.tv_isha_time to R.id.dot_isha
                        )
                        
                        val now = calendar.timeInMillis
                        var foundNext = false
                        
                        for (i in prayerNames.indices) {
                            val name = prayerNames[i]
                            val timeStr = timings.getString(name).split(" ")[0]
                            val parts = timeStr.split(":")
                            
                            val pCal = Calendar.getInstance()
                            pCal.set(Calendar.HOUR_OF_DAY, parts[0].toInt())
                            pCal.set(Calendar.MINUTE, parts[1].toInt())
                            pCal.set(Calendar.SECOND, 0)
                            
                            val pTime = pCal.timeInMillis
                            
                            // Set timeline time
                            views.setTextViewText(prayerIds[i].first, timeStr)
                            
                            if (!foundNext && pTime > now) {
                                nextPrayerName = name
                                nextPrayerTimeMs = pTime
                                nextPrayerTimeStr = timeStr
                                currentPrayerName = if (i > 0) prayerNames[i - 1] else "Isha"
                                activePrayerIndex = if (i > 0) i - 1 else 4
                                foundNext = true
                            }
                        }
                        
                        if (!foundNext) {
                            val fajrStr = timings.getString("Fajr").split(" ")[0]
                            val parts = fajrStr.split(":")
                            val pCal = Calendar.getInstance()
                            pCal.add(Calendar.DAY_OF_YEAR, 1)
                            pCal.set(Calendar.HOUR_OF_DAY, parts[0].toInt())
                            pCal.set(Calendar.MINUTE, parts[1].toInt())
                            pCal.set(Calendar.SECOND, 0)
                            
                            nextPrayerName = "Fajr"
                            nextPrayerTimeMs = pCal.timeInMillis
                            nextPrayerTimeStr = fajrStr
                            currentPrayerName = "Isha"
                            activePrayerIndex = 4
                        }

                        // Highlight active prayer in timeline
                        for (i in prayerNames.indices) {
                            val (timeId, dotId) = prayerIds[i]
                            if (i == activePrayerIndex) {
                                views.setTextColor(timeId, context.getColor(R.color.sukun_green))
                                views.setImageViewResource(dotId, R.drawable.widget_dot_active)
                            } else {
                                views.setTextColor(timeId, context.getColor(R.color.sukun_on_surface_variant))
                                views.setImageViewResource(dotId, R.drawable.widget_dot_inactive)
                            }
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            // Localize prayer names if needed
            val isArabic = Locale.getDefault().language == "ar"
            fun localize(name: String): String {
                if (!isArabic) return name
                return when(name) {
                    "Fajr" -> "الفجر"
                    "Dhuhr" -> "الظهر"
                    "Asr" -> "العصر"
                    "Maghrib" -> "المغرب"
                    "Isha" -> "العشاء"
                    else -> name
                }
            }

            if (nextPrayerTimeMs > 0) {
                views.setTextViewText(R.id.tv_current_prayer, localize(nextPrayerName))
                views.setTextViewText(R.id.tv_next_prayer_time, nextPrayerTimeStr)
                
                scheduleUpdate(context, nextPrayerTimeMs)
            } else {
                views.setTextViewText(R.id.tv_current_prayer, context.getString(R.string.widget_prayer_open_app))
                views.setTextViewText(R.id.tv_next_prayer_time, "--:--")
            }

            // Launch intent
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (intent != null) {
                val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun scheduleUpdate(context: Context, timeMs: Long) {
            val intent = Intent(context, PrayerWidgetProvider::class.java)
            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            // Send to all prayer widgets
            val componentName = android.content.ComponentName(context, PrayerWidgetProvider::class.java)
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)

            val pendingIntent = PendingIntent.getBroadcast(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            // Add a small 1s delay to make sure time has crossed
            alarmManager.setExact(AlarmManager.RTC, timeMs + 1000, pendingIntent)
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = android.content.ComponentName(context, PrayerWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            for (id in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, id)
            }
        }
    }
}
