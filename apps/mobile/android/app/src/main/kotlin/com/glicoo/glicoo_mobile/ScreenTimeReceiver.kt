package com.glicoo.glicoo_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences

/**
 * Tracks total screen-on duration by listening to SCREEN_ON / SCREEN_OFF broadcasts.
 *
 * WHY: PACKAGE_USAGE_STATS requires a special grant most users cannot give.
 * SCREEN_ON/OFF broadcasts need no permission and work even when the app is closed.
 * Data is stored in SharedPreferences so it survives process death.
 *
 * CONTRACT:
 *   - SharedPreferences name: "glico_screen_time"
 *   - "screen_on_ts"   → Long  : epoch ms when screen last turned on (0 = screen is off)
 *   - "today_date"     → String: "yyyy-MM-dd" of the date the accumulator belongs to
 *   - "today_seconds"  → Long  : accumulated screen-on seconds for today
 *
 * TRADEOFF: First-boot / reboot without a SCREEN_ON event won't have a start timestamp,
 * so we treat it as screen-off until the next SCREEN_ON broadcast.
 */
class ScreenTimeReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_SCREEN_ON,
            Intent.ACTION_BOOT_COMPLETED -> handleScreenOn(context)

            Intent.ACTION_SCREEN_OFF -> handleScreenOff(context)
        }
    }

    companion object {
        private const val PREFS_NAME = "glico_screen_time"
        private const val KEY_SCREEN_ON_TS = "screen_on_ts"
        private const val KEY_TODAY_DATE = "today_date"
        private const val KEY_TODAY_SECONDS = "today_seconds"

        private fun prefs(context: Context): SharedPreferences =
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        private fun todayStr(): String {
            val cal = java.util.Calendar.getInstance()
            val y = cal.get(java.util.Calendar.YEAR)
            val m = (cal.get(java.util.Calendar.MONTH) + 1).toString().padStart(2, '0')
            val d = cal.get(java.util.Calendar.DAY_OF_MONTH).toString().padStart(2, '0')
            return "$y-$m-$d"
        }

        /** Mark screen-on timestamp. */
        fun handleScreenOn(context: Context) {
            val prefs = prefs(context)
            rolloverIfNewDay(prefs)
            prefs.edit().putLong(KEY_SCREEN_ON_TS, System.currentTimeMillis()).apply()
        }

        /** Accumulate elapsed seconds since last SCREEN_ON, then clear the timestamp. */
        fun handleScreenOff(context: Context) {
            val prefs = prefs(context)
            rolloverIfNewDay(prefs)

            val onTs = prefs.getLong(KEY_SCREEN_ON_TS, 0L)
            if (onTs == 0L) return // screen was never registered as on — skip

            val elapsedSeconds = (System.currentTimeMillis() - onTs) / 1_000L
            val accumulated = prefs.getLong(KEY_TODAY_SECONDS, 0L)

            prefs.edit()
                .putLong(KEY_TODAY_SECONDS, accumulated + elapsedSeconds)
                .putLong(KEY_SCREEN_ON_TS, 0L) // clear: screen is now off
                .apply()
        }

        /**
         * Returns today's total screen-on time in seconds.
         * If screen is currently ON, adds the in-progress session to the stored total.
         */
        fun getTodaySeconds(context: Context): Long {
            val prefs = prefs(context)
            rolloverIfNewDay(prefs)

            val stored = prefs.getLong(KEY_TODAY_SECONDS, 0L)
            val onTs = prefs.getLong(KEY_SCREEN_ON_TS, 0L)

            // Screen is currently on — add live elapsed time
            return if (onTs != 0L) {
                val live = (System.currentTimeMillis() - onTs) / 1_000L
                stored + live
            } else {
                stored
            }
        }

        /** Reset accumulator when the calendar date changes. */
        private fun rolloverIfNewDay(prefs: SharedPreferences) {
            val today = todayStr()
            val stored = prefs.getString(KEY_TODAY_DATE, "") ?: ""
            if (stored != today) {
                prefs.edit()
                    .putString(KEY_TODAY_DATE, today)
                    .putLong(KEY_TODAY_SECONDS, 0L)
                    .putLong(KEY_SCREEN_ON_TS, 0L)
                    .apply()
            }
        }
    }
}
