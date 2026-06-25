import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:my_todo_list_app/model/memo.dart';
import 'package:my_todo_list_app/model/todo_category_config.dart';
import 'package:my_todo_list_app/storage/session_storage.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/util/sub_functions.dart';
import 'package:my_todo_list_app/view/account/account_page.dart';
import 'package:my_todo_list_app/view/diary/calendar_diary.dart';
import 'package:my_todo_list_app/view/login/login_page.dart';
import 'package:my_todo_list_app/vm/database_handler.dart';

class TodoView extends StatefulWidget {
  const TodoView({super.key, required this.onMemoTabRequested});

  final VoidCallback onMemoTabRequested;

  @override
  State<TodoView> createState() => _TodoViewState();
}

class _TodoViewState extends State<TodoView> {
  final db = DatabaseHandler();

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
        title: Text('Life-LOG', style: TextStyle(fontWeight: FontWeight.w500)),
        leadingWidth: 74,
        leading: TextButton(
          onPressed: _logout,
          style: TextButton.styleFrom(
            foregroundColor: Color(0xFF222222),
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            '로그아웃',
            style: TextStyle(
              color: Color(0xFF222222),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        backgroundColor: Color.fromARGB(16, 203, 255, 243),
        actions: [
          TextButton(
            onPressed: widget.onMemoTabRequested,
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF222222),
              padding: EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '+ 메모',
              style: TextStyle(
                color: Color(0xFF222222),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          PopupMenuButton<_HomeAction>(
            icon: Icon(Icons.more_horiz),
            tooltip: 'Menu',
            onSelected: (value) {
              switch (value) {
                case _HomeAction.diary:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalendarDiary(),
                    ),
                  );
                case _HomeAction.account:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountPage(),
                    ),
                  );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _HomeAction.diary, child: Text('다이어리로 전환')),
              PopupMenuItem(value: _HomeAction.account, child: Text('내 계정')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Memo>>(
              future: db.getAllMemos(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: SizedBox(
                      width: 320,
                      child: Text(
                        '오늘의 생각이나 일정을 가볍게 남겨보세요.',
                        style: TextStyle(
                          fontSize: 16,
                          backgroundColor: Dcolor.stickerGreenV2,
                        ),
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
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateSection(
    DateTime? date,
    List<Memo> memos, {
    String? title,
    bool showDate = true,
  }) {
    final sortedMemos = [...memos]
      ..sort((a, b) => _memoDateTime(a).compareTo(_memoDateTime(b)));
    final activeMemos = sortedMemos.where((memo) => !memo.isDone).toList();
    final completedMemos = sortedMemos.where((memo) => memo.isDone).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 20),
      decoration: BoxDecoration(
        color: Dcolor.defaultWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? _dateLabel(date!),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: Dcolor.defaultText,
            ),
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
          ...activeMemos.map(_memoRow),
          if (completedMemos.isNotEmpty) ...[
            const SizedBox(height: 4),
            _completedSectionHeader(),
            const SizedBox(height: 12),
            ...completedMemos.map(_memoRow),
          ],
        ],
      ),
    );
  }

  Widget _completedSectionHeader() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Dcolor.textColorGrey.withValues(alpha: 0.35),
            thickness: 1,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '완료',
          style: TextStyle(
            color: Dcolor.defaultText,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _memoRow(Memo m) {
    return GestureDetector(
      onTap: () => _editMemo(m),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        height: 55,
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
                  setState(() {});
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
                          child: Text(
                            limitText(m.content),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              fontSize: 15,
                              color: Dcolor.defaultText,
                            ),
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
    int selectedCategoryId = memo.categoryId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final memoDate = DateTime.parse(memo.date);

            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Memo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${memoDate.month}/${memoDate.day}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(hintText: 'Enter memo'),
                  ),
                  ...todoCategoryConfigs.map(
                    (category) => _categoryOption(
                      name: category.name,
                      accentColor: category.accentColor,
                      isSelected: selectedCategoryId == category.id,
                      onTap: () {
                        setModalState(() => selectedCategoryId = category.id);
                      },
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () async {
                    final text = textController.text.trim();
                    if (text.isEmpty) return;
                    final navigator = Navigator.of(context);

                    await db.updateMemo(memo.memoId!, text, selectedCategoryId);

                    navigator.pop();
                    setState(() {});
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    await SessionStorage.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _categoryOption({
    required String name,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: accentColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(name, style: TextStyle(color: accentColor)),
          ],
        ),
      ),
    );
  }
}

enum _HomeAction { diary, account }
