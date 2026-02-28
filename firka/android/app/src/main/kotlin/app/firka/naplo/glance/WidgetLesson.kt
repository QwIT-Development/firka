package app.firka.naplo.glance

import app.firka.naplo.getIntOrNull
import app.firka.naplo.getStringOrNull
import org.json.JSONObject
import java.time.LocalDateTime
import java.time.format.DateTimeFormatterBuilder

class WidgetLesson(data: JSONObject) {
    val formatter = DateTimeFormatterBuilder()
        .appendPattern("yyyy-MM-dd'T'HH:mm:ss.SSS")
        .optionalStart()
        .appendLiteral('Z')
        .optionalEnd()
        .toFormatter()

    val name: String = data.getString("Nev")
    val start: LocalDateTime = LocalDateTime.parse(data.getString("KezdetIdopont"), formatter)
    val end: LocalDateTime = LocalDateTime.parse(data.getString("VegIdopont"), formatter)
    val lessonNumber: Int? = data.getIntOrNull("Oraszam")
    val roomName: String? = data.getStringOrNull("TeremNeve")
    val substituteTeacher: String? = data.getStringOrNull("HelyettesTanarNeve")
}
