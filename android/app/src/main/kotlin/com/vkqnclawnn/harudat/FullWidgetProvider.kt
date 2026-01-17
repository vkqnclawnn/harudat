package com.vkqnclawnn.harudat

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.SizeF
import android.widget.RemoteViews
import androidx.core.content.FileProvider
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File
import java.io.FileOutputStream
import kotlin.math.sqrt
import kotlin.math.roundToInt

class FullWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    widgetData: SharedPreferences
  ) {
    appWidgetIds.forEach { appWidgetId ->
      val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
      updateWidget(context, appWidgetManager, appWidgetId, widgetData, options)
    }
  }

  override fun onAppWidgetOptionsChanged(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    newOptions: Bundle
  ) {
    scheduleDebouncedUpdate(context, appWidgetManager, appWidgetId, newOptions)
  }

  private fun updateWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    widgetData: SharedPreferences,
    options: Bundle
  ) {
    val views = RemoteViews(context.packageName, R.layout.widget_layout_full)
    val (widthPx, heightPx) = resolveWidgetSizePx(context, appWidgetManager, appWidgetId, options)
    if (widthPx <= 0 || heightPx <= 0) {
      Log.d(TAG, "FullWidget size invalid: ${widthPx}x${heightPx}")
      appWidgetManager.updateAppWidget(appWidgetId, views)
      return
    }
    val json = resolveWidgetJson(context, widgetData)
    val data = HaruDotData.fromJson(json)
    Log.d(TAG, "FullWidget size=${widthPx}x${heightPx}, hasData=${data != null}, jsonLen=${json?.length ?: 0}")
    val bitmap = DotMatrixDrawer.drawFullWidget(context, widthPx, heightPx, data)
    setImageWithIpcGuard(context, views, R.id.widget_image_full, bitmap, "widget_full_$appWidgetId")
    appWidgetManager.updateAppWidget(appWidgetId, views)
  }

  private fun resolveWidgetSizePx(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    options: Bundle
  ): Pair<Int, Int> {
    val density = context.resources.displayMetrics.density
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      val sizes = options.getParcelableArrayList<SizeF>(AppWidgetManager.OPTION_APPWIDGET_SIZES)
      if (!sizes.isNullOrEmpty()) {
        val best = sizes.maxBy { it.width * it.height }
        return Pair(
          (best.width * density).roundToInt().coerceAtLeast(1),
          (best.height * density).roundToInt().coerceAtLeast(1)
        )
      }
    }
    var minWidthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
    var minHeightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)

    if (minWidthDp <= 0 || minHeightDp <= 0) {
      val info = appWidgetManager.getAppWidgetInfo(appWidgetId)
      if (info != null) {
        if (minWidthDp <= 0) minWidthDp = info.minWidth
        if (minHeightDp <= 0) minHeightDp = info.minHeight
      }
    }

    if (minWidthDp <= 0) minWidthDp = DEFAULT_WIDTH_DP
    if (minHeightDp <= 0) minHeightDp = DEFAULT_HEIGHT_DP

    return Pair(
      (minWidthDp * density).roundToInt().coerceAtLeast(1),
      (minHeightDp * density).roundToInt().coerceAtLeast(1)
    )
  }

  private fun setImageWithIpcGuard(
    context: Context,
    views: RemoteViews,
    imageViewId: Int,
    bitmap: Bitmap,
    cacheKey: String
  ) {
    if (bitmap.byteCount <= MAX_BITMAP_BYTES) {
      views.setImageViewBitmap(imageViewId, bitmap)
      Log.d(TAG, "FullWidget bitmap inline bytes=${bitmap.byteCount}")
      return
    }

    val file = File(context.cacheDir, "$cacheKey.png")
    try {
      FileOutputStream(file).use { output ->
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
      }
      val uri = FileProvider.getUriForFile(
        context,
        "${context.packageName}.fileprovider",
        file
      )
      val launcherPackage = resolveLauncherPackage(context)
      if (launcherPackage != null) {
        context.grantUriPermission(launcherPackage, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
      }
      views.setImageViewUri(imageViewId, uri)
      Log.d(TAG, "FullWidget bitmap via uri bytes=${bitmap.byteCount}, launcher=${launcherPackage ?: "unknown"}")
    } catch (_: Exception) {
      val scaled = scaleBitmapToLimit(bitmap, MAX_BITMAP_BYTES)
      views.setImageViewBitmap(imageViewId, scaled)
      Log.d(TAG, "FullWidget bitmap scaled bytes=${scaled.byteCount}")
    }
  }

  private fun resolveWidgetJson(context: Context, widgetData: SharedPreferences?): String? {
    val key = WIDGET_JSON_KEY
    widgetData?.getString(key, null)?.let { return it }

    val candidates = listOf(
      context.getSharedPreferences("home_widget", Context.MODE_PRIVATE),
      context.getSharedPreferences("HomeWidget", Context.MODE_PRIVATE),
      context.getSharedPreferences("${context.packageName}.home_widget", Context.MODE_PRIVATE)
    )

    for (prefs in candidates) {
      val value = prefs.getString(key, null)
      if (!value.isNullOrBlank()) return value
    }

    return null
  }

  private fun resolveLauncherPackage(context: Context): String? {
    val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
    val resolve = context.packageManager.resolveActivity(intent, 0)
    return resolve?.activityInfo?.packageName
  }

  private fun scaleBitmapToLimit(bitmap: Bitmap, maxBytes: Int): Bitmap {
    if (bitmap.byteCount <= maxBytes) return bitmap
    val scale = sqrt(maxBytes.toDouble() / bitmap.byteCount.toDouble()).toFloat()
    val targetWidth = (bitmap.width * scale).roundToInt().coerceAtLeast(1)
    val targetHeight = (bitmap.height * scale).roundToInt().coerceAtLeast(1)
    return Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
  }

  private fun scheduleDebouncedUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    options: Bundle
  ) {
    val runnable = Runnable {
      val prefs = context.getSharedPreferences("home_widget", Context.MODE_PRIVATE)
      updateWidget(context, appWidgetManager, appWidgetId, prefs, options)
    }

    pendingUpdates[appWidgetId]?.let { handler.removeCallbacks(it) }
    pendingUpdates[appWidgetId] = runnable
    handler.postDelayed(runnable, DEBOUNCE_MS)
  }

  companion object {
    private const val MAX_BITMAP_BYTES = 1_000_000
    private const val DEBOUNCE_MS = 120L
    private const val DEFAULT_WIDTH_DP = 240
    private const val DEFAULT_HEIGHT_DP = 180
    private const val TAG = "HaruDotWidget"
    private const val WIDGET_JSON_KEY = "dday_json"
    private val handler = Handler(Looper.getMainLooper())
    private val pendingUpdates = mutableMapOf<Int, Runnable>()
  }
}
