package app.firka.naplo.model

import androidx.compose.ui.graphics.Color
import org.json.JSONObject

class Colors(widgetState: JSONObject) {
    var background: Color = Color(widgetState.getJSONObject("colors").getInt("background"))
    var backgroundAmoled: Color =
        Color(widgetState.getJSONObject("colors").getInt("backgroundAmoled"))
    var background0p: Color = Color(widgetState.getJSONObject("colors").getInt("background0p"))
    var success: Color = Color(widgetState.getJSONObject("colors").getInt("success"))
    var textPrimary: Color = Color(widgetState.getJSONObject("colors").getInt("textPrimary"))
    var textSecondary: Color = Color(widgetState.getJSONObject("colors").getInt("textSecondary"))
    var textTertiary: Color = Color(widgetState.getJSONObject("colors").getInt("textTertiary"))
    var card: Color = Color(widgetState.getJSONObject("colors").getInt("card"))
    var cardTranslucent: Color =
        Color(widgetState.getJSONObject("colors").getInt("cardTranslucent"))
    var buttonSecondaryFill: Color =
        Color(widgetState.getJSONObject("colors").getInt("buttonSecondaryFill"))
    var accent: Color = Color(widgetState.getJSONObject("colors").getInt("accent"))
    var secondary: Color = Color(widgetState.getJSONObject("colors").getInt("secondary"))
    var shadowColor: Color = Color(widgetState.getJSONObject("colors").getInt("shadowColor"))
    var a15p: Color = Color(widgetState.getJSONObject("colors").getInt("a15p"))
    var warningAccent: Color = Color(widgetState.getJSONObject("colors").getInt("warningAccent"))
    var warningText: Color = Color(widgetState.getJSONObject("colors").getInt("warningText"))
    var warning15p: Color = Color(widgetState.getJSONObject("colors").getInt("warning15p"))
    var warningCard: Color = Color(widgetState.getJSONObject("colors").getInt("warningCard"))
    var errorAccent: Color = Color(widgetState.getJSONObject("colors").getInt("errorAccent"))
    var errorText: Color = Color(widgetState.getJSONObject("colors").getInt("errorText"))
    var error15p: Color = Color(widgetState.getJSONObject("colors").getInt("error15p"))
    var errorCard: Color = Color(widgetState.getJSONObject("colors").getInt("errorCard"))
    var grade5: Color = Color(widgetState.getJSONObject("colors").getInt("grade5"))
    var grade4: Color = Color(widgetState.getJSONObject("colors").getInt("grade4"))
    var grade3: Color = Color(widgetState.getJSONObject("colors").getInt("grade3"))
    var grade2: Color = Color(widgetState.getJSONObject("colors").getInt("grade2"))
    var grade1: Color = Color(widgetState.getJSONObject("colors").getInt("grade1"))
}