package app.firka.naplo

import app.firka.naplo.model.NameUid
import app.firka.naplo.model.NameUidDesc
import app.firka.naplo.model.Subject
import org.json.JSONObject

fun JSONObject.getStringOrNull(key: String): String? {
    return try {
        if (has(key)) {
            getString(key)
        } else {
            null
        }
    } catch (_: Exception) {
        null
    }
}

fun JSONObject.getIntOrNull(key: String): Int? {
    return try {
        if (has(key)) {
            getInt(key)
        } else {
            null
        }
    } catch (_: Exception) {
        null
    }
}

fun JSONObject.getNameUidDescOrNull(key: String): NameUidDesc? {
    try {
        return if (has(key)) {
            NameUidDesc(getJSONObject(key))
        } else {
            null
    }
        } catch (_: Exception) {
            return null
        }
}

fun JSONObject.getNameUidOrNull(key: String): NameUid? {
    try {
        return if (has(key)) {
            NameUid(getJSONObject(key))
        } else {
        null
    }
        } catch (_: Exception) {
            return null
        }
}

fun JSONObject.getSubjectOrNull(key: String): Subject? {
    return try {
        if (has(key)) {
            Subject(getJSONObject(key))
        } else {
            null
        }
    } catch (_: Exception) {
        null
    }
}