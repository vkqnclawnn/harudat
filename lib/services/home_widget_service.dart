import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../dday_model.dart';

class HomeWidgetService {
  static const String _dataKey = 'dday_data';
  static const String _imageKeyFull = 'widget_full_image';
  static const String _imageKeyMini = 'widget_mini_image';
  static const String _androidWidgetFull = 'FullWidgetProvider';
  static const String _androidWidgetMini = 'MiniWidgetProvider';

  static Future<void> updateHomeWidget(DDayModel dday) async {
    await HomeWidget.saveWidgetData(_dataKey, jsonEncode(dday.toJson()));

    await renderFullWidget(dday);
    await renderMiniWidget(dday);

    await HomeWidget.updateWidget(
      name: _androidWidgetFull,
      androidName: _androidWidgetFull,
    );
    await HomeWidget.updateWidget(
      name: _androidWidgetMini,
      androidName: _androidWidgetMini,
    );
  }

  static Future<void> renderFullWidget(DDayModel dday) async {
    await HomeWidget.renderFlutterWidget(
      HaruDotWidgetFull(dday: dday),
      logicalSize: const Size(360, 360),
      pixelRatio: 4.0,
      key: _imageKeyFull,
    );
  }

  static Future<void> renderMiniWidget(DDayModel dday) async {
    await HomeWidget.renderFlutterWidget(
      HaruDotWidgetMini(dday: dday),
      logicalSize: const Size(240, 140),
      pixelRatio: 4.0,
      key: _imageKeyMini,
    );
  }

  static Future<void> clearHomeWidget() async {
    await HomeWidget.saveWidgetData(_dataKey, null);
    await HomeWidget.updateWidget(
      name: _androidWidgetFull,
      androidName: _androidWidgetFull,
    );
    await HomeWidget.updateWidget(
      name: _androidWidgetMini,
      androidName: _androidWidgetMini,
    );
  }

  static Future<void> updateFromStorage() async {
    final box = await Hive.openBox<DDayModel>('dday_box');
    if (box.isEmpty) {
      await clearHomeWidget();
      return;
    }
    await updateHomeWidget(box.values.last);
  }
}

class HaruDotWidgetFull extends StatelessWidget {
  final DDayModel dday;

  const HaruDotWidgetFull({super.key, required this.dday});

  @override
  Widget build(BuildContext context) {
    final background = dday.isWidgetDark ? Colors.black : Colors.white;
    final foreground = dday.isWidgetDark ? Colors.white : Colors.black;
    final accent = _accentColor(dday.colorIndex);
    final dateText = DateFormat('yyyy.MM.dd').format(dday.endDate);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dday.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateText,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _ddayText(dday),
            style: TextStyle(
              color: foreground,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          ClipRect(
            child: _DotMatrix(
              totalDays: dday.totalDays,
              todayIndex: dday.todayIndex,
              pastColor: accent.withValues(alpha: 0.8),
              todayColor: accent,
              futureColor: foreground.withValues(alpha: 0.18),
              dotSize: 7.0,
              spacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class HaruDotWidgetMini extends StatelessWidget {
  final DDayModel dday;

  const HaruDotWidgetMini({super.key, required this.dday});

  @override
  Widget build(BuildContext context) {
    final background = dday.isWidgetDark ? Colors.black : Colors.white;
    final foreground = dday.isWidgetDark ? Colors.white : Colors.black;
    final accent = _accentColor(dday.colorIndex);
    final progress = dday.progressPercent.clamp(0, 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dday.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _ddayText(dday),
                style: TextStyle(
                  color: foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '$progress%',
                style: TextStyle(
                  color: foreground.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRect(
            child: _DotMatrix(
              totalDays: dday.totalDays,
              todayIndex: dday.todayIndex,
              pastColor: accent.withValues(alpha: 0.75),
              todayColor: accent,
              futureColor: foreground.withValues(alpha: 0.18),
              dotSize: 5.5,
              spacing: 2.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotMatrix extends StatelessWidget {
  final int totalDays;
  final int todayIndex;
  final Color pastColor;
  final Color todayColor;
  final Color futureColor;
  final double dotSize;
  final double spacing;

  const _DotMatrix({
    required this.totalDays,
    required this.todayIndex,
    required this.pastColor,
    required this.todayColor,
    required this.futureColor,
    required this.dotSize,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(totalDays, (index) {
        final isToday = index == todayIndex;
        Color dotColor;
        if (index < todayIndex) {
          dotColor = pastColor;
        } else if (isToday) {
          dotColor = todayColor;
        } else {
          dotColor = futureColor;
        }
        return Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
          ),
        );
      }),
    );
  }
}

String _ddayText(DDayModel dday) {
  final remaining = dday.remainingDays;
  if (remaining == 0) return 'D-Day';
  if (remaining > 0) return 'D-$remaining';
  return 'D+${remaining.abs()}';
}

Color _accentColor(int index) {
  const colors = [
    Color(0xFF4CAF50),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFFFB8C00),
    Color(0xFFF4511E),
    Color(0xFFE53935),
    Color(0xFF00897B),
    Color(0xFF546E7A),
    Color(0xFFD81B60),
    Color(0xFF7CB342),
  ];
  final safeIndex = index.clamp(0, colors.length - 1).toInt();
  return colors[safeIndex];
}
