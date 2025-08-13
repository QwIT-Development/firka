package app.firka.naplo.model

import app.firka.naplo.getNameUidDescOrNull
import app.firka.naplo.getStringOrNull
import org.json.JSONObject

class Subject(data: JSONObject) {
    var uid: String? = data.getStringOrNull("Uid")
    var name: String? = data.getStringOrNull("Nev")
    var category: NameUidDesc? = data.getNameUidDescOrNull("Kategoria")
    var sortIndex: Int = data.getInt("SortIndex")
}