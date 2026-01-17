import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dday_model.dart';
import 'add_dday_sheet.dart';
import 'services/home_widget_service.dart';
import 'theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _didWarmUp = false;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    final curve = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(curve);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(curve);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runFirstWarmUp();
    });
  }

  Future<void> _runFirstWarmUp() async {
    if (_didWarmUp || !mounted) return;
    _didWarmUp = true;

    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (context) {
        return const IgnorePointer(
          child: Opacity(
            opacity: 0.01,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 280,
                      child: TextField(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    entry.remove();
    await _warmUpBottomSheet();
    _enterController.forward();
  }

  Future<void> _warmUpBottomSheet() async {
    if (!mounted) return;
    final navigator = Navigator.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.canPop()) {
        navigator.pop();
      }
    });

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.transparent,
      builder: (context) {
        return const Opacity(
          opacity: 0.01,
          child: AddDDaySheet(),
        );
      },
    );
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  String _formatMonthDay(DateTime date) {
    return '${date.month}.${date.day}';
  }

  /// BottomSheet 표시
  Future<void> _showAddDDaySheet({DDayModel? existingDDay}) async {
    final colors = Theme.of(context).colorScheme;
    final result = await showModalBottomSheet<DDayModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: colors.scrim.withValues(alpha: 0.3),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              clipBehavior: Clip.hardEdge,
              child: AddDDaySheet(existingDDay: existingDDay),
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (result != null) {
      await HomeWidgetService.updateHomeWidget(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DDayProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: RepaintBoundary(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: provider.hasDDay
                      ? _buildActiveState(provider.ddayList)
                      : _buildEmptyState(),
                ),
              ),
            ),
          ),
          // FAB는 D-Day가 없을 때만 표시 (하단 중앙)
          floatingActionButton: null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  /// Empty State UI (데이터가 없는 경우)
  Widget _buildEmptyState() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'D-Dot',
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => themeProvider.toggleTheme(),
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: colors.onSurface,
                ),
                tooltip: isDark ? '라이트 모드' : '다크 모드',
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Center(
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding:
                      const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: colors.surface,
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .shadowColor
                            .withValues(alpha: 0.12),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary.withValues(alpha: 0.2),
                        ),
                        child: Icon(
                          Icons.hourglass_empty_rounded,
                          size: 34,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '아직 기록된 디데이가 없어요.',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '예: 수능, 첫 공연, 이사, 전역일',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface.withValues(alpha: 0.55),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      _buildAddButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Active State UI (D-Day가 활성화된 경우)
  Widget _buildActiveState(List<DDayModel> ddays) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'D-Dot',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => themeProvider.toggleTheme(),
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: colors.onSurface,
                ),
                tooltip: isDark ? '라이트 모드' : '다크 모드',
              ),
            ],
          ),
          const SizedBox(height: 20),
          // D-Day 카드
          const SizedBox(height: 8),
          ...ddays.map(
            (dday) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildDDayCard(dday),
            ),
          ),
          // 디데이 추가하기 버튼 (카드 바로 아래)
          Center(child: _buildSecondaryAddButton()),
          const SizedBox(height: 56), // 여유 공간
        ],
      ),
    );
  }

  /// D-Day 카드 위젯
  Widget _buildDDayCard(DDayModel dday) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ddayProvider = context.watch<DDayProvider>();
    final preset = ddayProvider.presetForIndex(dday.colorIndex);
    final pastColor = preset['past']!;
    final todayColor = preset['today']!;
    final rangeText =
        '${_formatMonthDay(dday.startDate)} ~ ${_formatMonthDay(dday.endDate)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: colors.surface,
        border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dday.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rangeText,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _showAddDDaySheet(existingDDay: dday),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 20,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _showDeleteDialog(dday),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.delete_rounded,
                        size: 20,
                        color: colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'D-${dday.remainingDays}',
                style: textTheme.displaySmall?.copyWith(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: todayColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '오늘까지 ${dday.burnedDays}일 지나갔어요',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDotMatrix(dday, pastColor: pastColor, todayColor: todayColor),
        ],
      ),
    );
  }

  /// 디데이 추가하기 버튼 (카드 아래에 배치)
  Widget _buildAddButton() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () {
        // 새로운 D-Day 추가 (existingDDay: null)
        _showAddDDaySheet();
      },
      child: SizedBox(
        width: 200,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                colors.primary,
                colors.primary.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  size: 24,
                  color: colors.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  '새 디데이 만들기',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: colors.onPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryAddButton() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () {
        _showAddDDaySheet();
      },
      child: Container(
        width: 200,
        height: 52,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 18,
                color: colors.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                '새 디데이 만들기',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 삭제 확인 다이얼로그 (빠르고 깔끔하게)
  void _showDeleteDialog(DDayModel dday) {
    final colors = Theme.of(context).colorScheme;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete Dialog',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: const SizedBox.shrink(),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 5 * animation.value,
                sigmaY: 5 * animation.value,
              ),
              child: Container(
                color: colors.scrim.withValues(
                  alpha: 0.3 * animation.value,
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => Navigator.pop(context),
                child: const SizedBox.expand(),
              ),
            ),
            FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0)
                    .animate(curvedAnimation),
                child: Center(
                  child: Material(
                    type: MaterialType.transparency,
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .shadowColor
                                  .withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.errorContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.warning_rounded,
                                size: 36,
                                color: colors.error,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '디데이 삭제',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '정말로 "${dday.name}"을(를) 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.onSurface.withValues(alpha: 0.7),
                                height: 1.4,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: colors.outline.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '취소',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: colors.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final provider =
                                          context.read<DDayProvider>();
                                      await provider.deleteDDay(dday);
                                      if (!mounted) return;

                                      if (provider.ddayList.isNotEmpty) {
                                        await HomeWidgetService
                                            .updateHomeWidget(
                                          provider.ddayList.last,
                                        );
                                      } else {
                                        await HomeWidgetService
                                            .clearHomeWidget();
                                      }

                                      if (mounted) {
                                        Navigator.pop(context);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.error,
                                      foregroundColor: colors.onError,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
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
              ),
            ),
          ],
        );
      },
    );
  }

  /// 점 매트릭스 위젯
  Widget _buildDotMatrix(
    DDayModel dday, {
    required Color pastColor,
    required Color todayColor,
  }) {
    final colors = Theme.of(context).colorScheme;
    final totalDots = dday.totalDays;
    final todayIndex = dday.todayIndex;
    const double spacing = 3.0;
    double dotSize = 7.0;

    if (totalDots > 365) {
      final scale = totalDots / 365;
      dotSize = (7.0 / scale).clamp(3.5, 7.0);
    }

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(totalDots, (index) {
        Color dotColor;
        bool isToday = index == todayIndex;

        if (index < todayIndex) {
          dotColor = pastColor;
        } else if (isToday) {
          dotColor = todayColor;
        } else {
          dotColor = colors.outline.withValues(alpha: 0.7);
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

  /// FAB 위젯 (D-Day 없을 때만 사용)
  Widget _buildFAB() {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        _showAddDDaySheet(); // 새로운 D-Day 추가
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '디데이 추가하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.add,
              size: 20,
              color: colors.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
