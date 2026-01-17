import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../dday_model.dart';

class HomeWidgetService {
  static const String _dataKey = 'dday_json';
  static const String _androidWidgetFull = 'FullWidgetProvider';
  static const String _androidWidgetMini = 'MiniWidgetProvider';

  static Future<void> updateHomeWidget(DDayModel dday) async {
    final payload = _buildWidgetPayload(dday);
    await HomeWidget.saveWidgetData(_dataKey, jsonEncode(payload));

    await HomeWidget.updateWidget(
      name: _androidWidgetFull,
      androidName: _androidWidgetFull,
    );
    await HomeWidget.updateWidget(
      name: _androidWidgetMini,
      androidName: _androidWidgetMini,
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

  static Map<String, dynamic> _buildWidgetPayload(DDayModel dday) {
    final colors = _dotPresetForIndex(dday.colorIndex);
    final background = dday.isWidgetDark ? Colors.black : Colors.white;
    final dateText = DateFormat('yyyy.MM.dd').format(dday.endDate);
    final ddayText = _ddayText(dday);

    return {
      'name': dday.name,
      'dDayText': ddayText,
      'dateText': dateText,
      'dateRangeText': dateText,
      'totalDots': dday.totalDays,
      'burnedDots': dday.burnedDays,
      'progressPercent': dday.progressPercent,
      'colorPast': _toHex(colors['past']!),
      'colorToday': _toHex(colors['today']!),
      'backgroundColor': _toHex(background),
      'isWidgetDark': dday.isWidgetDark,
    };
  }
}

String _ddayText(DDayModel dday) {
  final remaining = dday.remainingDays;
  if (remaining == 0) return 'D-Day';
  if (remaining > 0) return 'D-$remaining';
  return 'D+${remaining.abs()}';
}

Map<String, Color> _dotPresetForIndex(int index) {
  const presets = [
    {'past': Color(0xFF66BB6A), 'today': Color(0xFF4CAF50)},
    {'past': Color(0xFF42A5F5), 'today': Color(0xFF1E88E5)},
    {'past': Color(0xFFAB47BC), 'today': Color(0xFF8E24AA)},
    {'past': Color(0xFFFFA726), 'today': Color(0xFFFB8C00)},
    {'past': Color(0xFFFF7043), 'today': Color(0xFFF4511E)},
    {'past': Color(0xFFEF5350), 'today': Color(0xFFE53935)},
    {'past': Color(0xFF26A69A), 'today': Color(0xFF00897B)},
    {'past': Color(0xFF78909C), 'today': Color(0xFF546E7A)},
    {'past': Color(0xFFEC407A), 'today': Color(0xFFD81B60)},
    {'past': Color(0xFF9CCC65), 'today': Color(0xFF7CB342)},
  ];
  final safeIndex = index.clamp(0, presets.length - 1).toInt();
  return presets[safeIndex];
}

String _toHex(Color color) {
  final value = color.value & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
