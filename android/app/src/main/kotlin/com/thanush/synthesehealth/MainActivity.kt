package com.thanush.synthesehealth

import android.content.Context
import android.os.Build
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val stepChannelName = "com.thanush.synthesehealth/step_milestones"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            stepChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "configure" -> {
                    saveConfig(call)
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    if (enabled) {
                        StepMilestoneService.start(this)
                    } else {
                        StepMilestoneService.stop(this)
                    }
                    result.success(true)
                }
                "stop" -> {
                    getSharedPreferences(StepMilestoneService.PREFS, Context.MODE_PRIVATE)
                        .edit()
                        .putBoolean(StepMilestoneService.KEY_ENABLED, false)
                        .apply()
                    StepMilestoneService.stop(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Persist goal, localized strings and the seed count for the service. */
    private fun saveConfig(call: MethodCall) {
        val prefs = getSharedPreferences(StepMilestoneService.PREFS, Context.MODE_PRIVATE)
        val e = prefs.edit()

        val enabled = call.argument<Boolean>("enabled") ?: false
        e.putBoolean(StepMilestoneService.KEY_ENABLED, enabled)

        call.argument<Int>("goal")?.let {
            e.putInt(StepMilestoneService.KEY_GOAL, it)
        }
        // Seed today's count so the service aligns with the in-app total and
        // doesn't re-alert milestones already passed before it started.
        call.argument<Int>("initialSteps")?.let {
            e.putInt(StepMilestoneService.KEY_SEED_STEPS, it.coerceAtLeast(0))
            e.putBoolean(StepMilestoneService.KEY_PENDING_SEED, true)
        }

        putString(call, e, "channelOngoing", StepMilestoneService.KEY_S_CH_ONGOING)
        putString(call, e, "channelMilestone", StepMilestoneService.KEY_S_CH_MILESTONE)
        putString(call, e, "ongoingTitle", StepMilestoneService.KEY_S_ONGOING_TITLE)
        putString(call, e, "ongoingBody", StepMilestoneService.KEY_S_ONGOING_BODY)
        putString(call, e, "title1k", StepMilestoneService.KEY_S_1K_TITLE)
        putString(call, e, "body1k", StepMilestoneService.KEY_S_1K_BODY)
        putString(call, e, "title5k", StepMilestoneService.KEY_S_5K_TITLE)
        putString(call, e, "body5k", StepMilestoneService.KEY_S_5K_BODY)
        putString(call, e, "titleGoal", StepMilestoneService.KEY_S_GOAL_TITLE)
        putString(call, e, "bodyGoal", StepMilestoneService.KEY_S_GOAL_BODY)

        e.apply()
    }

    private fun putString(
        call: MethodCall,
        editor: android.content.SharedPreferences.Editor,
        arg: String,
        key: String,
    ) {
        call.argument<String>(arg)?.let { editor.putString(key, it) }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideNavBar()
    }

    private fun hideNavBar() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ — hide navigation bar only, show transiently on swipe up
            window.insetsController?.let { ctrl ->
                ctrl.hide(WindowInsets.Type.navigationBars())
                ctrl.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            // Android 8–10 — legacy flags, nav bar only
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            )
        }
    }
}
