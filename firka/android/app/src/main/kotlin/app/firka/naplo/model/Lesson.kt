package app.firka.naplo.model

import app.firka.naplo.getIntOrNull
import app.firka.naplo.getNameUidDescOrNull
import app.firka.naplo.getNameUidOrNull
import app.firka.naplo.getStringOrNull
import app.firka.naplo.getSubjectOrNull
import org.json.JSONObject
import java.time.LocalDateTime
import java.time.format.DateTimeFormatterBuilder

class Lesson {
    val formatter = DateTimeFormatterBuilder()
        .appendPattern("yyyy-MM-dd'T'HH:mm:ss.SSS")
        .optionalStart()
        .appendLiteral('Z')
        .optionalEnd()
        .toFormatter()

    constructor(data: JSONObject) {
        uid = data.getString("Uid")
        date = data.getString("Datum")
        start = LocalDateTime.parse(data.getString("KezdetIdopont"), formatter)
        end = LocalDateTime.parse(data.getString("VegIdopont"), formatter)
        name = data.getString("Nev")
        lessonNumber = data.getIntOrNull("Oraszam")
        lessonSeqNumber = data.getIntOrNull("OraEvesSorszama")
        classGroup = data.getNameUidOrNull("OsztalyCsoport")
        teacher = data.getStringOrNull("TanarNeve")
        subject = data.getSubjectOrNull("Tantargy")
        theme = data.getStringOrNull("Tema")
        roomName = data.getStringOrNull("TeremNeve")
        type = NameUidDesc(data.getJSONObject("Tipus"))
        studentPresence = data.getNameUidDescOrNull("TanuloJelenlet")
        state = NameUidDesc(data.getJSONObject("Allapot"))
        substituteTeacher = data.getStringOrNull("HelyettesTanarNeve")
        homeworkUid = data.getStringOrNull("HaziFeladatUid")
        taskGroupUid = data.getStringOrNull("FeladatGroupUid")
        languageTaskGroupUid = data.getStringOrNull("NyelviFeladatGroupUid")
        assessmentUid = data.getStringOrNull("BejelentettSzamonkeresUid")
        canStudentEditHomework = data.getBoolean("IsTanuloHaziFeladatEnabled")
        isHomeworkComplete = data.getBoolean("IsHaziFeladatMegoldva")
        if (data.has("Csatolmanyok")) {
            val rawAttachments = data.getJSONArray("Csatolmanyok")

            for (i in 0..<rawAttachments.length()) {
                attachments.add(NameUid(rawAttachments.getJSONObject(i)))
            }
        }
        isDigitalLesson = data.getBoolean("IsDigitalisOra")
        digitalDeviceList = data.getStringOrNull("DigitalisEszkozTipus")
        digitalPlatformType = data.getStringOrNull("DigitalisPlatformTipus")
        if (data.has("DigitalisTamogatoEszkozTipusList")) {
            val rawDigitalSupportDeviceTypeList =
                data.getJSONArray("DigitalisTamogatoEszkozTipusList")

            for (i in 0..<rawDigitalSupportDeviceTypeList.length()) {
                digitalSupportDeviceTypeList.add(rawDigitalSupportDeviceTypeList.getString(i))
            }
        }
        createdAt = LocalDateTime.parse(data.getString("Letrehozas"), formatter)
        lastModifiedAt = LocalDateTime.parse(data.getString("UtolsoModositas"), formatter)
    }

    var uid: String;
    var date: String;
    var start: LocalDateTime;
    var end: LocalDateTime;
    var name: String;
    var lessonNumber: Int?;
    var lessonSeqNumber: Int?;
    var classGroup: NameUid?;
    var teacher: String?;
    var subject: Subject?;
    var theme: String?;
    var roomName: String?;
    var type: NameUidDesc;
    var studentPresence: NameUidDesc?;
    var state: NameUidDesc;
    var substituteTeacher: String?;
    var homeworkUid: String?;
    var taskGroupUid: String?;
    var languageTaskGroupUid: String?;
    var assessmentUid: String?;
    var canStudentEditHomework: Boolean;
    var isHomeworkComplete: Boolean;
    var attachments = mutableListOf<NameUid>()
    var isDigitalLesson: Boolean
    var digitalDeviceList: String?
    var digitalPlatformType: String?
    var digitalSupportDeviceTypeList = mutableListOf<String>()
    var createdAt: LocalDateTime
    var lastModifiedAt: LocalDateTime
}