import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'main.dart';
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
  String? _nameError; // 이름 에러 메시지
  String? _dateError; // 날짜 에러 메시지

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
    final initialDate = isStartDate ? _startDate : _endDate;
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
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

  /// 저장 버튼 클릭 처리
  void _onSave() {
    final name = _nameController.text.trim();

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

    // D-Day 저장
    final dday = DDayModel(
      name: name,
      startDate: _startDate,
      endDate: _endDate,
    );

    context.read<DDayProvider>().saveDDay(dday);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // 키보드 높이 고려
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 그랩 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // 타이틀
            Text(
              widget.existingDDay != null ? '디데이 수정' : '디데이 추가',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 28),
            // 이름 입력 필드
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '디데이 이름',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            // 이름 에러 메시지 표시
            if (_nameError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _nameError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // 날짜 선택 컨테이너
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // 시작일 선택
                  _buildDateRow(
                    label: '시작일',
                    date: _startDate,
                    onTap: () => _selectDate(true),
                    showDivider: true,
                  ),
                  // 마감일 선택
                  _buildDateRow(
                    label: '마감일',
                    date: _endDate,
                    onTap: () => _selectDate(false),
                    showDivider: false,
                  ),
                ],
              ),
            ),
            // 날짜 에러 메시지 표시
            if (_dateError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _dateError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // 총 기간 표시 컨테이너
            _buildDurationInfo(),
            const SizedBox(height: 24),
            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  widget.existingDDay != null ? '수정 완료' : '디데이 추가',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 날짜 선택 Row 위젯
  Widget _buildDateRow({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
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
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _isToday(date) ? '오늘' : _formatDate(date),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF4CAF50),
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
            color: Colors.grey[300],
          ),
      ],
    );
  }

  /// 총 기간 계산
  int get _totalDays {
    return _endDate.difference(_startDate).inDays + 1;
  }

  /// 총 기간 표시 위젯
  Widget _buildDurationInfo() {
    final days = _totalDays;
    final isValid = days > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isValid ? const Color(0xFFE8F5E9) : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 20,
            color: isValid ? const Color(0xFF2E7D32) : Colors.redAccent,
          ),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 16,
                color: isValid ? Colors.grey[700] : Colors.redAccent,
              ),
              children: [
                const TextSpan(text: '총 '),
                TextSpan(
                  text: isValid ? '$days' : '0',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isValid ? const Color(0xFF2E7D32) : Colors.redAccent,
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
