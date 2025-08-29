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
import app.firka.naplo.model.Lesson
import java.time.format.DateTimeFormatterBuilder

val hhmm = DateTimeFormatterBuilder()
    .appendPattern("HH:mm")
    .toFormatter()

@Composable
fun LessonCard(lesson: Lesson, colors: Colors,
               modifier: GlanceModifier = GlanceModifier) {
    Box(modifier =
        modifier
            .fillMaxWidth()
            .padding(4.dp, 0.dp)
            .cornerRadius(16.dp)
            .background(colors.card)
    ) {
        var bgColor = colors.a15p
        var fgColor = colors.textSecondary

        if (lesson.substituteTeacher == null) {
            bgColor = colors.warning15p
            fgColor = colors.warningText
        }


        Box(modifier = GlanceModifier.padding(12.dp)) {
            Row {
                Row(modifier = GlanceModifier.width(226.dp), verticalAlignment = Alignment.CenterVertically) {
                    if (lesson.lessonNumber != null) {
                        Box(modifier = GlanceModifier.cornerRadius(16.dp).background(bgColor)) {
                            Text(
                                lesson.lessonNumber.toString(),
                                style = TextStyle(
                                    color = ColorProvider(fgColor, fgColor),
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Bold
                                ),
                                modifier = GlanceModifier.padding(8.dp, 4.dp),
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

                // Spacer(modifier = GlanceModifier.width(10.dp))

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
                    Box(modifier = GlanceModifier.cornerRadius(16.dp).background(colors.a15p)) {
                        var roomName = "N/A";
                        if (lesson.roomName != null) {
                            roomName = lesson.roomName!!;
                        }

                        if (roomName.length < 2) {
                            roomName = " $roomName"
                        }

                        Text(
                            roomName,
                            style = TextStyle(
                                color = ColorProvider(colors.textSecondary, colors.textSecondary),
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold
                            ),
                            modifier = GlanceModifier.padding(8.dp, 4.dp),
                        )
                    }
                }
            }
        }
    }
}