package com.thanush.synthese

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val CHANNEL = "synthese/home_widget"
        private const val TAG = "SyntheseWidget"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateSteps" -> {
                        val rawSteps = call.argument<Number>("steps")
                        val steps = rawSteps?.toInt()
                        if (steps == null) {
                            result.error("INVALID_ARGS", "steps is required", null)
                            return@setMethodCallHandler
                        }
                        val prefs = HomeWidgetStore.prefs(applicationContext)
                        val currentHeartRate = prefs.getInt(HomeWidgetStore.KEY_HEART_RATE, 0)
                        val currentActiveCalories = prefs.getInt(HomeWidgetStore.KEY_ACTIVE_CALORIES, 0)
                        val currentExerciseMinutes = prefs.getInt(HomeWidgetStore.KEY_EXERCISE_MINUTES, 0)

                        HomeWidgetStore.writeDashboardMetrics(
                            applicationContext,
                            steps = steps,
                            heartRate = call.argument<Number>("heartRate")?.toInt() ?: currentHeartRate,
                            activeCalories = call.argument<Number>("activeCalories")?.toInt() ?: currentActiveCalories,
                            exerciseMinutes = call.argument<Number>("exerciseMinutes")?.toInt() ?: currentExerciseMinutes
                        )
                        refreshDashboardWidgets(applicationContext)
                        result.success(null)
                    }
                    "updateDashboardMetrics" -> {
                        val steps = call.argument<Number>("steps")?.toInt()
                        val heartRate = call.argument<Number>("heartRate")?.toInt()
                        val activeCalories = call.argument<Number>("activeCalories")?.toInt()
                        val exerciseMinutes = call.argument<Number>("exerciseMinutes")?.toInt()
                        if (steps == null || heartRate == null || activeCalories == null || exerciseMinutes == null) {
                            result.error("INVALID_ARGS", "steps, heartRate, activeCalories, exerciseMinutes are required", null)
                            return@setMethodCallHandler
                        }
                        HomeWidgetStore.writeDashboardMetrics(
                            applicationContext,
                            steps = steps,
                            heartRate = heartRate,
                            activeCalories = activeCalories,
                            exerciseMinutes = exerciseMinutes
                        )
                        refreshDashboardWidgets(applicationContext)
                        result.success(null)
                    }
                    "updateWorkoutSummary" -> {
                        val mode = call.argument<String>("mode") ?: "Workout"
                        val distance = call.argument<String>("distance") ?: "0.00 km"
                        val duration = call.argument<String>("duration") ?: "00:00:00"
                        val calories = call.argument<Number>("calories")?.toInt() ?: 0
                        val paceLabel = call.argument<String>("paceLabel") ?: "Speed"
                        val paceValue = call.argument<String>("paceValue") ?: "--"
                        val rawRoute = call.argument<List<*>>("routePoints") ?: emptyList<Any?>()
                        val route = rawRoute.mapNotNull { item ->
                            val map = item as? Map<*, *> ?: return@mapNotNull null
                            RoutePoint(
                                lat = (map["lat"] as? Number)?.toDouble() ?: 0.0,
                                lng = (map["lng"] as? Number)?.toDouble() ?: 0.0
                            )
                        }
                        HomeWidgetStore.writeWorkoutSummary(
                            applicationContext,
                            mode = mode,
                            distance = distance,
                            duration = duration,
                            calories = calories,
                            paceLabel = paceLabel,
                            paceValue = paceValue,
                            routePoints = route
                        )
                        WorkoutSummaryWidgetProvider.refreshAll(applicationContext)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun refreshDashboardWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val providerClasses = listOf(
            StepsHomeWidgetProvider::class.java,
            HeartRateMetricWidgetProvider::class.java,
            CaloriesMetricWidgetProvider::class.java,
            ExerciseMetricWidgetProvider::class.java,
            DashboardWideWidgetProvider::class.java,
        )
        providerClasses.forEach { provider ->
            val ids = manager.getAppWidgetIds(ComponentName(context, provider))
            Log.d(TAG, "Refreshing ${provider.simpleName}, widgetCount=${ids.size}")
            if (ids.isNotEmpty()) {
                val intent = Intent(context, provider).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                context.sendBroadcast(intent)
            }
        }
    }
}
