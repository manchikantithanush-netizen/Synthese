package com.thanush.synthesehealth

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.util.Calendar

/**
 * Foreground service that watches the device's cumulative step-counter sensor
 * and fires milestone notifications at 1,000 / 5,000 / the user's goal — even
 * while the Flutter app is closed or the phone is locked.
 *
 * It mirrors the baseline math of the Dart [StepTracker]: TYPE_STEP_COUNTER is
 * cumulative-since-boot, so today's steps are derived from a per-day baseline
 * persisted in SharedPreferences. The service is the source of truth for
 * milestone alerts; the in-app counter remains independent.
 */
class StepMilestoneService : Service(), SensorEventListener {

    private var sensorManager: SensorManager? = null
    private var stepSensor: Sensor? = null

    private val prefs by lazy {
        getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createChannels()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Must call startForeground promptly after start. If the OS rejects it
        // (e.g. the activity-recognition permission isn't granted yet), bail out
        // gracefully — Flutter re-syncs and restarts us once it's granted.
        try {
            startForegroundInternal(buildOngoingNotification(currentTodaySteps()))
        } catch (e: Exception) {
            stopSelf()
            return START_NOT_STICKY
        }

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        stepSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        if (stepSensor == null) {
            // No hardware step counter — nothing to do.
            stopSelf()
            return START_NOT_STICKY
        }
        sensorManager?.registerListener(
            this,
            stepSensor,
            SensorManager.SENSOR_DELAY_NORMAL,
        )
        return START_STICKY
    }

    override fun onDestroy() {
        sensorManager?.unregisterListener(this)
        super.onDestroy()
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || event.sensor.type != Sensor.TYPE_STEP_COUNTER) return
        val cumulative = event.values.firstOrNull()?.toLong() ?: return
        handleCumulative(cumulative)
    }

    private fun handleCumulative(cumulative: Long) {
        rolloverIfNeeded()

        var baseline = prefs.getLong(KEY_BASELINE, -1L)
        if (baseline < 0L) {
            // First reading today: seed from the value Flutter handed us (so the
            // count lines up with the app and we don't re-alert past milestones),
            // or from zero after a midnight rollover.
            val seed = if (prefs.getBoolean(KEY_PENDING_SEED, false)) {
                prefs.getInt(KEY_SEED_STEPS, 0).coerceAtLeast(0)
            } else {
                0
            }
            baseline = cumulative - seed
            prefs.edit()
                .putLong(KEY_BASELINE, baseline)
                .putBoolean(KEY_PENDING_SEED, false)
                .apply()
            // Suppress milestones already passed at seed time — alert only on
            // genuine crossings from here on.
            if (seed > 0) suppressPassedMilestones(seed)
        } else if (cumulative < baseline) {
            // Device rebooted: hardware counter reset toward zero. Re-anchor so
            // today's already-counted steps are preserved.
            baseline = cumulative - currentTodaySteps()
            prefs.edit().putLong(KEY_BASELINE, baseline).apply()
        }

        val today = (cumulative - baseline).coerceAtLeast(0L).toInt()
        prefs.edit().putInt(KEY_TODAY, today).apply()

        checkMilestones(today)
        updateOngoingNotification(today)
    }

    private fun checkMilestones(today: Int) {
        val goal = prefs.getInt(KEY_GOAL, DEFAULT_GOAL).coerceAtLeast(1)

        if (!prefs.getBoolean(KEY_FIRED_1K, false) && today >= 1000) {
            prefs.edit().putBoolean(KEY_FIRED_1K, true).apply()
            notifyMilestone(
                NOTIF_1K,
                str(KEY_S_1K_TITLE, "1,000 steps! 👟"),
                str(KEY_S_1K_BODY, "Great start — you've passed 1,000 steps today."),
            )
        }
        if (!prefs.getBoolean(KEY_FIRED_5K, false) && today >= 5000) {
            prefs.edit().putBoolean(KEY_FIRED_5K, true).apply()
            notifyMilestone(
                NOTIF_5K,
                str(KEY_S_5K_TITLE, "5,000 steps! 🔥"),
                str(KEY_S_5K_BODY, "You're on a roll — 5,000 steps and counting."),
            )
        }
        if (!prefs.getBoolean(KEY_FIRED_GOAL, false) && today >= goal) {
            prefs.edit().putBoolean(KEY_FIRED_GOAL, true).apply()
            val body = str(
                KEY_S_GOAL_BODY,
                "You hit your {goal}-step goal for today. Amazing!",
            ).replace("{goal}", format(goal))
            notifyMilestone(
                NOTIF_GOAL,
                str(KEY_S_GOAL_TITLE, "Goal reached! 🎉"),
                body,
            )
        }
    }

    /** Mark any milestone at or below [steps] as already fired (no alert). */
    private fun suppressPassedMilestones(steps: Int) {
        val goal = prefs.getInt(KEY_GOAL, DEFAULT_GOAL).coerceAtLeast(1)
        val e = prefs.edit()
        if (steps >= 1000) e.putBoolean(KEY_FIRED_1K, true)
        if (steps >= 5000) e.putBoolean(KEY_FIRED_5K, true)
        if (steps >= goal) e.putBoolean(KEY_FIRED_GOAL, true)
        e.apply()
    }

    private fun rolloverIfNeeded() {
        val today = dateKey()
        if (prefs.getString(KEY_BASELINE_DATE, "") != today) {
            prefs.edit()
                .putString(KEY_BASELINE_DATE, today)
                .putLong(KEY_BASELINE, -1L)
                .putInt(KEY_TODAY, 0)
                .putBoolean(KEY_FIRED_1K, false)
                .putBoolean(KEY_FIRED_5K, false)
                .putBoolean(KEY_FIRED_GOAL, false)
                // A fresh day starts at zero; never seed from a stale value.
                .putBoolean(KEY_PENDING_SEED, false)
                .apply()
        }
    }

    private fun currentTodaySteps(): Int = prefs.getInt(KEY_TODAY, 0)

    // ── Notifications ─────────────────────────────────────────────────────────

    private fun startForegroundInternal(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIF_ONGOING,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH,
            )
        } else {
            startForeground(NOTIF_ONGOING, notification)
        }
    }

    private fun buildOngoingNotification(today: Int): Notification {
        val body = str(KEY_S_ONGOING_BODY, "{steps} steps today")
            .replace("{steps}", format(today))
        return NotificationCompat.Builder(this, CHANNEL_ONGOING)
            .setContentTitle(str(KEY_S_ONGOING_TITLE, "Step tracking active"))
            .setContentText(body)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(launchPendingIntent())
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun updateOngoingNotification(today: Int) {
        notificationManager().notify(NOTIF_ONGOING, buildOngoingNotification(today))
    }

    private fun notifyMilestone(id: Int, title: String, body: String) {
        val n = NotificationCompat.Builder(this, CHANNEL_MILESTONE)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(launchPendingIntent())
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        notificationManager().notify(id, n)
    }

    private fun launchPendingIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun createChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = notificationManager()
        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ONGOING,
                str(KEY_S_CH_ONGOING, "Step tracking"),
                NotificationManager.IMPORTANCE_LOW,
            ).apply { setShowBadge(false) },
        )
        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_MILESTONE,
                str(KEY_S_CH_MILESTONE, "Step milestones"),
                NotificationManager.IMPORTANCE_DEFAULT,
            ),
        )
    }

    private fun notificationManager(): NotificationManager =
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    // ── helpers ───────────────────────────────────────────────────────────────

    private fun str(key: String, fallback: String): String {
        val v = prefs.getString(key, null)
        return if (v.isNullOrEmpty()) fallback else v
    }

    private fun format(n: Int): String = "%,d".format(n)

    private fun dateKey(): String {
        val c = Calendar.getInstance()
        val y = c.get(Calendar.YEAR)
        val m = c.get(Calendar.MONTH) + 1
        val d = c.get(Calendar.DAY_OF_MONTH)
        return "%04d-%02d-%02d".format(y, m, d)
    }

    companion object {
        const val PREFS = "step_milestones"

        // Config / state keys (shared with MainActivity + BootReceiver).
        const val KEY_ENABLED = "enabled"
        const val KEY_GOAL = "goal"
        const val KEY_SEED_STEPS = "seed_steps"
        const val KEY_PENDING_SEED = "pending_seed"
        const val KEY_BASELINE = "baseline_cumulative"
        const val KEY_BASELINE_DATE = "baseline_date"
        const val KEY_TODAY = "today_steps"
        const val KEY_FIRED_1K = "fired_1k"
        const val KEY_FIRED_5K = "fired_5k"
        const val KEY_FIRED_GOAL = "fired_goal"

        // Localized string keys.
        const val KEY_S_CH_ONGOING = "s_channel_ongoing"
        const val KEY_S_CH_MILESTONE = "s_channel_milestone"
        const val KEY_S_ONGOING_TITLE = "s_ongoing_title"
        const val KEY_S_ONGOING_BODY = "s_ongoing_body"
        const val KEY_S_1K_TITLE = "s_1k_title"
        const val KEY_S_1K_BODY = "s_1k_body"
        const val KEY_S_5K_TITLE = "s_5k_title"
        const val KEY_S_5K_BODY = "s_5k_body"
        const val KEY_S_GOAL_TITLE = "s_goal_title"
        const val KEY_S_GOAL_BODY = "s_goal_body"

        const val DEFAULT_GOAL = 10000

        private const val CHANNEL_ONGOING = "step_milestones_ongoing"
        private const val CHANNEL_MILESTONE = "step_milestones_alerts"

        private const val NOTIF_ONGOING = 4201
        private const val NOTIF_1K = 4211
        private const val NOTIF_5K = 4212
        private const val NOTIF_GOAL = 4213

        fun start(context: Context) {
            val intent = Intent(context, StepMilestoneService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, StepMilestoneService::class.java))
        }
    }
}
