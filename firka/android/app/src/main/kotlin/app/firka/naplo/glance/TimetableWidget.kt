package app.firka.naplo.glance

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.color.ColorProvider
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import app.firka.naplo.model.Colors
import app.firka.naplo.model.Lesson
import org.json.JSONObject
import java.io.File
import java.time.LocalDate
import java.time.LocalDateTime

class TimetableWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>?
        get() = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceContent(context, currentState())
        }
    }

    @Composable
    private fun GlanceContent(context: Context, currentState: HomeWidgetGlanceState) {
        val appFlutter = File(context.applicationContext.dataDir, "app_flutter")
        val widgetStateFile = File(appFlutter, "widget_state.json")

        if (!widgetStateFile.exists()) {
            Box(modifier =
                GlanceModifier
                    .background(Color(0xFFFAFFF0))
                    .padding(16.dp)
                    .fillMaxSize(),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    "Widget használata előtt jelentkezz be",
                    style = TextStyle(
                        color = ColorProvider(Color(0xFF394C0A), Color(0xFF394C0A)),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium
                    )
                )
            }

            return
        }

        val widgetState = JSONObject(widgetStateFile.readText(Charsets.UTF_8))
        val colors = Colors(widgetState)

        val tt = widgetState.getJSONArray("timetable")
        var lessons = mutableListOf<Lesson>()

        for (i in 0..<tt.length()) {
            lessons.add(Lesson(tt.getJSONObject(i)))
        }

        val now = LocalDate.now()
        val start = LocalDateTime.of(now.year, now.month, now.dayOfMonth, 0, 0)
        val end = start.plusHours(23)
        lessons = lessons.filter { lesson -> lesson.start.isAfter(start) && lesson.end.isBefore(end) }.toMutableList()

        Box(modifier =
            GlanceModifier
                .background(colors.background)
                .padding(16.dp)
                .fillMaxSize()
        ) {
            Column {
                Text(
                    "Mai órarend",
                    style = TextStyle(
                        color = ColorProvider(colors.textSecondary, colors.textSecondary),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium
                    )
                )
                Spacer(modifier = GlanceModifier.height(4.dp))
                for (lesson in lessons) {
                    LessonCard(lesson, colors)
                    Spacer(modifier = GlanceModifier.height(4.dp))
                }
            }
        }
    }

}