import 'package:flutter/material.dart';
import 'package:my_todo_list_app/model/diary.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/view/account/account_page.dart';
import 'package:my_todo_list_app/view/diary/diary_editor_view.dart';
import 'package:my_todo_list_app/view/home.dart';
import 'package:my_todo_list_app/vm/database_handler.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarDiary extends StatefulWidget {
  const CalendarDiary({super.key});

  @override
  State<CalendarDiary> createState() => _CalendarDiaryState();
}

class _CalendarDiaryState extends State<CalendarDiary> {
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

  Diary? _diaryForDate(DateTime date) {
    return diaryMap[_dateKey(date)];
  }

  void _openMemoTab() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Home(initialTabIndex: 1)),
    );
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
      backgroundColor: const Color(0xFFDDE4EA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
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
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Dcolor.defaultText,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<_DiaryAction>(
                          icon: Icon(
                            Icons.more_horiz,
                            color: Dcolor.textColorGrey,
                            size: 28,
                          ),
                          tooltip: 'Menu',
                          onSelected: (value) {
                            switch (value) {
                              case _DiaryAction.memo:
                                _openMemoTab();
                              case _DiaryAction.account:
                                _openAccountPage();
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _DiaryAction.memo,
                              child: Text('메모 화면으로 전환'),
                            ),
                            PopupMenuItem(
                              value: _DiaryAction.account,
                              child: Text('내 계정'),
                            ),
                          ],
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
                                onDaySelected: (selected, focused) async {
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
                                  weekendTextStyle: const TextStyle(
                                    color: Color(0xFF4D94FF),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  outsideTextStyle: const TextStyle(
                                    color: Color(0xFFD1D5DB),
                                    fontSize: 13,
                                  ),
                                  selectedDecoration: const BoxDecoration(
                                    color: Color(0xFF2D9CFF),
                                    shape: BoxShape.circle,
                                  ),
                                  todayDecoration: const BoxDecoration(
                                    color: Color(0xFF2D9CFF),
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
                                  weekendStyle: const TextStyle(
                                    color: Color(0xFFB6BCC4),
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
                                    final isWeekend =
                                        day.weekday == DateTime.sunday ||
                                        day.weekday == DateTime.saturday;

                                    return Center(
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isWeekend
                                              ? const Color(0xFFB6BCC4)
                                              : Dcolor.textColorGrey,
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
                                      isOutside: day.month != focusedDay.month,
                                    );
                                  },
                                  selectedBuilder: (context, day, focused) {
                                    return _CalendarCell(
                                      day: day,
                                      diary: _diaryForDate(day),
                                      isSelected: true,
                                      isToday: false,
                                      isOutside: day.month != focusedDay.month,
                                    );
                                  },
                                  todayBuilder: (context, day, focused) {
                                    return _CalendarCell(
                                      day: day,
                                      diary: _diaryForDate(day),
                                      isSelected: true,
                                      isToday: true,
                                      isOutside: day.month != focusedDay.month,
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
    );
  }
}

enum _DiaryAction { memo, account }

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    required this.diary,
    required this.isSelected,
    required this.isToday,
    required this.isOutside,
  });

  final DateTime day;
  final Diary? diary;
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
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isSelected || isToday
                  ? const Color(0xFF2D9CFF)
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
          if (diary != null && diary!.image.isNotEmpty)
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
