package app.firka.naplo

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.core.app.NotificationCompat
import androidx.wear.ongoing.OngoingActivity
import androidx.wear.ongoing.Status
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {

    private val channel = "firka.app/main"
    private val channelId = "ongoing_activity"
    private val notificationId = 1000

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager

        notificationManager.createNotificationChannel(
            NotificationChannel(
                channelId,
                "Ongoing Activity",
                NotificationManager.IMPORTANCE_DEFAULT
            )
        )

        val notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)

        val ongoingActivityStatus = Status.Builder()
            // Sets the text used across various surfaces.
            .addTemplate("Firka")
            .build()

        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)!!
        val activityPendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val ongoingActivity = OngoingActivity.Builder(applicationContext,
            notificationId, notificationBuilder)
            .setStaticIcon(R.drawable.ic_notification)
            .setTouchIntent(activityPendingIntent)
            .setStatus(ongoingActivityStatus)
            .build()

        ongoingActivity.apply(applicationContext)


        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler {
                call, result ->
            when (call.method) {
                "isWear" -> {
                    result.success(packageManager.hasSystemFeature(PackageManager.FEATURE_WATCH))
                }
                "activity_update" -> {
                    notificationManager.notify(notificationId, notificationBuilder.build())
                    result.success(null)
                }
                "activity_cancel" -> {
                    notificationManager.cancel(notificationId)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
    }

}
