package com.thanush.synthese

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.widget.RemoteViews
import java.text.NumberFormat
import java.util.Locale
import kotlin.math.max
import kotlin.math.min

private fun formatNumber(value: Int): String =
    NumberFormat.getNumberInstance(Locale.getDefault()).format(value)

class DashboardWideWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    companion object {
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, DashboardWideWidgetProvider::class.java)
            )
            updateWidgets(context, manager, ids)
        }

        fun updateWidgets(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
            val prefs = HomeWidgetStore.prefs(context)
            val steps = prefs.getInt(HomeWidgetStore.KEY_STEPS, 0)
            val heartRate = prefs.getInt(HomeWidgetStore.KEY_HEART_RATE, 0)
            val activeCalories = prefs.getInt(HomeWidgetStore.KEY_ACTIVE_CALORIES, 0)
            val exerciseMinutes = prefs.getInt(HomeWidgetStore.KEY_EXERCISE_MINUTES, 0)

            appWidgetIds.forEach { id ->
                val views = RemoteViews(context.packageName, R.layout.dashboard_wide_widget)
                views.setTextViewText(R.id.wide_steps_value, formatNumber(steps))
                views.setTextViewText(R.id.wide_hr_value, heartRate.toString())
                views.setTextViewText(R.id.wide_cal_value, formatNumber(activeCalories))
                views.setTextViewText(R.id.wide_ex_value, exerciseMinutes.toString())
                appWidgetManager.updateAppWidget(id, views)
            }
        }
    }
}

class HeartRateMetricWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    companion object {
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, HeartRateMetricWidgetProvider::class.java)
            )
            updateWidgets(context, manager, ids)
        }

        fun updateWidgets(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
            val heartRate = HomeWidgetStore.prefs(context).getInt(HomeWidgetStore.KEY_HEART_RATE, 0)
            appWidgetIds.forEach { id ->
                val views = RemoteViews(context.packageName, R.layout.metric_heart_rate_widget)
                views.setTextViewText(R.id.metric_value, heartRate.toString())
                appWidgetManager.updateAppWidget(id, views)
            }
        }
    }
}

class CaloriesMetricWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    companion object {
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, CaloriesMetricWidgetProvider::class.java)
            )
            updateWidgets(context, manager, ids)
        }

        fun updateWidgets(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
            val calories = HomeWidgetStore.prefs(context).getInt(HomeWidgetStore.KEY_ACTIVE_CALORIES, 0)
            appWidgetIds.forEach { id ->
                val views = RemoteViews(context.packageName, R.layout.metric_calories_widget)
                views.setTextViewText(R.id.metric_value, formatNumber(calories))
                appWidgetManager.updateAppWidget(id, views)
            }
        }
    }
}

class ExerciseMetricWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    companion object {
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, ExerciseMetricWidgetProvider::class.java)
            )
            updateWidgets(context, manager, ids)
        }

        fun updateWidgets(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
            val minutes = HomeWidgetStore.prefs(context).getInt(HomeWidgetStore.KEY_EXERCISE_MINUTES, 0)
            appWidgetIds.forEach { id ->
                val views = RemoteViews(context.packageName, R.layout.metric_exercise_widget)
                views.setTextViewText(R.id.metric_value, minutes.toString())
                appWidgetManager.updateAppWidget(id, views)
            }
        }
    }
}

class WorkoutSummaryWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    companion object {
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, WorkoutSummaryWidgetProvider::class.java)
            )
            updateWidgets(context, manager, ids)
        }

        fun updateWidgets(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
            val prefs = HomeWidgetStore.prefs(context)
            val mode = prefs.getString(HomeWidgetStore.KEY_WORKOUT_MODE, "Workout") ?: "Workout"
            val distance = prefs.getString(HomeWidgetStore.KEY_WORKOUT_DISTANCE, "0.00 km") ?: "0.00 km"
            val duration = prefs.getString(HomeWidgetStore.KEY_WORKOUT_DURATION, "00:00:00") ?: "00:00:00"
            val calories = prefs.getInt(HomeWidgetStore.KEY_WORKOUT_CALORIES, 0)
            val paceLabel = prefs.getString(HomeWidgetStore.KEY_WORKOUT_PACE_LABEL, "Speed") ?: "Speed"
            val paceValue = prefs.getString(HomeWidgetStore.KEY_WORKOUT_PACE_VALUE, "--") ?: "--"
            val route = HomeWidgetStore.readRoutePoints(context)

            appWidgetIds.forEach { id ->
                val views = RemoteViews(context.packageName, R.layout.workout_summary_widget)
                views.setTextViewText(R.id.workout_mode, mode)
                views.setTextViewText(R.id.workout_distance, distance)
                views.setTextViewText(R.id.workout_duration, duration)
                views.setTextViewText(R.id.workout_calories, formatNumber(calories))
                views.setTextViewText(R.id.workout_pace_label, paceLabel)
                views.setTextViewText(R.id.workout_pace_value, paceValue)
                views.setImageViewBitmap(
                    R.id.workout_route_line,
                    drawRouteLineBitmap(route, width = 260, height = 130)
                )
                appWidgetManager.updateAppWidget(id, views)
            }
        }

        private fun drawRouteLineBitmap(route: List<RoutePoint>, width: Int, height: Int): Bitmap {
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)

            val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 5f
                color = 0x334C8DFFFF.toInt()
                strokeCap = Paint.Cap.ROUND
                strokeJoin = Paint.Join.ROUND
            }
            val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 5.5f
                color = 0xFF4C8DFF.toInt()
                strokeCap = Paint.Cap.ROUND
                strokeJoin = Paint.Join.ROUND
            }

            val points = if (route.size >= 2) route else listOf(
                RoutePoint(0.0, 0.0),
                RoutePoint(0.2, 0.1),
                RoutePoint(0.35, 0.5),
                RoutePoint(0.55, 0.45),
                RoutePoint(0.85, 0.8),
                RoutePoint(1.0, 1.0),
            )

            var minLat = points.first().lat
            var maxLat = points.first().lat
            var minLng = points.first().lng
            var maxLng = points.first().lng

            points.forEach {
                minLat = min(minLat, it.lat)
                maxLat = max(maxLat, it.lat)
                minLng = min(minLng, it.lng)
                maxLng = max(maxLng, it.lng)
            }

            val latRange = if (maxLat - minLat == 0.0) 1.0 else maxLat - minLat
            val lngRange = if (maxLng - minLng == 0.0) 1.0 else maxLng - minLng
            val pad = 10f
            val usableW = width - pad * 2
            val usableH = height - pad * 2

            val path = Path()
            points.forEachIndexed { index, point ->
                val nx = ((point.lng - minLng) / lngRange).toFloat()
                val ny = ((point.lat - minLat) / latRange).toFloat()
                val x = pad + nx * usableW
                val y = pad + (1f - ny) * usableH
                if (index == 0) path.moveTo(x, y) else path.lineTo(x, y)
            }

            canvas.drawPath(path, trackPaint)
            canvas.drawPath(path, linePaint)
            return bitmap
        }
    }
}
