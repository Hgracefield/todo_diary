import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:my_todo_list_app/model/memo.dart';
import 'package:my_todo_list_app/model/todo_category_config.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/util/sub_functions.dart';
import 'package:my_todo_list_app/view/account/account_page.dart';
import 'package:my_todo_list_app/vm/database_handler.dart';

class LifeLogHome extends StatefulWidget {
  const LifeLogHome({super.key, this.onAddMemoPressed});

  final VoidCallback? onAddMemoPressed;

  @override
  State<LifeLogHome> createState() => _LifeLogHomeState();
}

class _LifeLogHomeState extends State<LifeLogHome> {
  final db = DatabaseHandler();
  late Future<List<Memo>> _memosFuture;

  @override
  void initState() {
    super.initState();
    _memosFuture = db.getAllMemos();
  }

  void _reloadMemos() {
    _memosFuture = db.getAllMemos();
  }

  Map<DateTime, List<Memo>> _groupByDate(List<Memo> memos) {
    final Map<DateTime, List<Memo>> grouped = {};

    for (final memo in memos) {
      final d = DateTime.parse(memo.date);
      final key = DateTime(d.year, d.month, d.day);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(memo);
    }

    return grouped;
  }

  DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _memoDateTime(Memo memo) {
    final date = DateTime.parse(memo.date);
    final timeParts = memo.time.split(':');
    final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

    return DateTime(date.year, date.month, date.day, hour, minute);
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

  TimeOfDay _memoTime(Memo memo) {
    final timeParts = memo.time.split(':');
    final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _dateLabel(DateTime date) {
    final base = _todayDate();
    final diff = date.difference(base).inDays;

    if (diff == 0) return '오늘';
    if (diff == 1) return 'D - 1';

    return '${date.month}. ${date.day}.';
  }

  String _dateSubtitle(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.month}. ${date.day}. (${weekdays[date.weekday - 1]}요일)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Color(0x8B99CCC2),
      backgroundColor: Color(0x8BCBFFF3),
      appBar: AppBar(
        toolbarHeight: 80,
        titleSpacing: 16,
        centerTitle: false,
        title: Text(
          'Life-LOG',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Dcolor.defaultText,
            letterSpacing: 0,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Color(0x8BCBFFF3),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, size: 28),
            tooltip: '내 계정',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x8BCBFFF3), Colors.white],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<Memo>>(
                future: _memosFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: SizedBox(
                        width: 320,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '오늘의 생각이나 일정을 가볍게 남겨보세요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                backgroundColor: Dcolor.stickerGreenV2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: widget.onAddMemoPressed,
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('메모 입력'),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: const Color(0xFFA3D1C6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final today = _todayDate();
                  final grouped = _groupByDate(snapshot.data!);
                  final dates = grouped.keys.toList()
                    ..sort((a, b) => a.compareTo(b));
                  final visibleDates = dates.where((date) {
                    final diff = date.difference(today).inDays;
                    return diff >= 0 && diff <= 1;
                  }).toList();
                  final futureMemos =
                      snapshot.data!.where((memo) {
                        final memoDate = DateTime.parse(memo.date);
                        final key = DateTime(
                          memoDate.year,
                          memoDate.month,
                          memoDate.day,
                        );
                        return key.difference(today).inDays > 1;
                      }).toList()..sort(
                        (a, b) => _memoDateTime(a).compareTo(_memoDateTime(b)),
                      );

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...visibleDates.map(
                        (date) => _dateSection(date, grouped[date]!),
                      ),
                      if (futureMemos.isNotEmpty)
                        _dateSection(
                          null,
                          futureMemos,
                          title: '미래',
                          showDate: false,
                          showMemoDate: true,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateSection(
    DateTime? date,
    List<Memo> memos, {
    String? title,
    bool showDate = true,
    bool showMemoDate = false,
  }) {
    final sortedMemos = [...memos]
      ..sort((a, b) => _memoDateTime(a).compareTo(_memoDateTime(b)));
    final activeMemos = sortedMemos.where((memo) => !memo.isDone).toList();
    final completedMemos = sortedMemos.where((memo) => memo.isDone).toList();
    final sectionTitle = title ?? _dateLabel(date!);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: Dcolor.defaultWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sectionTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Dcolor.defaultText,
                  ),
                ),
              ),
              Text(
                '${completedMemos.length}/${sortedMemos.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Dcolor.textColorGrey,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          if (showDate && date != null)
            Text(
              _dateSubtitle(date),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Dcolor.textColorGrey,
              ),
            ),
          const SizedBox(height: 12),
          ...activeMemos.map(
            (memo) => _memoRow(memo, showDateLabel: showMemoDate),
          ),
          if (completedMemos.isNotEmpty) ...[
            const SizedBox(height: 4),
            _completedSectionHeader(),
            const SizedBox(height: 12),
            ...completedMemos.map(
              (memo) => _memoRow(memo, showDateLabel: showMemoDate),
            ),
          ],
        ],
      ),
    );
  }

  Widget _completedSectionHeader() {
    return Column(
      children: [
        Divider(
          color: Dcolor.textColorGrey.withValues(alpha: 0.35),
          thickness: 1,
        ),
        Text(
          '완료',
          style: TextStyle(
            color: Dcolor.defaultText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _memoRow(Memo m, {bool showDateLabel = false}) {
    return GestureDetector(
      onTap: () => _editMemo(m),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        height: showDateLabel ? 68 : 55,
        child: Slidable(
          key: ValueKey(m.memoId),
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.3,
            children: [
              SlidableAction(
                alignment: Alignment.center,
                onPressed: (context) async {
                  await db.deleteMemo(m.memoId!);
                  setState(_reloadMemos);
                },
                backgroundColor: Dcolor.stickerRemove,
                borderRadius: BorderRadius.circular(10),
                label: 'Delete',
                icon: Icons.delete_outline,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: todoCategoryBackgroundColor(m.categoryId),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: todoCategoryAccentColor(m.categoryId),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showDateLabel) ...[
                                Text(
                                  _futureMemoDateLabel(m),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Dcolor.textColorGrey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                limitText(m.content),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Dcolor.defaultText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _memoDoneAction(m),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _futureMemoDateLabel(Memo memo) {
    final date = DateTime.parse(memo.date);
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.month}. ${date.day}. (${weekdays[date.weekday - 1]})';
  }

  Widget _memoDoneAction(Memo memo) {
    final accentColor = todoCategoryAccentColor(memo.categoryId);

    return TextButton(
      onPressed: () async {
        final next = !memo.isDone;
        await db.updateMemoDone(memo.memoId!, next);
        setState(() {
          memo.isDone = next;
        });
      },
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: memo.isDone
          ? Text(
              '완료',
              style: TextStyle(
                color: accentColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            )
          : Icon(Icons.circle_outlined, color: accentColor, size: 33),
    );
  }

  void _editMemo(Memo memo) {
    final textController = TextEditingController(text: memo.content);
    DateTime selectedDate = DateTime.parse(memo.date);
    TimeOfDay selectedTime = _memoTime(memo);
    int selectedCategoryId = memo.categoryId;

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

                          await db.updateMemo(
                            memo.memoId!,
                            text.length > 100 ? text.substring(0, 100) : text,
                            selectedCategoryId,
                            date: _dateKey(selectedDate),
                            time: _timeKey(selectedTime),
                          );

                          navigator.pop();
                          setState(_reloadMemos);
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
}
