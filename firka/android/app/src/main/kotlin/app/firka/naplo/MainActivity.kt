package app.firka.naplo

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.system.exitProcess

class MainActivity : FlutterActivity() {

    private val channel = "firka.app/main"

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
