import 'package:flutter/material.dart';
import 'package:my_todo_list_app/model/diary.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/view/account/account_page.dart';
import 'package:my_todo_list_app/view/diary/diary_editor_view.dart';
import 'package:my_todo_list_app/vm/database_handler.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarDiary extends StatefulWidget {
  const CalendarDiary({super.key});

  @override
  State<CalendarDiary> createState() => _CalendarDiaryState();
}

class _CalendarDiaryState extends State<CalendarDiary> {
  static const _pageStartColor = Color(0x33E67E22);

  final db = DatabaseHandler();

  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay = DateTime.now();
  bool isLoading = true;
  Map<String, Diary> diaryMap = {};

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  String _dateKey(DateTime d) {
    return "${d.year.toString().padLeft(4, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.day.toString().padLeft(2, '0')}";
  }

  bool _isTodayOrPast(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return !target.isAfter(today);
  }

  Future<void> _loadDiaries() async {
    final diaries = await db.getDiaryList();
    final nextMap = <String, Diary>{};

    for (final diary in diaries) {
      nextMap[diary.diaryDate] = diary;
    }

    if (!mounted) return;

    setState(() {
      diaryMap = nextMap;
      isLoading = false;
    });
  }

  Future<void> _openDiaryEditor(DateTime date) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => DiaryEditorView(date: date)),
    );

    if (saved == true) {
      await _loadDiaries();
    }
  }

  Future<bool> _confirmOpenDiaryEditor() async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          content: Text(
            '당신의 역사를 작성하시겠습니까?',
            style: TextStyle(
              color: Dcolor.defaultText,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF333333),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('닫기'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFE67E22),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('작성하기'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    return shouldOpen == true;
  }

  Diary? _diaryForDate(DateTime date) {
    return diaryMap[_dateKey(date)];
  }

  void _openAccountPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AccountPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_pageStartColor, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Month ${focusedDay.month}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Dcolor.defaultText,
                              letterSpacing: 0,
                            ),
                          ),
                          const Spacer(),
                          const _PageBadge(
                            label: 'Diary',
                            backgroundColor: Color(0xFFE67E22),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.person_outline,
                              color: Dcolor.textColorGrey,
                              size: 28,
                            ),
                            tooltip: '내 계정',
                            onPressed: _openAccountPage,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : TableCalendar(
                                  firstDay: DateTime.utc(2022, 1, 1),
                                  lastDay: DateTime.utc(2100, 12, 31),
                                  focusedDay: focusedDay,
                                  currentDay: DateTime.now(),
                                  headerVisible: false,
                                  availableGestures:
                                      AvailableGestures.horizontalSwipe,
                                  rowHeight: 92,
                                  sixWeekMonthsEnforced: true,
                                  selectedDayPredicate: (day) =>
                                      isSameDay(selectedDay, day),
                                  enabledDayPredicate: _isTodayOrPast,
                                  onDaySelected: (selected, focused) async {
                                    final hasDiary =
                                        _diaryForDate(selected) != null;
                                    if (!hasDiary) {
                                      final shouldOpen =
                                          await _confirmOpenDiaryEditor();
                                      if (!shouldOpen) return;
                                    }

                                    setState(() {
                                      selectedDay = selected;
                                      focusedDay = focused;
                                    });
                                    await _openDiaryEditor(selected);
                                  },
                                  onPageChanged: (focused) {
                                    setState(() {
                                      focusedDay = focused;
                                    });
                                  },
                                  calendarStyle: CalendarStyle(
                                    outsideDaysVisible: true,
                                    defaultTextStyle: TextStyle(
                                      color: Dcolor.defaultText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    weekendTextStyle: TextStyle(
                                      color: Dcolor.stickerBlue,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    outsideTextStyle: const TextStyle(
                                      color: Color(0xFFD1D5DB),
                                      fontSize: 13,
                                    ),
                                    selectedDecoration: const BoxDecoration(
                                      color: Color(0xFFE67E22),
                                      shape: BoxShape.circle,
                                    ),
                                    todayDecoration: const BoxDecoration(
                                      color: Color(0xFFE67E22),
                                      shape: BoxShape.circle,
                                    ),
                                    cellMargin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 10,
                                    ),
                                    tablePadding: EdgeInsets.zero,
                                  ),
                                  daysOfWeekHeight: 28,
                                  daysOfWeekStyle: DaysOfWeekStyle(
                                    weekdayStyle: TextStyle(
                                      color: Dcolor.textColorGrey,
                                      fontSize: 11,
                                    ),
                                    weekendStyle: TextStyle(
                                      color: Dcolor.stickerBlue,
                                      fontSize: 11,
                                    ),
                                  ),
                                  calendarBuilders: CalendarBuilders(
                                    dowBuilder: (context, day) {
                                      const labels = [
                                        'Sun',
                                        'Mon',
                                        'Tue',
                                        'Wed',
                                        'Thu',
                                        'Fri',
                                        'Sat',
                                      ];
                                      final label = labels[day.weekday % 7];
                                      final color =
                                          day.weekday == DateTime.sunday
                                          ? Dcolor.stickerRed
                                          : day.weekday == DateTime.saturday
                                          ? Dcolor.stickerBlue
                                          : Dcolor.textColorGrey;

                                      return Center(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: color,
                                          ),
                                        ),
                                      );
                                    },
                                    defaultBuilder: (context, day, focused) {
                                      return _CalendarCell(
                                        day: day,
                                        diary: _diaryForDate(day),
                                        isSelected: false,
                                        isToday: isSameDay(day, DateTime.now()),
                                        isOutside:
                                            day.month != focusedDay.month,
                                      );
                                    },
                                    selectedBuilder: (context, day, focused) {
                                      return _CalendarCell(
                                        day: day,
                                        diary: _diaryForDate(day),
                                        isSelected: true,
                                        isToday: false,
                                        isOutside:
                                            day.month != focusedDay.month,
                                      );
                                    },
                                    todayBuilder: (context, day, focused) {
                                      return _CalendarCell(
                                        day: day,
                                        diary: _diaryForDate(day),
                                        isSelected: true,
                                        isToday: true,
                                        isOutside:
                                            day.month != focusedDay.month,
                                      );
                                    },
                                    outsideBuilder: (context, day, focused) {
                                      return _CalendarCell(
                                        day: day,
                                        diary: _diaryForDate(day),
                                        isSelected: false,
                                        isToday: false,
                                        isOutside: true,
                                      );
                                    },
                                    disabledBuilder: (context, day, focused) {
                                      return _CalendarCell(
                                        day: day,
                                        diary: _diaryForDate(day),
                                        isSelected: false,
                                        isToday: false,
                                        isOutside:
                                            day.month != focusedDay.month,
                                        isDisabled: true,
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageBadge extends StatelessWidget {
  const _PageBadge({required this.label, required this.backgroundColor});

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    required this.diary,
    required this.isSelected,
    required this.isToday,
    required this.isOutside,
    this.isDisabled = false,
  });

  final DateTime day;
  final Diary? diary;
  final bool isSelected;
  final bool isToday;
  final bool isOutside;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final textColor = isDisabled
        ? const Color(0xFFD1D5DB)
        : isOutside
        ? day.weekday == DateTime.sunday
              ? Dcolor.stickerRed
              : day.weekday == DateTime.saturday
              ? Dcolor.stickerBlue
              : const Color(0xFFD1D5DB)
        : day.weekday == DateTime.sunday
        ? Dcolor.stickerRed
        : day.weekday == DateTime.saturday
        ? Dcolor.stickerBlue
        : const Color(0xFF20242A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isSelected || isToday
                  ? const Color(0xFFE67E22)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected || isToday ? Colors.white : textColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (!isDisabled && diary != null && diary!.image.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                diary!.image,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 40,
                    height: 40,
                    color: const Color(0xFFE5E7EB),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
