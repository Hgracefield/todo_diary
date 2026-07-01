import 'package:flutter/material.dart';
import 'package:my_todo_list_app/model/memo.dart';
import 'package:my_todo_list_app/model/todo_category_config.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/vm/database_handler.dart';

class MemoListPanel extends StatelessWidget {
  const MemoListPanel({
    super.key,
    required this.selectedDay,
    required this.db,
    required this.dateKey,
    required this.onAddMemo,
    required this.onToggleDone,
  });

  final DateTime? selectedDay;
  final DatabaseHandler db;
  final String Function(DateTime date) dateKey;
  final void Function(DateTime date) onAddMemo;
  final Future<void> Function(Memo memo) onToggleDone;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: const BoxDecoration(
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
                onPressed: selectedDay == null
                    ? null
                    : () => onAddMemo(selectedDay!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D9CFF),
                  foregroundColor: Dcolor.defaultWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("+ 메모 등록"),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _MemoList(
                selectedDay: selectedDay,
                db: db,
                dateKey: dateKey,
                onToggleDone: onToggleDone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoList extends StatelessWidget {
  const _MemoList({
    required this.selectedDay,
    required this.db,
    required this.dateKey,
    required this.onToggleDone,
  });

  final DateTime? selectedDay;
  final DatabaseHandler db;
  final String Function(DateTime date) dateKey;
  final Future<void> Function(Memo memo) onToggleDone;

  @override
  Widget build(BuildContext context) {
    if (selectedDay == null) {
      return const Text("날짜를 선택하세요");
    }

    return FutureBuilder<List<Memo>>(
      future: db.getMemosByDate(dateKey(selectedDay!)),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text("등록된 메모가 없습니다");
        }

        final memos = [...snapshot.data!]
          ..sort((a, b) => (b.memoId ?? 0).compareTo(a.memoId ?? 0));

        return ListView(
          padding: EdgeInsets.zero,
          children: memos
              .map(
                (memo) => _MemoListItem(
                  memo: memo,
                  onToggleDone: () => onToggleDone(memo),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MemoListItem extends StatelessWidget {
  const _MemoListItem({required this.memo, required this.onToggleDone});

  final Memo memo;
  final VoidCallback onToggleDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: onToggleDone,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: Center(
                child: memo.isDone
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: todoCategoryAccentColor(memo.categoryId),
                      )
                    : Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: todoCategoryAccentColor(memo.categoryId),
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${memo.time}:',
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              memo.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Dcolor.defaultText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
                decoration: memo.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
