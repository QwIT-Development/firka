package app.firka.naplo.glance

import android.appwidget.AppWidgetManager
import android.content.Context
import android.os.Bundle
import HomeWidgetGlanceWidgetReceiver
import androidx.glance.appwidget.GlanceAppWidgetManager
import kotlinx.coroutines.runBlocking

import android.content.Intent
import android.util.Log
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class TimetableWidgetReceiver : HomeWidgetGlanceWidgetReceiver<TimetableWidget>() {
    override val glanceAppWidget = TimetableWidget()

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        if (action == ACTION_REFRESH_WIDGET ||
            action == AppWidgetManager.ACTION_APPWIDGET_UPDATE ||
            action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            val pendingResult = goAsync()
            CoroutineScope(SupervisorJob() + Dispatchers.Default).launch {
                try {
                    glanceAppWidget.updateAll(context)
                } catch (e: Exception) {
                    Log.e("TimetableWidget", "Failed glanceAppWidget.updateAll from onReceive", e)
                } finally {
                    pendingResult?.finish()
                }
            }
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val pendingResult = goAsync()
        CoroutineScope(SupervisorJob() + Dispatchers.Default).launch {
            try {
                val glanceId = GlanceAppWidgetManager(context).getGlanceIdBy(appWidgetId)
                glanceAppWidget.update(context, glanceId)
            } finally {
                pendingResult?.finish()
            }
        }
    }

    companion object {
        const val ACTION_REFRESH_WIDGET = "app.firka.naplo.ACTION_REFRESH_WIDGET"
    }
}