import 'package:flutter/material.dart';
import 'package:my_todo_list_app/model/memo.dart';
import 'package:my_todo_list_app/model/todo_category_config.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/view/calendar_diary.dart';
import 'package:my_todo_list_app/view/settings_view.dart';
import 'package:my_todo_list_app/vm/database_handler.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarSchedule extends StatefulWidget {
  const CalendarSchedule({super.key});

  @override
  State<CalendarSchedule> createState() => _CalendarScheduleState();
}

class _CalendarScheduleState extends State<CalendarSchedule> {
  final db = DatabaseHandler();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<Memo>> memoMap = {};

  @override
  void initState() {
    super.initState();
    loadAllMemos();
  }

  String _dateKey(DateTime d) {
    return "${d.year.toString().padLeft(4, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.day.toString().padLeft(2, '0')}";
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _rangeLabel(Memo memo) {
    final start = DateTime.parse(memo.startDate);
    final end = DateTime.parse(memo.endDate);

    if (memo.startDate == memo.endDate) {
      return '${start.month}/${start.day}';
    }

    return '${start.month}/${start.day} - ${end.month}/${end.day}';
  }

  Future<void> _openDiaryPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CalendarDiary()),
    );

    if (!mounted) return;
    await loadAllMemos();
  }

  Future<void> _openSettingsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsView()),
    );
  }

  List<Memo> _memosForCalendarDay(DateTime day) {
    return memoMap[_dateKey(day)] ?? [];
  }

  Future<void> _pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onSelected,
    DateTime? firstDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2022, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );

    if (picked == null) return;
    onSelected(_normalizeDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = '${_focusedDay.year}년 ${_focusedDay.month}월';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0x8BCBFFF3),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final isCompactHeight = availableHeight < 760;
            final calendarRowHeight = isCompactHeight ? 54.0 : 64.0;
            final calendarHeight = isCompactHeight ? 410.0 : 470.0;

            return Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            monthLabel,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _openDiaryPage,
                            icon: const Icon(Icons.menu_book_outlined),
                            tooltip: 'Diary',
                          ),
                          IconButton(
                            onPressed: _openSettingsPage,
                            icon: const Icon(Icons.settings_outlined),
                            tooltip: 'Setting',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: calendarHeight,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFFD9D9D9),
                            blurRadius: 12,
                            offset: Offset(2, 4),
                          ),
                        ],
                      ),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2022, 1, 1),
                        lastDay: DateTime.utc(2100, 12, 31),
                        focusedDay: _focusedDay,
                        currentDay: DateTime.now(),
                        rowHeight: calendarRowHeight,
                        headerVisible: false,
                        availableGestures: AvailableGestures.horizontalSwipe,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            color: Dcolor.textColorGrey,
                            fontSize: 11,
                          ),
                          weekendStyle: const TextStyle(
                            color: Color(0xFFB6BCC4),
                            fontSize: 11,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            return _CalendarScheduleCell(
                              day: day,
                              memos: _memosForCalendarDay(day),
                              isSelected: isSameDay(_selectedDay, day),
                              isToday: isSameDay(day, DateTime.now()),
                              isOutside: day.month != _focusedDay.month,
                            );
                          },
                          todayBuilder: (context, day, focusedDay) {
                            return _CalendarScheduleCell(
                              day: day,
                              memos: _memosForCalendarDay(day),
                              isSelected: isSameDay(_selectedDay, day),
                              isToday: true,
                              isOutside: day.month != _focusedDay.month,
                            );
                          },
                          selectedBuilder: (context, day, focusedDay) {
                            return _CalendarScheduleCell(
                              day: day,
                              memos: _memosForCalendarDay(day),
                              isSelected: true,
                              isToday: isSameDay(day, DateTime.now()),
                              isOutside: day.month != _focusedDay.month,
                            );
                          },
                          outsideBuilder: (context, day, focusedDay) {
                            return _CalendarScheduleCell(
                              day: day,
                              memos: _memosForCalendarDay(day),
                              isSelected: isSameDay(_selectedDay, day),
                              isToday: isSameDay(day, DateTime.now()),
                              isOutside: true,
                            );
                          },
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: _selectedDay == null ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: IgnorePointer(
                        ignoring: _selectedDay != null,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: Text(
                            '날짜를 누르면 아래에서 메모 섹션이 열립니다',
                            style: TextStyle(
                              fontSize: 13,
                              color: Dcolor.defaultText.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: 0,
                  right: 0,
                  bottom: _selectedDay == null ? -360 : 0,
                  child: _BottomMemoPanel(
                    selectedDay: _selectedDay,
                    dateKey: _selectedDay == null
                        ? null
                        : _dateKey(_selectedDay!),
                    onAddMemo: _selectedDay == null
                        ? null
                        : () => _addMemo(_selectedDay!),
                    onClose: () {
                      setState(() {
                        _selectedDay = null;
                      });
                    },
                    rangeLabelBuilder: _rangeLabel,
                    db: db,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _addMemo(DateTime date) {
    final textController = TextEditingController();
    int selectedCategoryId = 1;
    DateTime startDate = _normalizeDate(date);
    DateTime endDate = _normalizeDate(date);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '메모 입력',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${date.month}월 ${date.day}일 기준 일정 등록',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: '메모 입력',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DateSelectRow(
                      label: '시작일',
                      value:
                          '${startDate.year}.${startDate.month.toString().padLeft(2, '0')}.${startDate.day.toString().padLeft(2, '0')}',
                      onTap: () async {
                        await _pickDate(
                          initialDate: startDate,
                          onSelected: (picked) {
                            setModalState(() {
                              startDate = picked;
                              if (endDate.isBefore(startDate)) {
                                endDate = startDate;
                              }
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _DateSelectRow(
                      label: '종료일',
                      value:
                          '${endDate.year}.${endDate.month.toString().padLeft(2, '0')}.${endDate.day.toString().padLeft(2, '0')}',
                      onTap: () async {
                        await _pickDate(
                          initialDate: endDate,
                          firstDate: startDate,
                          onSelected: (picked) {
                            setModalState(() {
                              endDate = picked;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: todoCategoryConfigs.map((category) {
                        final isSelected = selectedCategoryId == category.id;

                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedCategoryId = category.id;
                            });
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? category.backgroundColor
                                  : const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected
                                    ? category.accentColor
                                    : const Color(0xFFE3E7ED),
                              ),
                            ),
                            child: Text(
                              category.name,
                              style: TextStyle(
                                color: category.accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    backgroundColor: Dcolor.textColorGrey,
                    foregroundColor: Dcolor.defaultWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 38,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () async {
                    final text = textController.text.trim();
                    if (text.isEmpty) return;

                    await db.insertMemo(
                      text,
                      _dateKey(startDate),
                      selectedCategoryId,
                      startDate: _dateKey(startDate),
                      endDate: _dateKey(endDate),
                    );

                    await loadAllMemos();

                    if (!mounted) return;
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    setState(() {
                      _selectedDay = startDate;
                      _focusedDay = startDate;
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFBDECC6),
                    foregroundColor: Dcolor.defaultText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 38,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> loadAllMemos() async {
    final memos = await db.getAllMemos();
    final nextMemoMap = <String, List<Memo>>{};

    for (final memo in memos) {
      DateTime cursor = DateTime.parse(memo.startDate);
      final end = DateTime.parse(memo.endDate);

      while (!cursor.isAfter(end)) {
        final key = _dateKey(cursor);
        nextMemoMap.putIfAbsent(key, () => []).add(memo);
        cursor = cursor.add(const Duration(days: 1));
      }
    }

    if (!mounted) return;
    setState(() {
      memoMap = nextMemoMap;
    });
  }
}

class _DateSelectRow extends StatelessWidget {
  const _DateSelectRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Dcolor.textColorGrey),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Dcolor.defaultText,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.calendar_today_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CalendarScheduleCell extends StatelessWidget {
  const _CalendarScheduleCell({
    required this.day,
    required this.memos,
    required this.isSelected,
    required this.isToday,
    required this.isOutside,
  });

  final DateTime day;
  final List<Memo> memos;
  final bool isSelected;
  final bool isToday;
  final bool isOutside;

  @override
  Widget build(BuildContext context) {
    final textColor = isOutside
        ? const Color(0xFFD1D5DB)
        : day.weekday == DateTime.sunday
        ? const Color(0xFFF26D6D)
        : day.weekday == DateTime.saturday
        ? const Color(0xFF4D94FF)
        : const Color(0xFF20242A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFF76C7FF) : Colors.transparent,
              border: isSelected
                  ? Border.all(color: const Color(0xFF2D9CFF), width: 1.5)
                  : null,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isToday ? Colors.white : textColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          ...memos
              .take(1)
              .map(
                (memo) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: todoCategoryBackgroundColor(memo.categoryId),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      memo.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: todoCategoryAccentColor(memo.categoryId),
                      ),
                    ),
                  ),
                ),
              ),
          if (memos.length > 1)
            Text(
              '+${memos.length - 1}',
              style: TextStyle(fontSize: 8, color: Dcolor.textColorGrey),
            ),
        ],
      ),
    );
  }
}

class _BottomMemoPanel extends StatelessWidget {
  const _BottomMemoPanel({
    required this.selectedDay,
    required this.dateKey,
    required this.onAddMemo,
    required this.onClose,
    required this.rangeLabelBuilder,
    required this.db,
  });

  final DateTime? selectedDay;
  final String? dateKey;
  final VoidCallback? onAddMemo;
  final VoidCallback onClose;
  final String Function(Memo memo) rangeLabelBuilder;
  final DatabaseHandler db;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 320,
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6DBE2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  selectedDay == null
                      ? ''
                      : '${selectedDay!.month}월 ${selectedDay!.day}일',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Dcolor.defaultText,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 50,
              child: ElevatedButton(
                onPressed: onAddMemo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAF1E5),
                  foregroundColor: const Color(0xFF2D8B57),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  '메모 추가',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: dateKey == null
                  ? const SizedBox.shrink()
                  : FutureBuilder<List<Memo>>(
                      future: db.getMemosByDate(dateKey!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              '등록된 메모가 없습니다',
                              style: TextStyle(
                                fontSize: 14,
                                color: Dcolor.textColorGrey,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: snapshot.data!.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final memo = snapshot.data![index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: todoCategoryBackgroundColor(
                                  memo.categoryId,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: todoCategoryAccentColor(
                                        memo.categoryId,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          memo.content,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Dcolor.defaultText,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          rangeLabelBuilder(memo),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: todoCategoryAccentColor(
                                              memo.categoryId,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
