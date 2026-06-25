import 'package:flutter/material.dart';
import 'package:my_todo_list_app/model/memo.dart';
import 'package:my_todo_list_app/model/todo_category_config.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/view/account/account_page.dart';
import 'package:my_todo_list_app/view/diary/calendar_diary.dart';
import 'package:my_todo_list_app/vm/database_handler.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarMemo extends StatefulWidget {
  const CalendarMemo({super.key});

  @override
  State<CalendarMemo> createState() => _CalendarMemoState();
}

class _CalendarMemoState extends State<CalendarMemo> {
  final db = DatabaseHandler();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<Memo>> memoMap = {}; // 메모 카테고리 맵
  String _dateKey(DateTime d) {
    return "${d.year.toString().padLeft(4, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.day.toString().padLeft(2, '0')}";
  }

  String _timeKey(TimeOfDay t) {
    return "${t.hour.toString().padLeft(2, '0')}:"
        "${t.minute.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    loadAllMemos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0x8BCBFFF3),

      // appBar: AppBar(
      //   foregroundColor: Dcolor.defaultText,
      //   backgroundColor: const Color(0x8BCBFFF3),
      // ),
      body: Column(
        children: [
          SizedBox(height: 55),
          // ───────── 상단 헤더 ─────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    "${_focusedDay.year}년 ${_focusedDay.month}월",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: PopupMenuButton<_CalendarMemoAction>(
                    icon: const Icon(Icons.more_horiz),
                    tooltip: 'Menu',
                    onSelected: (value) {
                      switch (value) {
                        case _CalendarMemoAction.diary:
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CalendarDiary(),
                            ),
                          );
                        case _CalendarMemoAction.account:
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AccountPage(),
                            ),
                          );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _CalendarMemoAction.diary,
                        child: Text('다이어리로 전환'),
                      ),
                      PopupMenuItem(
                        value: _CalendarMemoAction.account,
                        child: Text('내 계정'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // ───────── 달력 ─────────
          Container(
            height: 500,
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffdddddd),
                  blurRadius: 12,
                  offset: Offset(2, 4),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2022, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              rowHeight: 70,
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Color(0xFFE67E22),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFFA3D1C6),
                  shape: BoxShape.circle,
                ),
              ),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },

              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),

              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, _) {
                  final key = _dateKey(date);
                  final memos = memoMap[key];

                  if (memos == null || memos.isEmpty) return null;

                  return Positioned(
                    bottom: 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: memos.take(3).map((m) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 1),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: todoCategoryAccentColor(m.categoryId),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),

          // ───────── 메모 영역 ─────────
          Expanded(
            child: Container(
              width: MediaQuery.of(context).size.width,

              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _selectedDay == null
                          ? null
                          : () => _addMemo(_selectedDay!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Dcolor.stickerOrange,
                        foregroundColor: Dcolor.defaultWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text("+ 메모 등록"),
                    ),
                  ),

                  SizedBox(height: 8),

                  Expanded(
                    child: _selectedDay == null
                        ? Text("날짜를 선택하세요")
                        : FutureBuilder(
                            future: db.getMemosByDate(_dateKey(_selectedDay!)),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Text("등록된 메모가 없습니다");
                              }
                              final memos = [...snapshot.data!]
                                ..sort(
                                  (a, b) =>
                                      (b.memoId ?? 0).compareTo(a.memoId ?? 0),
                                );

                              return ListView(
                                padding: EdgeInsets.zero,
                                children: memos
                                    .map(
                                      (m) => Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          "${m.time}  • ${m.content}",
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────── 메모 추가 다이얼로그 ─────────
  void _addMemo(DateTime date) {
    final textController = TextEditingController();
    DateTime selectedDate = date;
    TimeOfDay selectedTime = TimeOfDay.now();
    int selectedCategoryId = 1; // 1: 할 일

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              constraints: BoxConstraints(maxWidth: 360),
              contentPadding: EdgeInsets.fromLTRB(20, 25, 20, 0),
              actionsPadding: EdgeInsets.fromLTRB(20, 12, 20, 16),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "메모 입력",
                      style: TextStyle(
                        color: Dcolor.defaultText,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2022, 1, 1),
                                lastDate: DateTime(2100, 12, 31),
                              );

                              if (pickedDate == null) return;
                              setModalState(() => selectedDate = pickedDate);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 34,
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFFCCCCCC)),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 15,
                                    color: Color(0xFF666666),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '${selectedDate.month}월 ${selectedDate.day}일',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );

                              if (pickedTime == null) return;
                              setModalState(() => selectedTime = pickedTime);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 34,
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFFCCCCCC)),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Color(0xFF666666),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    _timeKey(selectedTime),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: todoCategoryConfigs.map((category) {
                        final isSelected = selectedCategoryId == category.id;

                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: category == todoCategoryConfigs.last
                                  ? 0
                                  : 8,
                            ),
                            child: InkWell(
                              onTap: () {
                                setModalState(
                                  () => selectedCategoryId = category.id,
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? category.accentColor
                                      : Colors.white,
                                  border: Border.all(
                                    color: category.accentColor,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : category.accentColor,
                                    fontSize: 14,

                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: TextField(
                        controller: textController,
                        maxLength: 100,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: "메모 입력",
                          contentPadding: EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xFF333333),
                          foregroundColor: Dcolor.defaultWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text("취소", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final text = textController.text.trim();
                          if (text.isEmpty) return;
                          final navigator = Navigator.of(context);
                          await db.insertMemo(
                            text.length > 100 ? text.substring(0, 100) : text,
                            _dateKey(selectedDate),
                            selectedCategoryId,
                            time: _timeKey(selectedTime),
                          );
                          await loadAllMemos();
                          navigator.pop();
                          setState(() {
                            _selectedDay = selectedDate;
                            _focusedDay = selectedDate;
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Dcolor.stickerGreen,
                          foregroundColor: Dcolor.defaultWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text("저장", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ========== functions===========
  Future<void> loadAllMemos() async {
    final memos = await db.getAllMemos();

    memoMap.clear();
    for (var m in memos) {
      memoMap.putIfAbsent(m.date, () => []).add(m);
    }

    setState(() {});
  }
} // class

enum _CalendarMemoAction { diary, account }
