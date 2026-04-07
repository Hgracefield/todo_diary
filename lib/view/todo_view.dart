import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:my_todo_list_app/model/memo.dart';
import 'package:my_todo_list_app/model/todo_category_config.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/util/sub_functions.dart';
import 'package:my_todo_list_app/view/calendar_diary.dart';
import 'package:my_todo_list_app/vm/database_handler.dart';

class TodoView extends StatefulWidget {
  const TodoView({super.key});

  @override
  State<TodoView> createState() => _TodoViewState();
}

class _TodoViewState extends State<TodoView> {
  final db = DatabaseHandler();

  Future<void> _openDiaryPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CalendarDiary()),
    );

    if (!mounted) return;
    setState(() {});
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

  String _dateLabel(DateTime date) {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    final diff = date.difference(base).inDays;

    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'TOMORROW';
    if (diff == 2) return 'DAY AFTER TOMORROW';

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x8BCBFFF3),
      appBar: AppBar(
        toolbarHeight: 100,
        title: const Text(
          'MEMO LIST',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color.fromARGB(16, 203, 255, 243),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Open menu',
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) {
              if (value == 'diary') {
                _openDiaryPage();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(value: 'diary', child: Text('diary')),
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
                        'No memos yet.',
                        style: TextStyle(
                          fontSize: 16,
                          backgroundColor: Dcolor.stickerGreenV2,
                        ),
                      ),
                    ),
                  );
                }

                final grouped = _groupByDate(snapshot.data!);
                final dates = grouped.keys.toList()..sort();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: dates
                      .map((date) => _dateSection(date, grouped[date]!))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateSection(DateTime date, List<Memo> memos) {
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
            _dateLabel(date),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Dcolor.defaultText,
            ),
          ),
          Text(
            '${date.month}/${date.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Dcolor.textColorGrey,
            ),
          ),
          const SizedBox(height: 12),
          ...memos.map(_memoRow),
        ],
      ),
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
                        IconButton(
                          icon: Icon(
                            m.isDone
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: todoCategoryAccentColor(m.categoryId),
                            size: 33,
                          ),
                          onPressed: () async {
                            final next = !m.isDone;
                            await db.updateMemoDone(m.memoId!, next);
                            setState(() {
                              m.isDone = next;
                            });
                          },
                        ),
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
                    (category) => RadioListTile<int>(
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

                    await db.updateMemo(memo.memoId!, text, selectedCategoryId);

                    Navigator.pop(context);
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
}
