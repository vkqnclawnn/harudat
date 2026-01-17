package com.vkqnclawnn.harudat

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetUtils

class HaruDotWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    widgetData: SharedPreferences
  ) {
    appWidgetIds.forEach { appWidgetId ->
      val views = RemoteViews(context.packageName, R.layout.haru_dot_widget)
      val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
      val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
      val imageKey = if (minHeight < 140) "widget_image_mini" else "widget_image_full"

      val bitmap = HomeWidgetUtils.getWidgetBitmap(context, imageKey)
      if (bitmap != null) {
        views.setImageViewBitmap(R.id.widget_image, bitmap)
      } else {
        views.setImageViewResource(R.id.widget_image, R.mipmap.ic_launcher)
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
    onUpdate(context, appWidgetManager, intArrayOf(appWidgetId),
      context.getSharedPreferences("home_widget", Context.MODE_PRIVATE)
    )
  }
}
