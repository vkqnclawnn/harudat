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
      elevation: 0,
      clipBehavior: Clip.none,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: AddDDaySheet(existingDDay: existingDDay),
      ),
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
          // 상단 정보줄 (이름, 통계, 수정/삭제 버튼)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // D-Day 이름
              Expanded(
                child: Text(
                  dday.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 진행 통계 + 수정/삭제 버튼
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 진행 통계
                  Text(
                    '${dday.burnedDays}/${dday.totalDays}  ${dday.progressPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 수정 버튼
                  GestureDetector(
                    onTap: () => _showAddDDaySheet(existingDDay: dday),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // 삭제 버튼
                  GestureDetector(
                    onTap: () => _showDeleteDialog(dday),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_rounded,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
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

  /// 삭제 확인 다이얼로그 (블러 + 애니메이션)
  void _showDeleteDialog(DDayModel dday) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete Dialog',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // 탄성 애니메이션 커브
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return Stack(
          children: [
            // 블러 배경
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 5 * animation.value,
                sigmaY: 5 * animation.value,
              ),
              child: Container(
                color: Colors.black.withOpacity(0.3 * animation.value),
              ),
            ),
            // 스케일 애니메이션 적용 다이얼로그
            ScaleTransition(
              scale: curvedAnimation,
              child: Center(
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 경고 아이콘
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_rounded,
                            size: 36,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // 타이틀
                        const Text(
                          '디데이 삭제',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 내용
                        Text(
                          '정말로 "${dday.name}"을(를) 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 버튼들
                        Row(
                          children: [
                            // 취소 버튼
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: Text(
                                  '취소',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 삭제 버튼
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  context.read<DDayProvider>().deleteDDay();
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  '삭제',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
          dotColor = const Color.fromARGB(255, 255, 110, 110);
        } else if (isToday) {
          // 오늘: 빨간색
          dotColor = Color.fromARGB(255, 255, 16, 16);
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
                  colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: hasDDay ? const Color(0xFFE8E8E8) : null,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: hasDDay
                  ? Colors.black.withOpacity(0.05)
                  : const Color(0xFF4CAF50).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasDDay ? '디데이 수정하기' : '디데이 추가하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: hasDDay ? Colors.grey[600] : Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              hasDDay ? Icons.edit_rounded : Icons.add,
              size: 20,
              color: hasDDay ? Colors.grey[600] : Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
