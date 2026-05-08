package com.example.sukun_app

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.RadioGroup

class WidgetConfigureActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Set the result to CANCELED. This will cause the widget host to cancel
        // out of the widget placement if the user presses the back button.
        setResult(RESULT_CANCELED)

        setContentView(R.layout.activity_widget_configure)

        // Find the widget id from the intent.
        val intent = intent
        val extras = intent.extras
        if (extras != null) {
            appWidgetId = extras.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID
            )
        }

        // If this activity was started with an intent without an app widget ID, finish with an error.
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val radioGroup = findViewById<RadioGroup>(R.id.rg_dhikr_type)
        val saveButton = findViewById<Button>(R.id.btn_save)

        saveButton.setOnClickListener {
            val context = this@WidgetConfigureActivity

            // Determine the selected type
            val selectedType = when (radioGroup.checkedRadioButtonId) {
                R.id.rb_ayah -> "ayah"
                R.id.rb_quote -> "quote"
                R.id.rb_dhikr -> "dhikr"
                else -> "all"
            }

            // Save the preference locally for this widget ID
            saveTypePref(context, appWidgetId, selectedType)

            // It is the responsibility of the configuration activity to update the app widget
            val appWidgetManager = AppWidgetManager.getInstance(context)
            DhikrWidgetProvider.updateAppWidget(context, appWidgetManager, appWidgetId)

            // Make sure we pass back the original appWidgetId
            val resultValue = Intent()
            resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            setResult(RESULT_OK, resultValue)
            finish()
        }
    }

    companion object {
        private const val PREFS_NAME = "com.example.sukun_app.DhikrWidgetProvider"
        private const val PREF_PREFIX_KEY = "dhikr_type_"

        // Write the prefix to the SharedPreferences object for this widget
        fun saveTypePref(context: Context, appWidgetId: Int, text: String) {
            val prefs = context.getSharedPreferences(PREFS_NAME, 0).edit()
            prefs.putString(PREF_PREFIX_KEY + appWidgetId, text)
            prefs.apply()
        }

        // Read the prefix from the SharedPreferences object for this widget.
        // If there is no preference saved, get the default.
        fun loadTypePref(context: Context, appWidgetId: Int): String {
            val prefs = context.getSharedPreferences(PREFS_NAME, 0)
            return prefs.getString(PREF_PREFIX_KEY + appWidgetId, "all") ?: "all"
        }
    }
}
