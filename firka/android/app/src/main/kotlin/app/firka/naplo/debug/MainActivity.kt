package app.firka.naplo.debug

import android.content.ComponentName
import android.content.Intent
import android.util.Log
import android.content.pm.PackageManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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
                "set_icon" -> {
                    try {
                        val pn = context.packageName
                        val icon = call.argument<String?>("icon")
                        val icons = call.argument<String>("icons")!!.split(",")

                        if (icon != null) {
                            for (ic in icons) {
                                if (ic != icon) {
                                    Log.d("firka", "disable: $ic")
                                    packageManager.setComponentEnabledSetting(
                                        ComponentName(pn, "$pn.$ic"),
                                        PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                                        PackageManager.DONT_KILL_APP
                                    )
                                }
                            }

                            Log.d("firka", "enable: $icon")
                            packageManager.setComponentEnabledSetting(
                                ComponentName(pn, "$pn.$icon"),
                                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                                PackageManager.DONT_KILL_APP
                            )

                            Log.d("firka", "disable: MainActivity")
                            packageManager.setComponentEnabledSetting(
                                ComponentName(pn, "$pn.MainActivity"),
                                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                                0
                            )
                        } else {
                            for (ic in icons) {
                                packageManager.setComponentEnabledSetting(
                                    ComponentName(pn, "$pn.$ic"),
                                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                                    PackageManager.DONT_KILL_APP
                                )
                            }

                            packageManager.setComponentEnabledSetting(
                                ComponentName(pn, "$pn.MainActivity"),
                                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                                0
                            )
                        }

                        forceIconUpdate()
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
