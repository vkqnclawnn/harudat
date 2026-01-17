package com.vkqnclawnn.harudat

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Bundle
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class FullWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    widgetData: SharedPreferences
  ) {
    appWidgetIds.forEach { appWidgetId ->
      val views = RemoteViews(context.packageName, R.layout.widget_layout_full)
      val bitmap = loadWidgetBitmap(context, "widget_full_image")

      if (bitmap != null) {
        views.setImageViewBitmap(R.id.widget_image_full, bitmap)
      } else {
        views.setImageViewResource(R.id.widget_image_full, R.mipmap.ic_launcher)
      }

      appWidgetManager.updateAppWidget(appWidgetId, views)
    }
  }

  override fun onAppWidgetOptionsChanged(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    newOptions: Bundle
  ) {
    onUpdate(
      context,
      appWidgetManager,
      intArrayOf(appWidgetId),
      context.getSharedPreferences("home_widget", Context.MODE_PRIVATE)
    )
  }

  private fun loadWidgetBitmap(context: Context, key: String): Bitmap? {
    val candidates = listOf(
      File(context.cacheDir, "$key.png"),
      File(context.filesDir, "$key.png"),
      File(File(context.filesDir, "home_widget"), "$key.png"),
      File(File(context.cacheDir, "home_widget"), "$key.png")
    )

    for (file in candidates) {
      if (file.exists()) {
        val bitmap = BitmapFactory.decodeFile(file.absolutePath)
        if (bitmap != null) {
          return bitmap
        }
      }
    }
    return null
  }
}
