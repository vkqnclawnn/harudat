package com.vkqnclawnn.harudat

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

object DotMatrixDrawer {
  private val backgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG)
  private val titlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { typeface = Typeface.DEFAULT_BOLD }
  private val datePaint = Paint(Paint.ANTI_ALIAS_FLAG)
  private val ddayPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { typeface = Typeface.DEFAULT_BOLD }
  private val progressPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { typeface = Typeface.DEFAULT_BOLD }
  private val dotPaint = Paint(Paint.ANTI_ALIAS_FLAG)
  private val emptyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { typeface = Typeface.DEFAULT_BOLD }

  fun drawFullWidget(context: Context, widthPx: Int, heightPx: Int, data: HaruDotData?): Bitmap {
    val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)

    val padding = dpToPx(context, 20f)
    val cornerRadius = dpToPx(context, 24f)

    val backgroundColor = parseColorSafe(data?.backgroundColor ?: "#FFFFFF")
    backgroundPaint.color = backgroundColor
    canvas.drawRoundRect(RectF(0f, 0f, widthPx.toFloat(), heightPx.toFloat()), cornerRadius, cornerRadius, backgroundPaint)

    if (data == null) {
      drawEmptyState(context, canvas, widthPx, heightPx, isDark = false)
      return bitmap
    }

    val foreground = if (data.isWidgetDark) Color.WHITE else Color.BLACK
    val titleSize = dpToPx(context, 20f)
    val dateSize = dpToPx(context, 12f)
    val ddaySize = dpToPx(context, 32f)

    titlePaint.color = foreground
    titlePaint.textSize = titleSize

    datePaint.color = applyAlpha(foreground, 0.6f)
    datePaint.textSize = dateSize

    ddayPaint.color = foreground
    ddayPaint.textSize = ddaySize

    var cursorY = padding + titleSize
    canvas.drawText(data.name, padding, cursorY, titlePaint)

    cursorY += dpToPx(context, 4f) + dateSize
    canvas.drawText(data.dateText, padding, cursorY, datePaint)

    cursorY += dpToPx(context, 16f) + ddaySize
    canvas.drawText(data.dDayText, padding, cursorY, ddayPaint)

    cursorY += dpToPx(context, 16f)

    drawDots(
      context = context,
      canvas = canvas,
      startX = padding,
      startY = cursorY,
      availableWidth = widthPx - padding * 2,
      availableHeight = heightPx - padding - cursorY,
      totalDots = data.totalDots,
      burnedDots = data.burnedDots,
      pastColorHex = data.colorPast,
      todayColorHex = data.colorToday,
      futureColor = applyAlpha(foreground, 0.18f),
      dotSizeDp = 7f,
      spacingDp = 3f,
      pastAlpha = 0.8f
    )

    return bitmap
  }

  fun drawMiniWidget(context: Context, widthPx: Int, heightPx: Int, data: HaruDotData?): Bitmap {
    val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)

    val padding = dpToPx(context, 14f)
    val cornerRadius = dpToPx(context, 20f)

    val backgroundColor = parseColorSafe(data?.backgroundColor ?: "#FFFFFF")
    backgroundPaint.color = backgroundColor
    canvas.drawRoundRect(RectF(0f, 0f, widthPx.toFloat(), heightPx.toFloat()), cornerRadius, cornerRadius, backgroundPaint)

    if (data == null) {
      drawEmptyState(context, canvas, widthPx, heightPx, isDark = false)
      return bitmap
    }

    val foreground = if (data.isWidgetDark) Color.WHITE else Color.BLACK
    val titleSize = dpToPx(context, 16f)
    val ddaySize = dpToPx(context, 20f)
    val progressSize = dpToPx(context, 12f)

    titlePaint.color = foreground
    titlePaint.textSize = titleSize

    ddayPaint.color = foreground
    ddayPaint.textSize = ddaySize

    progressPaint.color = applyAlpha(foreground, 0.6f)
    progressPaint.textSize = progressSize

    var cursorY = padding + titleSize
    canvas.drawText(data.name, padding, cursorY, titlePaint)

    cursorY += dpToPx(context, 4f) + ddaySize
    canvas.drawText(data.dDayText, padding, cursorY, ddayPaint)

    val progressText = "${data.progressPercent.roundToInt()}%"
    val progressWidth = progressPaint.measureText(progressText)
    canvas.drawText(progressText, widthPx - padding - progressWidth, cursorY, progressPaint)

    cursorY += dpToPx(context, 10f)

    drawDots(
      context = context,
      canvas = canvas,
      startX = padding,
      startY = cursorY,
      availableWidth = widthPx - padding * 2,
      availableHeight = heightPx - padding - cursorY,
      totalDots = data.totalDots,
      burnedDots = data.burnedDots,
      pastColorHex = data.colorPast,
      todayColorHex = data.colorToday,
      futureColor = applyAlpha(foreground, 0.18f),
      dotSizeDp = 5.5f,
      spacingDp = 2.5f,
      pastAlpha = 0.75f
    )

    return bitmap
  }

  private fun drawDots(
    context: Context,
    canvas: Canvas,
    startX: Float,
    startY: Float,
    availableWidth: Float,
    availableHeight: Float,
    totalDots: Int,
    burnedDots: Int,
    pastColorHex: String,
    todayColorHex: String,
    futureColor: Int,
    dotSizeDp: Float,
    spacingDp: Float,
    pastAlpha: Float
  ) {
    if (totalDots <= 0 || availableWidth <= 0f || availableHeight <= 0f) return

    val dotSizePx = dpToPx(context, dotSizeDp)
    val spacingPx = dpToPx(context, spacingDp)
    val radius = dotSizePx / 2f

    val cols = max(1, floor((availableWidth + spacingPx) / (dotSizePx + spacingPx)).toInt())
    val maxRows = max(1, floor((availableHeight + spacingPx) / (dotSizePx + spacingPx)).toInt())
    val maxDots = min(totalDots, cols * maxRows)

    val todayIndex = when {
      burnedDots <= 0 -> -1
      burnedDots >= totalDots -> totalDots
      else -> burnedDots - 1
    }

    val pastColor = applyAlpha(parseColorSafe(pastColorHex), pastAlpha)
    val todayColor = parseColorSafe(todayColorHex)

    val step = dotSizePx + spacingPx
    for (i in 0 until maxDots) {
      val row = i / cols
      val col = i % cols

      val cx = startX + col * step + radius
      val cy = startY + row * step + radius

      if (cy + radius > startY + availableHeight) break

      val color = when {
        i < todayIndex -> pastColor
        i == todayIndex -> todayColor
        else -> futureColor
      }

      dotPaint.color = color
      canvas.drawCircle(cx, cy, radius, dotPaint)
    }
  }

  private fun drawEmptyState(context: Context, canvas: Canvas, widthPx: Int, heightPx: Int, isDark: Boolean) {
    val foreground = if (isDark) Color.WHITE else Color.BLACK
    emptyPaint.color = applyAlpha(foreground, 0.6f)
    emptyPaint.textSize = dpToPx(context, 14f)

    val text = "Create D-Day"
    val textWidth = emptyPaint.measureText(text)
    val x = (widthPx - textWidth) / 2f
    val y = heightPx / 2f
    canvas.drawText(text, x, y, emptyPaint)
  }

  private fun parseColorSafe(value: String): Int {
    return try {
      Color.parseColor(value)
    } catch (_: IllegalArgumentException) {
      Color.BLACK
    }
  }

  private fun applyAlpha(color: Int, alpha: Float): Int {
    val a = (Color.alpha(color) * alpha).roundToInt().coerceIn(0, 255)
    return Color.argb(a, Color.red(color), Color.green(color), Color.blue(color))
  }

  fun dpToPx(context: Context, dp: Float): Float {
    return dp * context.resources.displayMetrics.density
  }
}
