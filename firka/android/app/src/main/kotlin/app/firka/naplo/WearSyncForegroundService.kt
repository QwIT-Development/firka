package app.firka.naplo

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.ByteArrayInputStream
import java.io.ObjectInputStream
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.delay

/**
 * Foreground service that keeps the app able to respond to Wear OS sync requests.
 * When the watch sends request_sync, starts a Dart background isolate to fetch data,
 * then reads the cache file and sends sync_data to the watch.
 */
class WearSyncForegroundService : Service(), MessageClient.OnMessageReceivedListener {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private var cachePath: String? = null
    private var appDirPath: String? = null

    private val channelId = "firka_wear_sync"
    private val notificationId = 4001
    private var notificationTitle: String = "Syncing with watch"
    private var notificationText: String = ""

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                cachePath = intent.getStringExtra(EXTRA_CACHE_PATH)
                appDirPath = intent.getStringExtra(EXTRA_APP_DIR_PATH)
                notificationTitle = intent.getStringExtra(EXTRA_NOTIFICATION_TITLE) ?: "Syncing with watch"
                notificationText = intent.getStringExtra(EXTRA_NOTIFICATION_TEXT) ?: ""
                startForegroundWithNotification()
                Wearable.getMessageClient(this@WearSyncForegroundService)
                    .addListener(this@WearSyncForegroundService)
            }
            ACTION_STOP -> {
                stopForegroundService()
                return START_NOT_STICKY
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        try {
            Wearable.getMessageClient(this@WearSyncForegroundService)
                .removeListener(this@WearSyncForegroundService)
                .addOnCompleteListener { }
        } catch (_: Exception) { }
        scope.cancel()
        super.onDestroy()
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        if (messageEvent.path != PATH_WATCH_CONNECTIVITY ||
            !isRequestSyncPayload(messageEvent.data)
        ) return
        val cPath = cachePath
        val aPath = appDirPath
        if (cPath == null || aPath == null) return
        scope.launch {
            runSyncInBackground(cPath, aPath)
        }
    }

    /**
     * watch_connectivity plugin sends with path "watch_connectivity" and serializes the message
     * map with Java ObjectOutputStream. Parse payload and check for id == "request_sync".
     */
    private fun isRequestSyncPayload(data: ByteArray?): Boolean {
        if (data == null || data.isEmpty()) return false
        return try {
            ObjectInputStream(ByteArrayInputStream(data)).use { ois ->
                val map = ois.readObject()
                if (map is Map<*, *>) map["id"] == "request_sync" else false
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun startForegroundWithNotification() {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(notificationId, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            @Suppress("DEPRECATION")
            startForeground(notificationId, notification)
        }
    }

    private fun buildNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, channelId)
            .setContentTitle(notificationTitle)
            .setContentText(notificationText)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Wear sync",
                NotificationManager.IMPORTANCE_LOW
            ).apply { setShowBadge(false) }
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }

    private fun stopForegroundService() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private suspend fun runSyncInBackground(cPath: String, aPath: String) = withContext(Dispatchers.Default) {
        val flutterLoader = FlutterLoader()
        if (!flutterLoader.initialized()) {
            withContext(Dispatchers.Main) {
                flutterLoader.startInitialization(applicationContext)
                flutterLoader.ensureInitializationComplete(applicationContext, null)
            }
        }
        val (engine, bgChannel) = withContext(Dispatchers.Main) {
            val eng = FlutterEngine(applicationContext)
            val entrypoint = DartExecutor.DartEntrypoint(
                flutterLoader.findAppBundlePath(),
                "package:firka/services/wear_sync_background.dart",
                "wearSyncBackgroundEntrypoint"
            )
            eng.dartExecutor.executeDartEntrypoint(entrypoint)
            val ch = MethodChannel(eng.dartExecutor.binaryMessenger, "app.firka/wear_sync_background")
            Pair(eng, ch)
        }
        val completer = CompletableDeferred<Unit>()
        delay(500)
        withContext(Dispatchers.Main) {
            bgChannel.invokeMethod("request_sync", mapOf(
                "cachePath" to cPath,
                "appDirPath" to aPath
            ), object : MethodChannel.Result {
                override fun success(result: Any?) {
                    completer.complete(Unit)
                }
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    Log.e(TAG, "request_sync error: $errorCode $errorMessage")
                    completer.complete(Unit)
                }
                override fun notImplemented() {
                    completer.complete(Unit)
                }
            })
        }
        try {
            withTimeout(30_000) {
                completer.await()
            }
        } catch (_: kotlinx.coroutines.TimeoutCancellationException) {
            Log.w(TAG, "Wear sync isolate timed out")
        }
        withContext(Dispatchers.Main) {
            engine.destroy()
        }
    }

    companion object {
        private const val TAG = "WearSyncService"
        const val ACTION_START = "app.firka.naplo.WearSyncForegroundService.START"
        const val ACTION_STOP = "app.firka.naplo.WearSyncForegroundService.STOP"
        const val EXTRA_CACHE_PATH = "cachePath"
        const val EXTRA_APP_DIR_PATH = "appDirPath"
        const val EXTRA_NOTIFICATION_TITLE = "notificationTitle"
        const val EXTRA_NOTIFICATION_TEXT = "notificationText"
        private const val PATH_WATCH_CONNECTIVITY = "watch_connectivity"
    }
}
