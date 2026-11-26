package app.firka.naplo

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import app.firka.naplo.glance.WidgetLesson
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.File
import java.time.Duration
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter

class ProgressNotificationForegroundService : Service() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var tickerJob: Job? = null
    private var isForegroundStarted = false
    // Set when started via startForegroundService(): Android then requires a
    // startForeground() call, even if we immediately decide to stop.
    private var awaitingStartForeground = false
    private var transitionPendingIntent: PendingIntent? = null

    private val timeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_TIME_TICK,
                Intent.ACTION_SCREEN_ON,
                Intent.ACTION_USER_PRESENT -> {
                    refreshAndPostNotification()
                }
            }
        }
    }

    private val channelId = "firka_progress_notification_v3"
    private val notificationId = 4002

    private val hhmm = DateTimeFormatter.ofPattern("HH:mm")

    private fun formatTemplate(template: String, vararg replacements: Pair<String, String>): String {
        var res = template
        for ((key, value) in replacements) {
            res = res.replace("{$key}", value)
        }
        return res
    }

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        createNotificationChannel()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_TIME_TICK)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        ContextCompat.registerReceiver(
            this,
            timeReceiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()
        when (intent?.action) {
            ACTION_START, ACTION_UPDATE -> {
                if (intent.action == ACTION_START) awaitingStartForeground = true
                isRunning = true
                refreshAndPostNotification()
                startTicker()
            }
            ACTION_STOP -> {
                isRunning = false
                stopForegroundService()
                return START_NOT_STICKY
            }
            else -> {
                awaitingStartForeground = true
                isRunning = true
                refreshAndPostNotification()
                startTicker()
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        isRunning = false
        cancelTransitionAlarm()
        try {
            unregisterReceiver(timeReceiver)
        } catch (_: Exception) {}
        tickerJob?.cancel()
        scope.cancel()
        super.onDestroy()
    }

    private fun startTicker() {
        tickerJob?.cancel()
        tickerJob = scope.launch {
            while (isActive) {
                val currentMillis = System.currentTimeMillis()
                val millisIntoMinute = currentMillis % 60_000
                // Target next :00 or :30 second boundary
                val delayMillis = if (millisIntoMinute < 30_000) {
                    30_000 - millisIntoMinute
                } else {
                    60_000 - millisIntoMinute
                }.coerceIn(1_000, 30_000)

                delay(delayMillis)
                refreshAndPostNotification()
            }
        }
    }

    private fun refreshAndPostNotification() {
        val widgetData = loadTodayTimetable(applicationContext)

        if (widgetData == null || widgetData.lessons.isEmpty()) {
            Log.d(TAG, "No lessons for today; stopping progress service")
            stopForegroundService()
            return
        }

        val lessons = widgetData.lessons.sortedBy { it.start }
        val now = LocalDateTime.now()
        val lastLesson = lessons.last()

        // If today's last lesson has ended, stop notification & foreground service
        if (now.isAfter(lastLesson.end) || now.isEqual(lastLesson.end)) {
            Log.d(TAG, "Last lesson of the day ended (${lastLesson.end}); stopping progress service")
            stopForegroundService()
            return
        }

        val notification = buildProgressNotification(widgetData, now)
        if (notification == null) {
            stopForegroundService()
            return
        }

        if (!isForegroundStarted) {
            promoteToForeground(notification)
        }

        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(notificationId, notification)

        // Schedule exact alarm for next transition (lesson start/end or break end)
        val firstLesson = lessons.first()
        val targetTransitionTime: LocalDateTime? = when {
            now.isBefore(firstLesson.start) -> firstLesson.start
            else -> {
                val currentLesson = lessons.find { !now.isBefore(it.start) && now.isBefore(it.end) }
                if (currentLesson != null) {
                    currentLesson.end
                } else {
                    val nextLesson = lessons.firstOrNull { it.start.isAfter(now) }
                    nextLesson?.start
                }
            }
        }
        if (targetTransitionTime != null) {
            scheduleNextTransitionAlarm(targetTransitionTime)
        }
    }

    private fun buildProgressNotification(data: TimetableProgressData, now: LocalDateTime): Notification? {
        val strings = getStrings(this)
        val lessons = data.lessons.sortedBy { it.start }
        val firstLesson = lessons.first()
        val lastLesson = lessons.last()

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val accentColor = data.accentColor
        val breakColor = data.breakColor

        val remainingLessonsCount = lessons.count { !now.isAfter(it.end) }
        val remainingSuffix = if (remainingLessonsCount == 1) {
            strings["progress_notif_remaining_lessons_one"] ?: ""
        } else {
            val template = strings["progress_notif_remaining_lessons_other"] ?: ""
            formatTemplate(template, "count" to remainingLessonsCount.toString())
        }

        if (now.isBefore(firstLesson.start)) {
            val minutesLeft = minutesRemaining(now, firstLesson.start)
            val firstLessonIconRes = resolveSubjectIcon(firstLesson)

            val title = if (firstLesson.lessonNumber != null) {
                val template = strings["progress_notif_lesson_title"] ?: ""
                if (template.isNotEmpty()) {
                    formatTemplate(template, "number" to firstLesson.lessonNumber.toString(), "name" to firstLesson.name)
                } else {
                    firstLesson.name
                }
            } else {
                firstLesson.name
            }

            val room = firstLesson.roomName?.trim()
            val roomSuffix = if (!room.isNullOrBlank() && room != "null") "\n$room" else ""
            val subSuffix = if (!firstLesson.substituteTeacher.isNullOrBlank() && firstLesson.substituteTeacher != "null" && firstLesson.substituteTeacher != "-") {
                strings["progress_notif_substitution"] ?: ""
            } else ""
            val timeRange = "${firstLesson.start.format(hhmm)}-${firstLesson.end.format(hhmm)}"
            val templateCase1 = strings["progress_notif_case1_text"] ?: ""
            val text = formatTemplate(
                templateCase1,
                "minutes" to minutesLeft.toString(),
                "timeRange" to timeRange,
                "room" to roomSuffix,
                "substitution" to subSuffix,
                "remaining" to remainingSuffix
            )
            val criticalTemplate = strings["progress_notif_critical_text"] ?: ""
            val criticalText = formatTemplate(criticalTemplate, "minutes" to minutesLeft.toString())

            val morningStart = firstLesson.start.toLocalDate().atTime(6, 0)
            val baseStart = if (now.isBefore(morningStart)) now else morningStart
            val totalMinutes = Duration.between(baseStart, firstLesson.start).toMinutes().coerceAtLeast(15)
            val elapsed = Duration.between(baseStart, now).toMinutes().coerceIn(0, totalMinutes)

            if (Build.VERSION.SDK_INT >= 36) {
                val progressStyle = Notification.ProgressStyle()
                    .setProgress(elapsed.toInt())
                    .setProgressSegments(listOf(
                        Notification.ProgressStyle.Segment(totalMinutes.toInt()).setColor(accentColor)
                    ))
                    .setProgressEndIcon(Icon.createWithResource(this, firstLessonIconRes))
                    .setProgressTrackerIcon(Icon.createWithResource(this, R.drawable.ic_subject_break))

                val builder = Notification.Builder(this, channelId)
                    .setStyle(progressStyle)
                    .setContentTitle(title)
                    .setContentText(text)
                    .setSmallIcon(R.drawable.ic_notification)
                    .setLargeIcon(Icon.createWithResource(this, firstLessonIconRes))
                    .setContentIntent(pendingIntent)
                    .setOngoing(true)
                    .setOnlyAlertOnce(true)
                    .setRequestPromotedOngoing(true)
                    .setShortCriticalText(criticalText.take(7))

                return builder.build()
            } else {
                return NotificationCompat.Builder(this, channelId)
                    .setContentTitle(title)
                    .setContentText(text)
                    .setSmallIcon(R.drawable.ic_notification)
                    .setContentIntent(pendingIntent)
                    .setProgress(totalMinutes.toInt(), elapsed.toInt(), false)
                    .setOngoing(true)
                    .setOnlyAlertOnce(true)
                    .build()
            }
        }

        val currentLesson = lessons.find { !now.isBefore(it.start) && now.isBefore(it.end) }

        val title: String
        val text: String
        val criticalText: String
        val trackerIconRes: Int
        val largeIconRes: Int
        val endIconRes: Int
        val itemDuration: Int
        val itemElapsed: Int
        val itemColor: Int

        if (currentLesson != null) {
            val lessonDuration = Duration.between(currentLesson.start, currentLesson.end).toMinutes().coerceAtLeast(1).toInt()
            val elapsed = Duration.between(currentLesson.start, now).toMinutes().coerceIn(0, lessonDuration.toLong()).toInt()
            val timeLeft = minutesRemaining(now, currentLesson.end)

            itemDuration = lessonDuration
            itemElapsed = elapsed
            itemColor = accentColor

            trackerIconRes = resolveSubjectIcon(currentLesson)
            largeIconRes = trackerIconRes
            endIconRes = R.drawable.ic_subject_break

            val prefix = if (currentLesson.lessonNumber != null) {
                val template = strings["progress_notif_lesson_title"] ?: ""
                if (template.isNotEmpty()) {
                    formatTemplate(template, "number" to currentLesson.lessonNumber.toString(), "name" to currentLesson.name)
                } else {
                    currentLesson.name
                }
            } else {
                currentLesson.name
            }
            title = prefix
            val room = currentLesson.roomName?.trim()
            val roomSuffix = if (!room.isNullOrBlank() && room != "null") "\n$room" else ""
            val subSuffix = if (!currentLesson.substituteTeacher.isNullOrBlank() && currentLesson.substituteTeacher != "null" && currentLesson.substituteTeacher != "-") {
                strings["progress_notif_substitution"] ?: ""
            } else ""
            val timeRange = "${currentLesson.start.format(hhmm)}-${currentLesson.end.format(hhmm)}"
            val templateLesson = strings["progress_notif_case2_lesson_text"] ?: ""
            text = formatTemplate(
                templateLesson,
                "minutes" to timeLeft.toString(),
                "timeRange" to timeRange,
                "room" to roomSuffix,
                "substitution" to subSuffix,
                "remaining" to remainingSuffix
            )
            val criticalTemplate = strings["progress_notif_critical_text"] ?: ""
            criticalText = formatTemplate(criticalTemplate, "minutes" to timeLeft.toString())
        } else {
            val previousLesson = lessons.lastOrNull { !now.isBefore(it.end) }
            val nextLesson = lessons.firstOrNull { it.start.isAfter(now) }
            val breakStart = previousLesson?.end ?: now
            val breakEnd = nextLesson?.start ?: lastLesson.end

            val breakDuration = Duration.between(breakStart, breakEnd).toMinutes().coerceAtLeast(1).toInt()
            val elapsed = Duration.between(breakStart, now).toMinutes().coerceIn(0, breakDuration.toLong()).toInt()
            val timeLeft = minutesRemaining(now, breakEnd)

            itemDuration = breakDuration
            itemElapsed = elapsed
            itemColor = breakColor

            trackerIconRes = R.drawable.ic_subject_break
            largeIconRes = if (nextLesson != null) resolveSubjectIcon(nextLesson) else trackerIconRes
            endIconRes = if (nextLesson != null) resolveSubjectIcon(nextLesson) else trackerIconRes

            title = strings["progress_notif_case2_break_title"] ?: ""
            val templateBreak = strings["progress_notif_case2_break_text"] ?: ""
            text = formatTemplate(
                templateBreak,
                "minutes" to timeLeft.toString(),
                "remaining" to remainingSuffix
            )
            val criticalTemplate = strings["progress_notif_critical_text"] ?: ""
            criticalText = formatTemplate(criticalTemplate, "minutes" to timeLeft.toString())
        }

        if (Build.VERSION.SDK_INT >= 36) {
            val progressStyle = Notification.ProgressStyle()
                .setProgress(itemElapsed)
                .setProgressSegments(listOf(
                    Notification.ProgressStyle.Segment(itemDuration).setColor(itemColor)
                ))
                .setProgressTrackerIcon(Icon.createWithResource(this, trackerIconRes))
                .setProgressEndIcon(Icon.createWithResource(this, endIconRes))

            val builder = Notification.Builder(this, channelId)
                .setStyle(progressStyle)
                .setContentTitle(title)
                .setContentText(text)
                .setSmallIcon(R.drawable.ic_notification)
                .setLargeIcon(Icon.createWithResource(this, largeIconRes))
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setRequestPromotedOngoing(true)
                .setShortCriticalText(criticalText.take(7))

            return builder.build()
        } else {
            return NotificationCompat.Builder(this, channelId)
                .setContentTitle(title)
                .setContentText(text)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentIntent(pendingIntent)
                .setProgress(itemDuration, itemElapsed, false)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .build()
        }
    }

    private fun resolveSubjectIcon(lesson: WidgetLesson): Int {
        if (!lesson.icon.isNullOrEmpty()) {
            val res = getSubjectIconRes(lesson.icon)
            if (res != R.drawable.ic_notification) return res
        }
        val name = lesson.name.lowercase()
        return when {
            Regex("mate(k|matika)").containsMatchIn(name) -> R.drawable.ic_subject_mathematics
            Regex("magyar nyelv|nyelvtan").containsMatchIn(name) -> R.drawable.ic_subject_grammar
            Regex("irodalom").containsMatchIn(name) -> R.drawable.ic_subject_literature
            Regex("tor(i|tenelem)").containsMatchIn(name) -> R.drawable.ic_subject_history
            Regex("foldrajz").containsMatchIn(name) -> R.drawable.ic_subject_geography
            Regex("rajz|muvtori|muveszet|vizualis").containsMatchIn(name) -> R.drawable.ic_subject_art
            Regex("fizika").containsMatchIn(name) -> R.drawable.ic_subject_physics
            Regex("^enek|zene|szolfezs|zongora|korus").containsMatchIn(name) -> R.drawable.ic_subject_music
            Regex("^tes(i|tneveles)|sport|edzeselmelet").containsMatchIn(name) -> R.drawable.ic_subject_pe
            Regex("kemia").containsMatchIn(name) -> R.drawable.ic_subject_chemistry
            Regex("biologia").containsMatchIn(name) -> R.drawable.ic_subject_biology
            Regex("angol|nemet|francia|olasz|orosz|spanyol|latin|kinai|idegen|nyelv").containsMatchIn(name) -> R.drawable.ic_subject_language
            Regex("informatika|szoftver|digitalis").containsMatchIn(name) -> R.drawable.ic_subject_it
            Regex("prog|alkalmazas").containsMatchIn(name) -> R.drawable.ic_subject_code
            Regex("halozat").containsMatchIn(name) -> R.drawable.ic_subject_networking
            Regex("filozofia").containsMatchIn(name) -> R.drawable.ic_subject_philosophy
            Regex("osztaly(fonoki|kozosseg)").containsMatchIn(name) -> R.drawable.ic_subject_ofo
            Regex("penzugy|gazdasag").containsMatchIn(name) -> R.drawable.ic_subject_economics
            Regex("kornyezet|termeszet").containsMatchIn(name) -> R.drawable.ic_subject_env
            Regex("(hit|erkolcs)tan|vallas|etika").containsMatchIn(name) -> R.drawable.ic_subject_religion
            Regex("adatbazis").containsMatchIn(name) -> R.drawable.ic_subject_database
            else -> R.drawable.ic_subject_unknown
        }
    }

    private fun getSubjectIconRes(iconName: String?): Int {
        if (iconName == null) return R.drawable.ic_subject_unknown
        return when (iconName.lowercase()) {
            "mathematics" -> R.drawable.ic_subject_mathematics
            "grammar" -> R.drawable.ic_subject_grammar
            "literature" -> R.drawable.ic_subject_literature
            "history" -> R.drawable.ic_subject_history
            "geography" -> R.drawable.ic_subject_geography
            "art" -> R.drawable.ic_subject_art
            "physics" -> R.drawable.ic_subject_physics
            "music" -> R.drawable.ic_subject_music
            "pe" -> R.drawable.ic_subject_pe
            "chemistry" -> R.drawable.ic_subject_chemistry
            "biology" -> R.drawable.ic_subject_biology
            "env" -> R.drawable.ic_subject_env
            "religion" -> R.drawable.ic_subject_religion
            "economics" -> R.drawable.ic_subject_economics
            "it" -> R.drawable.ic_subject_it
            "code" -> R.drawable.ic_subject_code
            "networking" -> R.drawable.ic_subject_networking
            "theatre" -> R.drawable.ic_subject_theatre
            "film" -> R.drawable.ic_subject_film
            "electricalengineering" -> R.drawable.ic_subject_electricalengineering
            "mechanicalengineering" -> R.drawable.ic_subject_mechanicalengineering
            "technika" -> R.drawable.ic_subject_technika
            "dance" -> R.drawable.ic_subject_dance
            "philosophy" -> R.drawable.ic_subject_philosophy
            "erettsegi" -> R.drawable.ic_subject_erettsegi
            "ofo" -> R.drawable.ic_subject_ofo
            "diligence" -> R.drawable.ic_subject_diligence
            "attitude" -> R.drawable.ic_subject_attitude
            "language" -> R.drawable.ic_subject_language
            "linux" -> R.drawable.ic_subject_linux
            "database" -> R.drawable.ic_subject_database
            "applications" -> R.drawable.ic_subject_applications
            "project" -> R.drawable.ic_subject_project
            "break" -> R.drawable.ic_subject_break
            else -> R.drawable.ic_subject_unknown
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            try {
                nm.deleteNotificationChannel("firka_progress_notification")
                nm.deleteNotificationChannel("firka_progress_notification_v2")
            } catch (_: Exception) {}

            val strings = getStrings(this)
            val channelName = strings["progress_notif_channel_name"]?.takeIf { it.isNotBlank() } ?: "Firka"
            val channelDesc = strings["progress_notif_channel_desc"] ?: ""

            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
                description = channelDesc
            }
            nm.createNotificationChannel(channel)
        }
    }

    private fun scheduleNextTransitionAlarm(targetTime: LocalDateTime) {
        val alarmManager = getSystemService(ALARM_SERVICE) as? AlarmManager ?: return
        cancelTransitionAlarm()

        val intent = Intent(this, ProgressNotificationForegroundService::class.java).apply {
            action = ACTION_UPDATE
        }
        val pendingIntent = PendingIntent.getService(
            this,
            1001,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        transitionPendingIntent = pendingIntent

        val epochMillis = targetTime.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
        if (epochMillis > System.currentTimeMillis()) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, epochMillis, pendingIntent)
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, epochMillis, pendingIntent)
                }
            } catch (e: SecurityException) {
                Log.w(TAG, "Cannot schedule transition alarm", e)
            }
        }
    }

    private fun cancelTransitionAlarm() {
        val alarmManager = getSystemService(ALARM_SERVICE) as? AlarmManager ?: return
        transitionPendingIntent?.let {
            alarmManager.cancel(it)
            transitionPendingIntent = null
        }
    }

    private fun promoteToForeground(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                notificationId,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            @Suppress("DEPRECATION")
            startForeground(notificationId, notification)
        }
        isForegroundStarted = true
        awaitingStartForeground = false
    }

    private fun stopForegroundService() {
        // Stopping before startForeground() after startForegroundService() crashes
        // with ForegroundServiceDidNotStartInTimeException. Satisfy the contract
        // with a throwaway notification; STOP_FOREGROUND_REMOVE below removes it.
        if (awaitingStartForeground && !isForegroundStarted) {
            try {
                promoteToForeground(
                    NotificationCompat.Builder(this, channelId)
                        .setSmallIcon(R.drawable.ic_notification)
                        .setSilent(true)
                        .build()
                )
            } catch (e: Exception) {
                Log.w(TAG, "Could not enter foreground before stopping", e)
            }
        }
        isRunning = false
        cancelTransitionAlarm()
        tickerJob?.cancel()
        isForegroundStarted = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun minutesRemaining(from: LocalDateTime, to: LocalDateTime): Int {
        val seconds = Duration.between(from, to).seconds
        return if (seconds <= 0) 1 else ((seconds + 59) / 60).toInt().coerceAtLeast(1)
    }

    companion object {
        private const val TAG = "ProgressNotifService"
        const val ACTION_START = "app.firka.naplo.ProgressNotificationForegroundService.START"
        const val ACTION_UPDATE = "app.firka.naplo.ProgressNotificationForegroundService.UPDATE"
        const val ACTION_STOP = "app.firka.naplo.ProgressNotificationForegroundService.STOP"

        private const val PREFS_STRINGS = "firka_progress_strings"

        @Volatile
        var isRunning: Boolean = false

        fun saveStrings(context: Context, strings: Map<String, String>) {
            val prefs = context.applicationContext.getSharedPreferences(PREFS_STRINGS, Context.MODE_PRIVATE)
            val editor = prefs.edit()
            for ((k, v) in strings) {
                editor.putString(k, v)
            }
            editor.apply()
        }

        fun getStrings(context: Context): Map<String, String> {
            val prefs = context.applicationContext.getSharedPreferences(PREFS_STRINGS, Context.MODE_PRIVATE)
            val all = prefs.all
            val result = mutableMapOf<String, String>()
            for ((k, v) in all) {
                if (v is String) {
                    result[k] = v
                }
            }
            return result
        }

        fun loadTodayTimetable(context: Context): TimetableProgressData? {
            return try {
                val appFlutter = File(context.applicationContext.dataDir, "app_flutter")
                val widgetStateFile = File(appFlutter, "widget_state.json")
                if (!widgetStateFile.exists()) return null
                val text = widgetStateFile.readText(Charsets.UTF_8)
                val json = JSONObject(text)

                val tt = json.getJSONArray("timetable")
                val allLessons = mutableListOf<WidgetLesson>()
                for (i in 0 until tt.length()) {
                    allLessons.add(WidgetLesson(tt.getJSONObject(i)))
                }

                val today = LocalDate.now()
                var todayLessons = allLessons.filter { it.start.toLocalDate() == today }
                if (todayLessons.isEmpty()) {
                    val displayDateStr = json.optString("displayDate", "")
                    if (displayDateStr.isNotEmpty()) {
                        try {
                            val displayDate = LocalDate.parse(displayDateStr)
                            todayLessons = allLessons.filter { it.start.toLocalDate() == displayDate }
                        } catch (_: Exception) {}
                    }
                }
                // Cancelled lessons don't happen, so treat their slot as a break.
                todayLessons = todayLessons.filterNot { it.isCancelled }

                val colorsObj = json.optJSONObject("colors")
                val accent = colorsObj?.optInt("accent", 0xFF4C662B.toInt()) ?: 0xFF4C662B.toInt()
                val secondary = colorsObj?.optInt("secondary", 0xFF586249.toInt()) ?: 0xFF586249.toInt()
                val language = json.optString("language", null)

                TimetableProgressData(todayLessons, accent, secondary, language)
            } catch (e: Exception) {
                Log.e(TAG, "Error reading timetable data", e)
                null
            }
        }
    }
}

data class TimetableProgressData(
    val lessons: List<WidgetLesson>,
    val accentColor: Int,
    val breakColor: Int,
    val language: String? = null,
)
