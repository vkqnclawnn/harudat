import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'dday_model.g.dart';

/// D-Day 데이터 모델
/// Hive에 저장되는 D-Day 정보를 담는 클래스
@HiveType(typeId: 0)
class DDayModel extends HiveObject {
  /// D-Day 이름 (예: "수능", "전역일")
  @HiveField(0)
  String name;

  /// 시작일
  @HiveField(1)
  DateTime startDate;

  /// 마감일 (목표일)
  @HiveField(2)
  DateTime endDate;

  /// 색상 프리셋 인덱스
  @HiveField(3)
  int colorIndex;

  /// 위젯 배경 (true = 다크)
  @HiveField(4, defaultValue: true)
  bool isWidgetDark;

  DDayModel({
    required this.name,
    required this.startDate,
    required this.endDate,
    this.colorIndex = 0,
    this.isWidgetDark = true,
  });

  /// 총 기간 (일수) 계산
  int get totalDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// 경과 일수 계산 (오늘 기준)
  int get burnedDays {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);

    // 시작일 이전이면 0
    if (todayOnly.isBefore(startOnly)) return 0;

    // 종료일 이후면 전체 일수
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    if (todayOnly.isAfter(endOnly)) return totalDays;

    // 오늘까지 지난 일수 (오늘 포함)
    return todayOnly.difference(startOnly).inDays + 1;
  }

  /// 남은 일수 계산
  int get remainingDays {
    return totalDays - burnedDays;
  }

  /// 진행률 (%) 계산
  double get progressPercent {
    if (totalDays == 0) return 0.0;
    return (burnedDays / totalDays) * 100;
  }

  /// 오늘이 몇 번째 날인지 (0-indexed)
  int get todayIndex {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);

    if (todayOnly.isBefore(startOnly)) return -1;

    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    if (todayOnly.isAfter(endOnly)) return totalDays;

    return todayOnly.difference(startOnly).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'colorIndex': colorIndex,
      'isWidgetDark': isWidgetDark,
    };
  }

  factory DDayModel.fromJson(Map<String, dynamic> json) {
    return DDayModel(
      name: json['name'] as String? ?? '',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      colorIndex: json['colorIndex'] as int? ?? 0,
      isWidgetDark: json['isWidgetDark'] as bool? ?? true,
    );
  }
}

/// D-Day 데이터를 관리하는 Provider
class DDayProvider extends ChangeNotifier {
  List<DDayModel> _ddays = [];
  late Box<DDayModel> _box;

  // ✅ 형님이 정해주신 10가지 프리셋
  final List<Map<String, Color>> _dotColorPresets = [
    {'past': const Color(0xFF66BB6A), 'today': const Color(0xFF4CAF50)},
    {'past': const Color(0xFF42A5F5), 'today': const Color(0xFF1E88E5)},
    {'past': const Color(0xFFAB47BC), 'today': const Color(0xFF8E24AA)},
    {'past': const Color(0xFFFFA726), 'today': const Color(0xFFFB8C00)},
    {'past': const Color(0xFFFF7043), 'today': const Color(0xFFF4511E)},
    {'past': const Color(0xFFEF5350), 'today': const Color(0xFFE53935)},
    {'past': const Color(0xFF26A69A), 'today': const Color(0xFF00897B)},
    {'past': const Color(0xFF78909C), 'today': const Color(0xFF546E7A)},
    {'past': const Color(0xFFEC407A), 'today': const Color(0xFFD81B60)},
    {'past': const Color(0xFF9CCC65), 'today': const Color(0xFF7CB342)},
  ];

  int _selectedPresetIndex = 0;

  List<DDayModel> get ddayList => List.unmodifiable(_ddays);
  bool get hasDDay => _ddays.isNotEmpty;

  Color get dotColorPast => _dotColorPresets[_selectedPresetIndex]['past']!;
  Color get dotColorToday => _dotColorPresets[_selectedPresetIndex]['today']!;
  List<Map<String, Color>> get dotColorPresets => _dotColorPresets;
  int get selectedPresetIndex => _selectedPresetIndex;

  Map<String, Color> presetForIndex(int index) {
    final safeIndex = index.clamp(0, _dotColorPresets.length - 1).toInt();
    return _dotColorPresets[safeIndex];
  }

  /// Hive Box 초기화 및 데이터 로드
  Future<void> init() async {
    _box = await Hive.openBox<DDayModel>('dday_box');
    _ddays = _box.values.toList();
    _selectedPresetIndex = _ddays.isNotEmpty
        ? (_ddays.last.colorIndex).clamp(0, _dotColorPresets.length - 1).toInt()
        : 0;
    notifyListeners();
  }

  /// D-Day 저장 (새 항목 추가)
  Future<void> saveDDay(DDayModel dday) async {
    await _box.add(dday);
    await _box.flush();
    _ddays = _box.values.toList();
    _selectedPresetIndex =
        dday.colorIndex.clamp(0, _dotColorPresets.length - 1).toInt();
    notifyListeners();
  }

  /// D-Day 수정
  Future<void> updateDDay(DDayModel target, DDayModel updated) async {
    final key = target.key;
    if (key != null) {
      await _box.put(key, updated);
    } else {
      final index = _ddays.indexOf(target);
      if (index != -1) {
        await _box.putAt(index, updated);
      } else {
        await _box.add(updated);
      }
    }
    await _box.flush();
    _ddays = _box.values.toList();
    _selectedPresetIndex =
        updated.colorIndex.clamp(0, _dotColorPresets.length - 1).toInt();
    notifyListeners();
  }

  /// D-Day 삭제
  Future<void> deleteDDay(DDayModel target) async {
    final key = target.key;
    if (key != null) {
      await _box.delete(key);
    } else {
      final index = _ddays.indexOf(target);
      if (index != -1) {
        await _box.deleteAt(index);
      }
    }
    await _box.flush();
    _ddays = _box.values.toList();
    _selectedPresetIndex = _ddays.isNotEmpty
        ? (_ddays.last.colorIndex).clamp(0, _dotColorPresets.length - 1).toInt()
        : 0;
    notifyListeners();
  }

  /// 색상 선택
  void selectDotColorPreset(int index) {
    if (index < 0 || index >= _dotColorPresets.length) return;
    _selectedPresetIndex = index;
    notifyListeners();
  }
}
