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
import androidx.glance.LocalSize
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.SizeMode
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
import app.firka.naplo.glance.WidgetLesson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.File
import java.time.LocalDate
import java.time.LocalDateTime

class TimetableWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>?
        get() = HomeWidgetGlanceStateDefinition()

    override val sizeMode: SizeMode
        get() = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val data = withContext(Dispatchers.IO) {
            loadWidgetData(context)
        }
        provideContent {
            GlanceContent(context, currentState(), data)
        }
    }

    private fun loadWidgetData(context: Context): WidgetData? {
        val appFlutter = File(context.applicationContext.dataDir, "app_flutter")
        val widgetStateFile = File(appFlutter, "widget_state.json")
        if (!widgetStateFile.exists()) return null
        val widgetState = JSONObject(widgetStateFile.readText(Charsets.UTF_8))
        val colors = Colors(widgetState)
        val tt = widgetState.getJSONArray("timetable")
        val lessons = mutableListOf<WidgetLesson>()
        for (i in 0..<tt.length()) {
            lessons.add(WidgetLesson(tt.getJSONObject(i)))
        }
        val displayDateStr = widgetState.optString("displayDate", "")
        val targetDate = if (displayDateStr.isNotEmpty()) {
            try {
                LocalDate.parse(displayDateStr)
            } catch (_: Exception) {
                LocalDate.now()
            }
        } else {
            LocalDate.now()
        }
        val start = LocalDateTime.of(targetDate.year, targetDate.month, targetDate.dayOfMonth, 0, 0)
        val end = start.plusHours(23)
        val filtered = lessons.filter { it.start.isAfter(start) && it.end.isBefore(end) }
        val headerText = if (displayDateStr.isNotEmpty()) displayDateStr else "Mai órarend"
        return WidgetData(colors, headerText, filtered)
    }

    @Composable
    private fun GlanceContent(context: Context, currentState: HomeWidgetGlanceState, data: WidgetData?) {
        if (data == null) {
            Box(
                modifier = GlanceModifier
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

        val size = LocalSize.current
        val lessonRowHeightDp = 52f
        val scale = lessonRowHeightDp / 52f
        val headerHeightDp = 20f * scale
        val verticalPaddingDp = 32f * scale
        val spacerDp = 4f * scale
        val paddingDp = 16f * scale
        val availableHeightDp = size.height.value - verticalPaddingDp - headerHeightDp - spacerDp
        val maxVisibleLessons = (availableHeightDp / lessonRowHeightDp).toInt().coerceAtLeast(0)
        val maxLessons = (maxVisibleLessons.coerceAtMost(16) / 2 * 2).coerceAtLeast(1)
        val displayLessons = data.lessons.take(maxLessons)
        val lessonChunks = displayLessons.chunked(2)
        val showDate = maxLessons > 1
        val roomBadgeWidthDp = 48f
        val minWidthForTimeAndChipDp = 8f + 40f + roomBadgeWidthDp
        val subjectColumnWidthDp = (size.width.value - 2 * paddingDp - 32f - minWidthForTimeAndChipDp)
            .coerceIn(80f, 226f)
        val dateSectionHeight = if (showDate) headerHeightDp + spacerDp else 0f
        val lessonListHeight = when (val n = displayLessons.size) {
            0 -> 0f
            else -> n * lessonRowHeightDp + (n - 1) * spacerDp
        }
        val remainingHeight = (size.height.value - 2 * paddingDp - dateSectionHeight - lessonListHeight).coerceAtLeast(0f)
        val verticalPaddingAroundLessons = remainingHeight / 2f

        Box(
            modifier = GlanceModifier
                .background(data.colors.background)
                .padding(paddingDp.dp)
                .fillMaxSize()
        ) {
            Column {
                if (showDate) {
                    Text(
                        data.headerText,
                        style = TextStyle(
                            color = ColorProvider(data.colors.textSecondary, data.colors.textSecondary),
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium
                        )
                    )
                    Spacer(modifier = GlanceModifier.height(spacerDp.dp))
                }
                Spacer(modifier = GlanceModifier.height(verticalPaddingAroundLessons.dp))
                for (chunk in lessonChunks) {
                    Column {
                        for (lesson in chunk) {
                            LessonCard(
                                lesson,
                                data.colors,
                                roomBadgeWidthDp = roomBadgeWidthDp,
                                subjectColumnWidthDp = subjectColumnWidthDp,
                            )
                            Spacer(modifier = GlanceModifier.height(spacerDp.dp))
                        }
                    }
                }
                Spacer(modifier = GlanceModifier.height(verticalPaddingAroundLessons.dp))
            }
        }
    }
}

private data class WidgetData(
    val colors: Colors,
    val headerText: String,
    val lessons: List<WidgetLesson>,
)