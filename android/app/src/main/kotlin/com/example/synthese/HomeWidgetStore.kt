package com.thanush.synthese

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

data class RoutePoint(val lat: Double, val lng: Double)

object HomeWidgetStore {
    const val PREFS_NAME = "synthese_widget_prefs"

    const val KEY_STEPS = "steps_count"
    const val KEY_HEART_RATE = "heart_rate"
    const val KEY_ACTIVE_CALORIES = "active_calories"
    const val KEY_EXERCISE_MINUTES = "exercise_minutes"

    const val KEY_WORKOUT_MODE = "workout_mode"
    const val KEY_WORKOUT_DISTANCE = "workout_distance"
    const val KEY_WORKOUT_DURATION = "workout_duration"
    const val KEY_WORKOUT_CALORIES = "workout_calories"
    const val KEY_WORKOUT_PACE_LABEL = "workout_pace_label"
    const val KEY_WORKOUT_PACE_VALUE = "workout_pace_value"
    const val KEY_WORKOUT_ROUTE_JSON = "workout_route_json"

    fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun writeDashboardMetrics(
        context: Context,
        steps: Int,
        heartRate: Int,
        activeCalories: Int,
        exerciseMinutes: Int
    ) {
        prefs(context).edit()
            .putInt(KEY_STEPS, steps)
            .putInt(KEY_HEART_RATE, heartRate)
            .putInt(KEY_ACTIVE_CALORIES, activeCalories)
            .putInt(KEY_EXERCISE_MINUTES, exerciseMinutes)
            .apply()
    }

    fun writeWorkoutSummary(
        context: Context,
        mode: String,
        distance: String,
        duration: String,
        calories: Int,
        paceLabel: String,
        paceValue: String,
        routePoints: List<RoutePoint>
    ) {
        val routeJson = JSONArray()
        routePoints.forEach { point ->
            val obj = JSONObject()
            obj.put("lat", point.lat)
            obj.put("lng", point.lng)
            routeJson.put(obj)
        }

        prefs(context).edit()
            .putString(KEY_WORKOUT_MODE, mode)
            .putString(KEY_WORKOUT_DISTANCE, distance)
            .putString(KEY_WORKOUT_DURATION, duration)
            .putInt(KEY_WORKOUT_CALORIES, calories)
            .putString(KEY_WORKOUT_PACE_LABEL, paceLabel)
            .putString(KEY_WORKOUT_PACE_VALUE, paceValue)
            .putString(KEY_WORKOUT_ROUTE_JSON, routeJson.toString())
            .apply()
    }

    fun readRoutePoints(context: Context): List<RoutePoint> {
        val json = prefs(context).getString(KEY_WORKOUT_ROUTE_JSON, null) ?: return emptyList()
        return try {
            val arr = JSONArray(json)
            buildList(arr.length()) {
                for (i in 0 until arr.length()) {
                    val item = arr.optJSONObject(i) ?: continue
                    val lat = item.optDouble("lat", 0.0)
                    val lng = item.optDouble("lng", 0.0)
                    add(RoutePoint(lat = lat, lng = lng))
                }
            }
        } catch (_: Throwable) {
            emptyList()
        }
    }
}
