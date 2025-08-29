package app.firka.naplo.model

import app.firka.naplo.getStringOrNull
import org.json.JSONObject

class NameUid(data: JSONObject) {
    var uid: String = data.getString("Uid")
    var name: String? = data.getStringOrNull("Nev")
}
