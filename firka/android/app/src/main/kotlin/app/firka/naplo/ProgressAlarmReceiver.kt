package app.firka.naplo

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId

class ProgressAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        Log.d(TAG, "onReceive action: ${intent?.action}")

        scheduleNext6AmAlarm(context)

        val data = ProgressNotificationForegroundService.loadTodayTimetable(context)
        if (data == null || data.lessons.isEmpty()) {
            Log.d(TAG, "No timetable for today at 6 AM wakeup; skipping service start")
            return
        }

        val sorted = data.lessons.sortedBy { it.start }
        val lastLesson = sorted.last()
        val now = LocalDateTime.now()

        if (now.isBefore(lastLesson.end)) {
            Log.d(TAG, "Starting ProgressNotificationForegroundService from 6 AM alarm")
            val serviceIntent = Intent(context, ProgressNotificationForegroundService::class.java).apply {
                action = ProgressNotificationForegroundService.ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }
    }

    companion object {
        private const val TAG = "ProgressAlarmReceiver"
        const val ACTION_PROGRESS_6AM_ALARM = "app.firka.naplo.ACTION_PROGRESS_6AM_ALARM"
        const val ALARM_REQUEST_CODE = 400201

        fun scheduleNext6AmAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val intent = Intent(context, ProgressAlarmReceiver::class.java).apply {
                action = ACTION_PROGRESS_6AM_ALARM
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                ALARM_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val now = LocalDateTime.now()
            var target = now.toLocalDate().atTime(6, 0)
            if (!target.isAfter(now)) {
                target = target.plusDays(1)
            }

            val epochMillis = target.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
            Log.d(TAG, "Scheduling next 6 AM alarm for $target ($epochMillis)")

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, epochMillis, pendingIntent)
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, epochMillis, pendingIntent)
                }
            } catch (e: SecurityException) {
                Log.w(TAG, "SecurityException while scheduling exact 6 AM alarm, falling back to setWindow", e)
                alarmManager.set(AlarmManager.RTC_WAKEUP, epochMillis, pendingIntent)
            }
        }

        fun cancel6AmAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val intent = Intent(context, ProgressAlarmReceiver::class.java).apply {
                action = ACTION_PROGRESS_6AM_ALARM
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                ALARM_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
            Log.d(TAG, "Cancelled 6 AM progress alarm")
        }
    }
}
