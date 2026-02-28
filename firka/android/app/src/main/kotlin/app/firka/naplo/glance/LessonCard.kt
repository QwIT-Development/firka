package app.firka.naplo.glance

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.color.ColorProvider
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import app.firka.naplo.model.Colors
import app.firka.naplo.glance.WidgetLesson
import java.time.format.DateTimeFormatterBuilder

val hhmm = DateTimeFormatterBuilder()
    .appendPattern("HH:mm")
    .toFormatter()

@Composable
fun LessonCard(
    lesson: WidgetLesson,
    colors: Colors,
    modifier: GlanceModifier = GlanceModifier,
    roomBadgeWidthDp: Float = 48f,
) {
    Box(modifier =
        modifier
            .fillMaxWidth()
            .padding(4.dp, 0.dp)
            .cornerRadius(16.dp)
            .background(colors.card)
    ) {
        var bgColor = colors.a15p
        var fgColor = colors.textSecondary

        if (lesson.substituteTeacher != null) {
            bgColor = colors.warning15p
            fgColor = colors.warningText
        }


        Box(modifier = GlanceModifier.padding(12.dp)) {
            Row {
                val badgeStyle = TextStyle(
                    color = ColorProvider(colors.textSecondary, colors.textSecondary),
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold
                )
                val badgePadding = GlanceModifier.padding(8.dp, 4.dp)
                val lessonNumberBadgeModifier = GlanceModifier.cornerRadius(16.dp).width(24.dp)
                val roomBadgeModifier = GlanceModifier.cornerRadius(16.dp).width(roomBadgeWidthDp.dp)

                Row(modifier = GlanceModifier.width(226.dp), verticalAlignment = Alignment.CenterVertically) {
                    if (lesson.lessonNumber != null) {
                        Box(
                            modifier = lessonNumberBadgeModifier.background(bgColor),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(
                                lesson.lessonNumber.toString(),
                                style = TextStyle(
                                    color = ColorProvider(fgColor, fgColor),
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Bold
                                ),
                                modifier = GlanceModifier.padding(4.dp, 4.dp),
                            )
                        }
                        Spacer(modifier = GlanceModifier.width(4.dp))
                    }
                    // TODO: Add subject icons
                    Text(
                        lesson.name,
                        style = TextStyle(
                            color = ColorProvider(colors.textPrimary, colors.textPrimary),
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold
                        ),
                    )
                }

                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        lesson.start.format(hhmm),
                        style = TextStyle(
                            color = ColorProvider(colors.textPrimary, colors.textPrimary),
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold
                        ),
                    )
                    Spacer(modifier = GlanceModifier.width(8.dp))
                    val roomName = (lesson.roomName ?: "N/A").take(5)
                    Box(
                        modifier = roomBadgeModifier.background(colors.a15p),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            roomName,
                            style = badgeStyle,
                            modifier = GlanceModifier.padding(4.dp, 4.dp),
                        )
                    }
                }
            }
        }
    }
}