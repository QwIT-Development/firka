package app.firka.naplo.glance

import app.firka.naplo.getIntOrNull
import app.firka.naplo.getStringOrNull
import org.json.JSONObject
import java.time.LocalDateTime
import java.time.OffsetDateTime
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeFormatterBuilder
import java.time.temporal.ChronoField

class WidgetLesson(data: JSONObject) {
    companion object {
        private val formatter: DateTimeFormatter = DateTimeFormatterBuilder()
            .appendPattern("yyyy-MM-dd'T'HH:mm:ss")
            .optionalStart()
            .appendFraction(ChronoField.NANO_OF_SECOND, 1, 9, true)
            .optionalEnd()
            .optionalStart()
            .appendLiteral('Z')
            .optionalEnd()
            .optionalStart()
            .appendOffset("+HH:MM", "+00:00")
            .optionalEnd()
            .toFormatter()

        fun parseDateTime(raw: String): LocalDateTime {
            return try {
                LocalDateTime.parse(raw, formatter)
            } catch (_: Exception) {
                try {
                    OffsetDateTime.parse(raw).toLocalDateTime()
                } catch (_: Exception) {
                    LocalDateTime.parse(raw)
                }
            }
        }
    }

    val name: String = data.optString("name", data.optString("Nev", ""))
    val start: LocalDateTime = parseDateTime(data.optString("start", data.optString("KezdetIdopont", "")))
    val end: LocalDateTime = parseDateTime(data.optString("end", data.optString("VegIdopont", "")))
    val lessonNumber: Int? = data.getIntOrNull("dailyNth") ?: data.getIntOrNull("Oraszam")
    val roomName: String? = data.getStringOrNull("roomName") ?: data.getStringOrNull("TeremNeve")
    val substituteTeacher: String? = data.getStringOrNull("substituteTeacher") ?: data.getStringOrNull("HelyettesTanarNeve")
}
