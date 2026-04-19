package com.example.synthese

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.NumberFormat
import java.util.Locale

class StepsHomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
                ?: manager.getAppWidgetIds(
                    android.content.ComponentName(context, StepsHomeWidgetProvider::class.java)
                )
            updateWidgets(context, manager, ids)
        }
    }

    companion object {
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, StepsHomeWidgetProvider::class.java)
            )
            updateWidgets(context, manager, ids)
        }

        fun updateWidgets(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray
        ) {
            val prefs = HomeWidgetStore.prefs(context)
            val steps = prefs.getInt(HomeWidgetStore.KEY_STEPS, 0)
            val formattedSteps = NumberFormat.getNumberInstance(Locale.getDefault())
                .format(steps)

            appWidgetIds.forEach { widgetId ->
                val views = RemoteViews(context.packageName, R.layout.steps_home_widget)
                views.setTextViewText(R.id.steps_value, formattedSteps)
                appWidgetManager.updateAppWidget(widgetId, views)
            }
        }
    }
}
