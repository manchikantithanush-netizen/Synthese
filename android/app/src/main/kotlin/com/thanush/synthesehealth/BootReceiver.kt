package com.thanush.synthesehealth

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Restarts [StepMilestoneService] after a reboot so milestone tracking keeps
 * working without the user having to open the app. The hardware step counter
 * resets on reboot; the service re-anchors its baseline on the next reading.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != "android.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }
        val prefs = context.getSharedPreferences(
            StepMilestoneService.PREFS,
            Context.MODE_PRIVATE,
        )
        if (prefs.getBoolean(StepMilestoneService.KEY_ENABLED, false)) {
            StepMilestoneService.start(context)
        }
    }
}
