package app.firka.naplo.glance

import android.appwidget.AppWidgetManager
import android.content.Context
import android.os.Bundle
import HomeWidgetGlanceWidgetReceiver
import androidx.glance.appwidget.GlanceAppWidgetManager
import kotlinx.coroutines.runBlocking

class TimetableWidgetReceiver : HomeWidgetGlanceWidgetReceiver<TimetableWidget>() {
    override val glanceAppWidget = TimetableWidget()

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        runBlocking {
            val glanceId = GlanceAppWidgetManager(context).getGlanceIdBy(appWidgetId)
            glanceAppWidget.update(context, glanceId)
        }
    }
}