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

  DDayModel({
    required this.name,
    required this.startDate,
    required this.endDate,
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
}
