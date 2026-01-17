package com.vkqnclawnn.harudat

import org.json.JSONObject


data class HaruDotData(
  val name: String,
  val dDayText: String,
  val dateText: String,
  val totalDots: Int,
  val burnedDots: Int,
  val progressPercent: Double,
  val colorPast: String,
  val colorToday: String,
  val backgroundColor: String,
  val isWidgetDark: Boolean
) {
  companion object {
    fun fromJson(jsonString: String?): HaruDotData? {
      if (jsonString.isNullOrBlank()) return null
      val json = JSONObject(jsonString)
      return HaruDotData(
        name = json.optString("name", ""),
        dDayText = json.optString("dDayText", ""),
        dateText = json.optString("dateText", json.optString("dateRangeText", "")),
        totalDots = json.optInt("totalDots", 0),
        burnedDots = json.optInt("burnedDots", 0),
        progressPercent = json.optDouble("progressPercent", 0.0),
        colorPast = json.optString("colorPast", "#66BB6A"),
        colorToday = json.optString("colorToday", "#4CAF50"),
        backgroundColor = json.optString("backgroundColor", "#FFFFFF"),
        isWidgetDark = json.optBoolean("isWidgetDark", false)
      )
    }
  }
}
