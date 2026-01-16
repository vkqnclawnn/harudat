import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'dday_model.dart';
import 'add_dday_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBlurred = false;

  /// BottomSheet 표시 (블러 효과 적용)
  void _showAddDDaySheet({DDayModel? existingDDay}) {
    setState(() => _isBlurred = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => AddDDaySheet(existingDDay: existingDDay),
    ).then((_) {
      setState(() => _isBlurred = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DDayProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFE5E5E5),
          body: Stack(
            children: [
              // 메인 콘텐츠
              SafeArea(
                child: provider.hasDDay
                    ? _buildActiveState(provider.dday!)
                    : _buildEmptyState(),
              ),
              // 블러 오버레이
              if (_isBlurred)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),
            ],
          ),
          // FAB - 하단 중앙 배치
          floatingActionButton: _buildFAB(provider.hasDDay),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  /// Empty State UI (데이터가 없는 경우)
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 타이틀
          const Text(
            '나의 디데이',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 40),
          // 빈 상태 카드
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding:
                    const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 모래시계 아이콘 (블러 효과 적용)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 블러된 그림자 효과
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: const Icon(
                              Icons.hourglass_empty,
                              size: 48,
                              color: Colors.black26,
                            ),
                          ),
                          // 실제 아이콘
                          const Icon(
                            Icons.hourglass_empty,
                            size: 48,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 안내 문구
                    const Text(
                      '아직 추가된 디데이가 없습니다.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 100), // FAB 공간 확보
        ],
      ),
    );
  }

  /// Active State UI (D-Day가 활성화된 경우)
  Widget _buildActiveState(DDayModel dday) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // D-Day 이름 카드
          _buildDDayCard(dday),
          const SizedBox(height: 120), // FAB 공간 확보
        ],
      ),
    );
  }

  /// D-Day 카드 위젯 (점 매트릭스 포함)
  Widget _buildDDayCard(DDayModel dday) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 정보줄 (이름, 통계)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // D-Day 이름
              Text(
                dday.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // 진행 통계
              Text(
                '${dday.burnedDays}/${dday.totalDays}  ${dday.progressPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 점 매트릭스
          _buildDotMatrix(dday),
        ],
      ),
    );
  }

  /// 점 매트릭스 위젯
  Widget _buildDotMatrix(DDayModel dday) {
    final totalDots = dday.totalDays;
    final todayIndex = dday.todayIndex;

    // 점 크기 계산 (최소 4px 보장)
    // 화면 너비에 따라 동적으로 계산
    const double spacing = 6.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 48 - 40; // padding 고려

    // 한 줄에 들어갈 점 개수 계산 (기본 점 크기 8px 기준)
    double dotSize = 8.0;
    int dotsPerRow = ((availableWidth + spacing) / (dotSize + spacing)).floor();

    // 점이 너무 많으면 크기 조정
    if (totalDots > 365) {
      // 스케일링: 점 크기를 줄이되 최소 4px 보장
      final scale = totalDots / 365;
      dotSize = (8.0 / scale).clamp(4.0, 8.0);
      dotsPerRow = ((availableWidth + spacing) / (dotSize + spacing)).floor();
    }

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(totalDots, (index) {
        // 색상 결정
        Color dotColor;
        bool isToday = index == todayIndex;

        if (index < todayIndex) {
          // 지나간 날: 빨간색 
          dotColor = const Color.fromARGB(255, 255, 79, 79);
        } else if (isToday) {
          // 오늘: 빨간색 
          dotColor = Color.fromARGB(255, 195, 0, 0);
        } else {
          // 남은 날: 회색 (Active)r
          dotColor = const Color(0xFF848484);
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

  /// FAB 위젯
  Widget _buildFAB(bool hasDDay) {
    return GestureDetector(
      onTap: () {
        final provider = context.read<DDayProvider>();
        _showAddDDaySheet(existingDDay: provider.dday);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          // 그라데이션 또는 단색 (이미지 참고하여 파란색 그라데이션)
          gradient: hasDDay
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF5B9CFF), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: hasDDay ? const Color(0xFFE8E8E8) : null,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: hasDDay
                  ? Colors.black.withOpacity(0.05)
                  : const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasDDay ? '디데이 추가' : '디데이 추가하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: hasDDay ? Colors.grey[600] : Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.add,
              size: 20,
              color: hasDDay ? Colors.grey[600] : Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
