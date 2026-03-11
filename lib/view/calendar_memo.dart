import 'package:flutter/material.dart';
import 'package:my_todo_list_app/model/memo.dart';
import 'package:my_todo_list_app/model/todo_category_config.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
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

  @override
  void initState() {
    super.initState();
    loadAllMemos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Color(0x8BCBFFF3),

      // appBar: AppBar(
      //   foregroundColor: Dcolor.defaultText,
      //   backgroundColor:const Color(0x8BCBFFF3),
      // ),
      body: Column(
        children: [
          SizedBox(height: 50),
          // ───────── 상단 헤더 ─────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_focusedDay.year}년 ${_focusedDay.month}월",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.more_horiz),
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

              selectedDayPredicate: (day) =>
                  isSameDay(_selectedDay, day),

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

              padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text("메모 추가"),
                    ),
                  ),

                  SizedBox(height: 12),

                  Expanded(
                    child: _selectedDay == null
                        ? Text("날짜를 선택하세요")
                        : FutureBuilder(
                            future: db.getMemosByDate(
                              _dateKey(_selectedDay!),
                            ),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return Text("등록된 메모가 없습니다");
                              }

                              return ListView(
                                children: snapshot.data!
                                    .map(
                                      (m) => Padding(
                                        padding: EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Text("• ${m.content}"),
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
    int selectedCategoryId = 1; // 1: 할 일

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "메모 입력",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${date.month}월 ${date.day}일',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: "메모 입력",
                    ),
                  ),

                  ...todoCategoryConfigs.map(
                    (category) => SizedBox(
                      height: 30,
                      child: RadioListTile<int>(
                        value: category.id,
                        groupValue: selectedCategoryId,
                        title: Text(
                          category.name,
                          style: TextStyle(color: category.accentColor),
                        ),
                        visualDensity: VisualDensity.compact,
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() => selectedCategoryId = value);
                        },
                      ),
                    ),
                  ),
                ],
              ),

              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),

                  style: TextButton.styleFrom(
                    backgroundColor: Dcolor.textColorGrey,
                    foregroundColor: Dcolor.defaultWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 12,
                    ),
                  ),
                  child: Text("취소"),
                ),
                SizedBox(width: 10),
                TextButton(
                  onPressed: () async {
                    final text = textController.text.trim();
                    if (text.isEmpty) return;
                    await db.insertMemo(
                      text,
                      _dateKey(date),
                      selectedCategoryId,
                    );
                    await loadAllMemos();
                    Navigator.pop(context);
                    setState(() {});
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Color.fromARGB(81, 49, 170, 51),
                    foregroundColor: Dcolor.defaultText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 12,
                    ),
                  ),
                  child: Text("저장"),
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
