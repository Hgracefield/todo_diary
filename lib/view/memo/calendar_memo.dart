import 'package:flutter/material.dart';
import 'package:my_todo_list_app/model/memo.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/view/account/account_page.dart';
import 'package:my_todo_list_app/view/memo/widgets/memo_calendar_card.dart';
import 'package:my_todo_list_app/view/memo/widgets/memo_form_dialog.dart';
import 'package:my_todo_list_app/view/memo/widgets/memo_list_panel.dart';
import 'package:my_todo_list_app/vm/database_handler.dart';

class CalendarMemo extends StatefulWidget {
  const CalendarMemo({super.key});

  @override
  State<CalendarMemo> createState() => _CalendarMemoState();
}

class _CalendarMemoState extends State<CalendarMemo> {
  static const _pageStartColor = Color(0x332D9CFF);

  final db = DatabaseHandler();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
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

  String _timeKey(TimeOfDay t) {
    return "${t.hour.toString().padLeft(2, '0')}:"
        "${t.minute.toString().padLeft(2, '0')}";
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
      resizeToAvoidBottomInset: true,
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
                Row(
                  children: [
                    Text(
                      'Month ${_focusedDay.month}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Dcolor.defaultText,
                        letterSpacing: 0,
                      ),
                    ),
                    const Spacer(),
                    const _PageBadge(
                      label: 'Memo',
                      backgroundColor: Color(0xFF2D9CFF),
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
                MemoCalendarCard(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  memoMap: memoMap,
                  dateKey: _dateKey,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                ),
                MemoListPanel(
                  selectedDay: _selectedDay,
                  db: db,
                  dateKey: _dateKey,
                  onAddMemo: _addMemo,
                  onToggleDone: _toggleMemoDone,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addMemo(DateTime date) {
    showDialog(
      context: context,
      builder: (context) {
        return MemoFormDialog(
          initialDate: date,
          onSave: (text, selectedDate, selectedTime, selectedCategoryId) async {
            await db.insertMemo(
              text.length > 100 ? text.substring(0, 100) : text,
              _dateKey(selectedDate),
              selectedCategoryId,
              time: _timeKey(selectedTime),
            );
            await loadAllMemos();

            if (!mounted) return;
            setState(() {
              _selectedDay = selectedDate;
              _focusedDay = selectedDate;
            });
          },
        );
      },
    );
  }

  Future<void> _toggleMemoDone(Memo memo) async {
    if (memo.memoId == null) return;
    await db.updateMemoDone(memo.memoId!, !memo.isDone);
    await loadAllMemos();
  }

  Future<void> loadAllMemos() async {
    final memos = await db.getAllMemos();

    memoMap.clear();
    for (final memo in memos) {
      memoMap.putIfAbsent(memo.date, () => []).add(memo);
    }

    setState(() {});
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
