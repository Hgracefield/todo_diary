import 'package:flutter/material.dart';
import 'package:my_todo_list_app/model/memo.dart';
import 'package:my_todo_list_app/model/todo_category_config.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:table_calendar/table_calendar.dart';

class MemoCalendarCard extends StatelessWidget {
  const MemoCalendarCard({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.memoMap,
    required this.dateKey,
    required this.onDaySelected,
  });

  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<String, List<Memo>> memoMap;
  final String Function(DateTime date) dateKey;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0xffdddddd),
            blurRadius: 12,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2022, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: focusedDay,
        headerVisible: false,
        rowHeight: 70,
        calendarStyle: CalendarStyle(
          weekendTextStyle: TextStyle(color: Dcolor.stickerBlue),
          todayDecoration: const BoxDecoration(
            color: Color(0xFF2D9CFF),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFFA3D1C6),
            shape: BoxShape.circle,
          ),
        ),
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: onDaySelected,
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
            final label = labels[day.weekday % 7];

            return Center(
              child: Text(
                label,
                style: TextStyle(
                  color: _weekdayColor(day),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
          defaultBuilder: (context, day, focusedDay) {
            return _MemoCalendarDayCell(
              day: day,
              isOutside: day.month != focusedDay.month,
            );
          },
          outsideBuilder: (context, day, focusedDay) {
            return _MemoCalendarDayCell(day: day, isOutside: true);
          },
          markerBuilder: (context, date, _) {
            final memos = memoMap[dateKey(date)];

            if (memos == null || memos.isEmpty) return null;

            return Positioned(
              bottom: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: memos.take(3).map((memo) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: todoCategoryAccentColor(memo.categoryId),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _weekdayColor(DateTime day, {bool isOutside = false}) {
    if (day.weekday == DateTime.sunday) return Dcolor.stickerRed;
    if (day.weekday == DateTime.saturday) return Dcolor.stickerBlue;
    return isOutside ? const Color(0xFFD1D5DB) : const Color(0xFF20242A);
  }
}

class _MemoCalendarDayCell extends StatelessWidget {
  const _MemoCalendarDayCell({required this.day, required this.isOutside});

  final DateTime day;
  final bool isOutside;

  @override
  Widget build(BuildContext context) {
    final color = day.weekday == DateTime.sunday
        ? Dcolor.stickerRed
        : day.weekday == DateTime.saturday
        ? Dcolor.stickerBlue
        : isOutside
        ? const Color(0xFFD1D5DB)
        : const Color(0xFF20242A);

    return Center(
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
