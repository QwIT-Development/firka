package app.firka.naplo

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.glance.appwidget.updateAll
import app.firka.naplo.glance.TimetableWidget
import app.firka.naplo.glance.TimetableWidgetReceiver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlin.system.exitProcess

class MainActivity : FlutterActivity() {

    private val channel = "firka.app/main"
    private val wearSyncChannel = "app.firka/wear_sync"

    private fun forceIconUpdate() {
        try {
            val intent = Intent("android.intent.action.MAIN")
            intent.addCategory("android.intent.category.HOME")
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(intent)

        } catch (_: Exception) {
            Thread.sleep(2000)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, wearSyncChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "startWearSyncService" -> {
                    val args = call.arguments as? Map<*, *>
                    val cachePath = args?.get("cachePath") as? String
                    val appDirPath = args?.get("appDirPath") as? String
                    if (cachePath != null && appDirPath != null) {
                        val messenger = flutterEngine.dartExecutor.binaryMessenger
                        val ch = MethodChannel(messenger, wearSyncChannel)
                        ch.invokeMethod("getLocalizedString", "wearSyncNotificationTitle", object : MethodChannel.Result {
                            override fun success(titleResult: Any?) {
                                val title = titleResult as? String ?: "Syncing with watch"
                                ch.invokeMethod("getLocalizedString", "wearSyncNotificationText", object : MethodChannel.Result {
                                    override fun success(textResult: Any?) {
                                        val text = textResult as? String ?: ""
                                        val intent = Intent(this@MainActivity, WearSyncForegroundService::class.java).apply {
                                            action = WearSyncForegroundService.ACTION_START
                                            putExtra(WearSyncForegroundService.EXTRA_CACHE_PATH, cachePath)
                                            putExtra(WearSyncForegroundService.EXTRA_APP_DIR_PATH, appDirPath)
                                            putExtra(WearSyncForegroundService.EXTRA_NOTIFICATION_TITLE, title)
                                            putExtra(WearSyncForegroundService.EXTRA_NOTIFICATION_TEXT, text)
                                        }
                                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                            startForegroundService(intent)
                                        } else {
                                            startService(intent)
                                        }
                                        result.success(null)
                                    }
                                    override fun error(code: String, msg: String?, details: Any?) { result.success(null) }
                                    override fun notImplemented() { result.success(null) }
                                })
                            }
                            override fun error(code: String, msg: String?, details: Any?) { result.error(code, msg, details) }
                            override fun notImplemented() { result.notImplemented() }
                        })
                    } else {
                        result.error("INVALID_ARGS", "cachePath and appDirPath required", null)
                    }
                }
                "stopWearSyncService" -> {
                    val intent = Intent(this, WearSyncForegroundService::class.java).apply {
                        action = WearSyncForegroundService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler {
                call, result ->
            when (call.method) {
                "get_info" -> {
                    result.success("${Build.MODEL};" +
                            "${Build.VERSION.RELEASE};" +
                            "${Build.VERSION.SDK_INT}")
                }
                "set_icon" -> {
                    try {
                        val pn = context.packageName
                        if (pn.endsWith(".debug")) {
                            result.success(true)
                            return@setMethodCallHandler
                        }
                        val icon = call.argument<String?>("icon")
                        val icons = call.argument<String>("icons")!!.split(",")

                        if (icon != null) {
                            for (ic in icons) {
                                if (ic != icon) {
                                    Log.d("firka", "Disabling activity: $pn.$ic")
                                    packageManager.setComponentEnabledSetting(
                                        ComponentName(pn, "$pn.$ic"),
                                        PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                                        PackageManager.DONT_KILL_APP
                                    )
                                }
                            }

                            Log.d("firka", "Enabling acitvity: $pn.$icon")
                            packageManager.setComponentEnabledSetting(
                                ComponentName(pn, "$pn.$icon"),
                                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                                PackageManager.DONT_KILL_APP
                            )

                            Log.d("firka" ,"Disabling activity: $pn.MainActivity")
                            packageManager.setComponentEnabledSetting(
                                ComponentName(pn, "$pn.MainActivity"),
                                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                                PackageManager.DONT_KILL_APP
                            )
                        } else {
                            for (ic in icons) {
                                Log.d("firka", "Disabling activity: $pn.$ic")
                                packageManager.setComponentEnabledSetting(
                                    ComponentName(pn, "$pn.$ic"),
                                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                                    PackageManager.DONT_KILL_APP
                                )
                            }

                            Log.d("firka", "Enabling acitvity: $pn.MainActivity")
                            packageManager.setComponentEnabledSetting(
                                ComponentName(pn, "$pn.MainActivity"),
                                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                                PackageManager.DONT_KILL_APP
                            )
                        }

                        forceIconUpdate()

                        exitProcess(-1)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                        result.success(true)
                }
                "refreshTimetableWidget" -> {
                    CoroutineScope(SupervisorJob() + Dispatchers.Default).launch {
                        try {
                            val appContext = context.applicationContext
                            val appWidgetManager = AppWidgetManager.getInstance(appContext)
                            val componentName = ComponentName(appContext, TimetableWidgetReceiver::class.java)
                            val ids = appWidgetManager.getAppWidgetIds(componentName)
                            if (ids.isNotEmpty()) {
                                val intent = Intent(appContext, TimetableWidgetReceiver::class.java).apply {
                                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                                    addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
                                }
                                appContext.sendBroadcast(intent)
                            }
                            TimetableWidget().updateAll(appContext)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("refresh_failed", e.message, null)
                        }
                    }
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
