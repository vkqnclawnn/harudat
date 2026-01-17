import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dday_model.dart';

class AddDDaySheet extends StatefulWidget {
  final DDayModel? existingDDay;

  const AddDDaySheet({super.key, this.existingDDay});

  @override
  State<AddDDaySheet> createState() => _AddDDaySheetState();
}

class _AddDDaySheetState extends State<AddDDaySheet> {
  late TextEditingController _nameController;
  late DateTime _startDate;
  late DateTime _endDate;
  late int _tempPresetIndex;
  late bool _isWidgetDark;
  String? _nameError; // 이름 에러 메시지
  String? _dateError; // 날짜 에러 메시지

  Color _contrastOn(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  @override
  void initState() {
    super.initState();
    // 기존 데이터가 있으면 불러오기, 없으면 기본값 설정
    _nameController = TextEditingController(
      text: widget.existingDDay?.name ?? '',
    );
    _startDate = widget.existingDDay?.startDate ?? DateTime.now();
    _endDate = widget.existingDDay?.endDate ??
        DateTime.now().add(const Duration(days: 30));
    _tempPresetIndex = widget.existingDDay?.colorIndex ??
        context.read<DDayProvider>().selectedPresetIndex;
    _isWidgetDark = widget.existingDDay?.isWidgetDark ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 한국어 날짜 포맷 (yyyy년 MM월 dd일)
  String _formatDate(DateTime date) {
    return DateFormat('yyyy년 M월 d일', 'ko').format(date);
  }

  /// 오늘 날짜인지 확인
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// 날짜 선택기 표시
  Future<void> _selectDate(bool isStartDate) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final initialDate = isStartDate ? _startDate : _endDate;
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);

    final picked = await _showCustomDatePicker(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // 시작일이 마감일보다 뒤면 마감일 조정
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
          // 마감일이 시작일보다 앞이면 시작일 조정
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(days: 1));
          }
        }
      });
    }
  }

  Future<DateTime?> _showCustomDatePicker({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (dialogContext) {
        return _CalendarDialog(
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
        );
      },
    );
  }

  /// 저장 버튼 클릭 처리
  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    final provider = context.read<DDayProvider>();

    // 에러 초기화
    setState(() {
      _nameError = null;
      _dateError = null;
    });

    // 유효성 검사
    if (name.isEmpty) {
      setState(() {
        _nameError = '디데이 이름을 입력해주세요';
      });
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      setState(() {
        _dateError = '마감일은 시작일보다 이후여야 합니다';
      });
      return;
    }

    // D-Day 저장/수정
    final dday = DDayModel(
      name: name,
      startDate: _startDate,
      endDate: _endDate,
      colorIndex: _tempPresetIndex,
      isWidgetDark: _isWidgetDark,
    );

    if (widget.existingDDay != null) {
      await provider.updateDDay(widget.existingDDay!, dday);
    } else {
      await provider.saveDDay(dday);
    }
    if (!mounted) return;
    Navigator.pop(context, dday);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ddayProvider = context.watch<DDayProvider>();
    final presets = ddayProvider.dotColorPresets;
    final selectedIndex = _tempPresetIndex;
    final selectedTodayColor = presets[selectedIndex]['today']!;
    final selectedOnColor = _contrastOn(selectedTodayColor);
    final days = _totalDays;
    final isValidDays = days > 0;

    final content = _SheetContent(
      isEditing: widget.existingDDay != null,
      nameController: _nameController,
      nameError: _nameError,
      dateError: _dateError,
      startDateLabel: _isToday(_startDate) ? '오늘' : _formatDate(_startDate),
      endDateLabel: _isToday(_endDate) ? '오늘' : _formatDate(_endDate),
      onTapStartDate: () => _selectDate(true),
      onTapEndDate: () => _selectDate(false),
      colors: colors,
      textTheme: textTheme,
      presets: presets,
      selectedIndex: selectedIndex,
      onSelectPreset: (index) => setState(() => _tempPresetIndex = index),
      isWidgetDark: _isWidgetDark,
      onWidgetThemeChanged: (value) => setState(() => _isWidgetDark = value),
      totalDays: days,
      isValidDays: isValidDays,
      selectedTodayColor: selectedTodayColor,
      selectedOnColor: selectedOnColor,
      onSave: _onSave,
    );

    return _BottomInsetPadding(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: content,
      ),
    );
  }

  /// 총 기간 계산
  int get _totalDays => _endDate.difference(_startDate).inDays + 1;
}

class _CalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _CalendarDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  static const List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _normalize(widget.initialDate);
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int _daysInMonth(DateTime month) {
    final beginningNextMonth = DateTime(month.year, month.month + 1, 1);
    return beginningNextMonth.subtract(const Duration(days: 1)).day;
  }

  bool _isDisabled(DateTime date) {
    return date.isBefore(_normalize(widget.firstDate)) ||
        date.isAfter(_normalize(widget.lastDate));
  }

  void _goToPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final daysInMonth = _daysInMonth(_visibleMonth);
    final firstWeekday =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday;
    final leadingEmpty = firstWeekday - 1;
    const totalCells = 42;
    final today = _normalize(DateTime.now());

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: colors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(colors, textTheme),
            const SizedBox(height: 12),
            _buildWeekdays(colors, textTheme),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildCalendarGrid(
                key: ValueKey('${_visibleMonth.year}-${_visibleMonth.month}'),
                colors: colors,
                textTheme: textTheme,
                daysInMonth: daysInMonth,
                leadingEmpty: leadingEmpty,
                totalCells: totalCells,
                today: today,
              ),
            ),
            const SizedBox(height: 18),
            _buildActions(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_visibleMonth.year}년 ${_visibleMonth.month}월',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: colors.onSurface,
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _goToPreviousMonth,
              icon: const Icon(Icons.chevron_left_rounded),
              color: colors.onSurface,
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              splashRadius: 20,
            ),
            IconButton(
              onPressed: _goToNextMonth,
              icon: const Icon(Icons.chevron_right_rounded),
              color: colors.onSurface,
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              splashRadius: 20,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdays(ColorScheme colors, TextTheme textTheme) {
    return Row(
      children: _weekdays
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface.withValues(alpha: 0.4),
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid({
    required Key key,
    required ColorScheme colors,
    required TextTheme textTheme,
    required int daysInMonth,
    required int leadingEmpty,
    required int totalCells,
    required DateTime today,
  }) {
    return GridView.builder(
      key: key,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNumber = index - leadingEmpty + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(
          _visibleMonth.year,
          _visibleMonth.month,
          dayNumber,
        );
        final normalized = _normalize(date);
        final isSelected = normalized == _selectedDate;
        final isToday = normalized == today;
        final disabled = _isDisabled(normalized);

        final backgroundColor =
            isSelected ? colors.primary : Colors.transparent;
        final textColor = isSelected
            ? colors.onPrimary
            : disabled
                ? colors.onSurface.withValues(alpha: 0.25)
                : colors.onSurface;
        final borderColor = isToday && !isSelected
            ? colors.primary.withValues(alpha: 0.5)
            : Colors.transparent;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: disabled
                ? null
                : () {
                    setState(() {
                      _selectedDate = normalized;
                    });
                  },
            splashColor: colors.primary.withValues(alpha: 0.12),
            highlightColor: colors.primary.withValues(alpha: 0.08),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$dayNumber',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (isToday && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(ColorScheme colors) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: colors.outline.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Text(
              '취소',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.pop(context, _selectedDate),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '확인',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomInsetPadding extends StatelessWidget {
  final Widget child;

  const _BottomInsetPadding({required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: child,
    );
  }
}

class _SheetContent extends StatelessWidget {
  final bool isEditing;
  final TextEditingController nameController;
  final String? nameError;
  final String? dateError;
  final String startDateLabel;
  final String endDateLabel;
  final VoidCallback onTapStartDate;
  final VoidCallback onTapEndDate;
  final ColorScheme colors;
  final TextTheme textTheme;
  final List<Map<String, Color>> presets;
  final int selectedIndex;
  final ValueChanged<int> onSelectPreset;
  final bool isWidgetDark;
  final ValueChanged<bool> onWidgetThemeChanged;
  final int totalDays;
  final bool isValidDays;
  final Color selectedTodayColor;
  final Color selectedOnColor;
  final VoidCallback onSave;

  const _SheetContent({
    required this.isEditing,
    required this.nameController,
    required this.nameError,
    required this.dateError,
    required this.startDateLabel,
    required this.endDateLabel,
    required this.onTapStartDate,
    required this.onTapEndDate,
    required this.colors,
    required this.textTheme,
    required this.presets,
    required this.selectedIndex,
    required this.onSelectPreset,
    required this.isWidgetDark,
    required this.onWidgetThemeChanged,
    required this.totalDays,
    required this.isValidDays,
    required this.selectedTodayColor,
    required this.selectedOnColor,
    required this.onSave,
  });

  Color _contrastOn(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SheetGrabber(),
        const SizedBox(height: 24),
        _SheetHeader(
          title: isEditing ? '디데이 다듬기' : '새 디데이',
          colors: colors,
          textTheme: textTheme,
        ),
        const SizedBox(height: 28),
        _NameFieldSection(
          controller: nameController,
          colors: colors,
          textTheme: textTheme,
        ),
        if (nameError != null)
          _InlineErrorText(
              message: nameError!, colors: colors, textTheme: textTheme),
        const SizedBox(height: 16),
        _DateSection(
          colors: colors,
          textTheme: textTheme,
          startDateLabel: startDateLabel,
          endDateLabel: endDateLabel,
          onTapStartDate: onTapStartDate,
          onTapEndDate: onTapEndDate,
        ),
        if (dateError != null)
          _InlineErrorText(
              message: dateError!, colors: colors, textTheme: textTheme),
        const SizedBox(height: 16),
        _DurationInfo(
          totalDays: totalDays,
          isValid: isValidDays,
          colors: colors,
          textTheme: textTheme,
          highlightColor: selectedTodayColor,
        ),
        const SizedBox(height: 32),
        _ColorPickerSection(
          colors: colors,
          textTheme: textTheme,
          presets: presets,
          selectedIndex: selectedIndex,
          onSelectPreset: onSelectPreset,
          contrastOn: _contrastOn,
        ),
        const SizedBox(height: 28),
        _WidgetBackgroundToggle(
          colors: colors,
          textTheme: textTheme,
          isWidgetDark: isWidgetDark,
          onChanged: onWidgetThemeChanged,
        ),
        const SizedBox(height: 36),
        _SaveButton(
          isEditing: isEditing,
          colors: colors,
          textTheme: textTheme,
          selectedTodayColor: selectedTodayColor,
          selectedOnColor: selectedOnColor,
          onSave: onSave,
        ),
      ],
    );
  }
}

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _SheetHeader({
    required this.title,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
    );
  }
}

class _NameFieldSection extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _NameFieldSection({
    required this.controller,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: '예: 수능, 첫 공연, 이사, 전역일',
          hintStyle: TextStyle(
            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 16,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: InputBorder.none,
        ),
        cursorColor: colors.primary,
        style: textTheme.bodyLarge?.copyWith(
          color: colors.onSurface,
        ),
      ),
    );
  }
}

class _InlineErrorText extends StatelessWidget {
  final String message;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _InlineErrorText({
    required this.message,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          style: textTheme.bodySmall?.copyWith(
            color: colors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme textTheme;
  final String startDateLabel;
  final String endDateLabel;
  final VoidCallback onTapStartDate;
  final VoidCallback onTapEndDate;

  const _DateSection({
    required this.colors,
    required this.textTheme,
    required this.startDateLabel,
    required this.endDateLabel,
    required this.onTapStartDate,
    required this.onTapEndDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _DateRow(
            label: '시작일',
            dateLabel: startDateLabel,
            onTap: onTapStartDate,
            showDivider: true,
            colors: colors,
            textTheme: textTheme,
          ),
          _DateRow(
            label: '마감일',
            dateLabel: endDateLabel,
            onTap: onTapEndDate,
            showDivider: false,
            colors: colors,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final String dateLabel;
  final VoidCallback onTap;
  final bool showDivider;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _DateRow({
    required this.label,
    required this.dateLabel,
    required this.onTap,
    required this.showDivider,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: showDivider
              ? const BorderRadius.vertical(top: Radius.circular(12))
              : const BorderRadius.vertical(bottom: Radius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: colors.onSurface,
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: colors.outline.withValues(alpha: 0.6),
          ),
      ],
    );
  }
}

class _DurationInfo extends StatelessWidget {
  final int totalDays;
  final bool isValid;
  final ColorScheme colors;
  final TextTheme textTheme;
  final Color highlightColor;

  const _DurationInfo({
    required this.totalDays,
    required this.isValid,
    required this.colors,
    required this.textTheme,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isValid ? colors.surfaceContainerHighest : colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 20,
            color: isValid ? colors.onSurface : colors.error,
          ),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              style: textTheme.bodyLarge?.copyWith(
                color: isValid
                    ? colors.onSurface.withValues(alpha: 0.8)
                    : colors.error,
              ),
              children: [
                const TextSpan(text: '총 '),
                TextSpan(
                  text: isValid ? '$totalDays' : '0',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isValid ? highlightColor : colors.error,
                  ),
                ),
                const TextSpan(text: '일 동안'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorPickerSection extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme textTheme;
  final List<Map<String, Color>> presets;
  final int selectedIndex;
  final ValueChanged<int> onSelectPreset;
  final Color Function(Color) contrastOn;

  const _ColorPickerSection({
    required this.colors,
    required this.textTheme,
    required this.presets,
    required this.selectedIndex,
    required this.onSelectPreset,
    required this.contrastOn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '색감 선택',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(presets.length, (index) {
              final pastColor = presets[index]['past']!;
              final itemTodayColor = presets[index]['today']!;
              final isSelected = index == selectedIndex;
              final checkColor = contrastOn(itemTodayColor);

              return _ColorPresetItem(
                pastColor: pastColor,
                todayColor: itemTodayColor,
                isSelected: isSelected,
                checkColor: checkColor,
                onTap: () => onSelectPreset(index),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _ColorPresetItem extends StatelessWidget {
  final Color pastColor;
  final Color todayColor;
  final bool isSelected;
  final Color checkColor;
  final VoidCallback onTap;

  const _ColorPresetItem({
    required this.pastColor,
    required this.todayColor,
    required this.isSelected,
    required this.checkColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [pastColor, todayColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: todayColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: isSelected
            ? Icon(
                Icons.check_rounded,
                color: checkColor,
                size: 24,
              )
            : null,
      ),
    );
  }
}

class _WidgetBackgroundToggle extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme textTheme;
  final bool isWidgetDark;
  final ValueChanged<bool> onChanged;

  const _WidgetBackgroundToggle({
    required this.colors,
    required this.textTheme,
    required this.isWidgetDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '위젯 배경',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _WidgetOptionCard(
                label: '다크',
                isSelected: isWidgetDark,
                background: Colors.black,
                foreground: Colors.white,
                colors: colors,
                onTap: () => onChanged(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WidgetOptionCard(
                label: '라이트',
                isSelected: !isWidgetDark,
                background: Colors.white,
                foreground: Colors.black,
                colors: colors,
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WidgetOptionCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color background;
  final Color foreground;
  final ColorScheme colors;
  final VoidCallback onTap;

  const _WidgetOptionCard({
    required this.label,
    required this.isSelected,
    required this.background,
    required this.foreground,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? background
              : colors.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? foreground : colors.outline,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? foreground : colors.outline,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? foreground : colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isEditing;
  final ColorScheme colors;
  final TextTheme textTheme;
  final Color selectedTodayColor;
  final Color selectedOnColor;
  final VoidCallback onSave;

  const _SaveButton({
    required this.isEditing,
    required this.colors,
    required this.textTheme,
    required this.selectedTodayColor,
    required this.selectedOnColor,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedTodayColor,
          foregroundColor: selectedOnColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          isEditing ? '변경 저장' : '저장하기',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: selectedOnColor,
          ),
        ),
      ),
    );
  }
}
