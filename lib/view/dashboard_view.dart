import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:my_todo_list_app/model/memo.dart';
import 'package:my_todo_list_app/model/todo_category_config.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/util/sub_functions.dart';
import 'package:my_todo_list_app/view/calendar_diary.dart';
import 'package:my_todo_list_app/vm/database_handler.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final db = DatabaseHandler();

  Future<void> _openDiaryPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CalendarDiary()),
    );

    if (!mounted) return;
    setState(() {});
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _includesDay(Memo memo, DateTime day) {
    final normalizedDay = _normalizeDate(day);
    final start = _normalizeDate(DateTime.parse(memo.startDate));
    final end = _normalizeDate(DateTime.parse(memo.endDate));
    return !normalizedDay.isBefore(start) && !normalizedDay.isAfter(end);
  }

  String _dateRangeLabel(Memo memo) {
    final start = DateTime.parse(memo.startDate);
    final end = DateTime.parse(memo.endDate);

    if (_isSameDay(start, end)) {
      return '${start.month}/${start.day}';
    }

    return '${start.month}/${start.day} - ${end.month}/${end.day}';
  }

  List<Memo> _todayMemos(List<Memo> memos) {
    final today = _normalizeDate(DateTime.now());
    return memos.where((memo) => _includesDay(memo, today)).toList()
      ..sort(
        (a, b) => DateTime.parse(a.startDate).compareTo(
          DateTime.parse(b.startDate),
        ),
      );
  }

  List<Memo> _upcomingMemos(List<Memo> memos) {
    final today = _normalizeDate(DateTime.now());
    return memos
        .where((memo) {
          final start = _normalizeDate(DateTime.parse(memo.startDate));
          final end = _normalizeDate(DateTime.parse(memo.endDate));
          return start.isAfter(today) && !end.isBefore(today);
        })
        .toList()
      ..sort(
        (a, b) => DateTime.parse(a.startDate).compareTo(
          DateTime.parse(b.startDate),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x8BCBFFF3),
      appBar: AppBar(
        toolbarHeight: 90,
        title: const Text(
          'HOME DASHBOARD',
          style: TextStyle(fontWeight: FontWeight.w600),
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
      body: FutureBuilder<List<Memo>>(
        future: db.getAllMemos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allMemos = snapshot.data!;
          final todayMemos = _todayMemos(allMemos);
          final incompleteToday = todayMemos.where((memo) => !memo.isDone).toList();
          final completeToday = todayMemos.where((memo) => memo.isDone).toList();
          final upcomingMemos = _upcomingMemos(allMemos).take(4).toList();
          final completionRate = todayMemos.isEmpty
              ? 0.0
              : completeToday.length / todayMemos.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _heroSummaryCard(
                totalToday: todayMemos.length,
                completeCount: completeToday.length,
                incompleteCount: incompleteToday.length,
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: '오늘 할 일',
                subtitle: '오늘 처리해야 하는 미완료 메모',
                child: incompleteToday.isEmpty
                    ? _emptyText('오늘 할 일이 비어 있어요')
                    : Column(
                        children: incompleteToday
                            .map((memo) => _memoRow(memo))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: '가까운 일정',
                subtitle: '곧 다가오는 다음 일정',
                child: upcomingMemos.isEmpty
                    ? _emptyText('가까운 일정이 아직 없어요')
                    : Column(
                        children: upcomingMemos
                            .map((memo) => _schedulePreviewRow(memo))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: '오늘 일정 요약',
                subtitle: '완료 / 미완료 상태를 한 번에 보기',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _summaryCountCard(
                            label: '완료',
                            count: completeToday.length,
                            color: const Color(0xFF61B38A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _summaryCountCard(
                            label: '미완료',
                            count: incompleteToday.length,
                            color: const Color(0xFF4D94FF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _summarySubsection(
                      title: '완료',
                      memos: completeToday,
                      emptyMessage: '완료한 일정이 아직 없어요',
                      isCompletedSection: true,
                    ),
                    const SizedBox(height: 12),
                    _summarySubsection(
                      title: '미완료',
                      memos: incompleteToday,
                      emptyMessage: '남은 일정이 없어요',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: '오늘 완료율',
                subtitle: '오늘 기준 진행 정도',
                child: _completionRateCard(
                  rate: completionRate,
                  completeCount: completeToday.length,
                  totalCount: todayMemos.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _heroSummaryCard({
    required int totalToday,
    required int completeCount,
    required int incompleteCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAF5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘 일정 한눈에',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Dcolor.defaultText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '오늘 일정 $totalToday개 중 $completeCount개 완료, $incompleteCount개 남아 있어요.',
            style: TextStyle(
              fontSize: 14,
              color: Dcolor.textColorGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        color: Dcolor.defaultWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Dcolor.defaultText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Dcolor.textColorGrey,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _summaryCountCard({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count개',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Dcolor.defaultText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summarySubsection({
    required String title,
    required List<Memo> memos,
    required String emptyMessage,
    bool isCompletedSection = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Dcolor.defaultText,
            ),
          ),
          const SizedBox(height: 10),
          if (memos.isEmpty) _emptyText(emptyMessage),
          if (memos.isNotEmpty)
            ...memos.map(
              (memo) => _memoRow(
                memo,
                isCompletedSection: isCompletedSection,
              ),
            ),
        ],
      ),
    );
  }

  Widget _completionRateCard({
    required double rate,
    required int completeCount,
    required int totalCount,
  }) {
    final percentage = (rate * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Dcolor.defaultText,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '$completeCount / $totalCount 완료',
                style: TextStyle(
                  fontSize: 13,
                  color: Dcolor.textColorGrey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: rate,
            minHeight: 12,
            backgroundColor: const Color(0xFFE4EBE8),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF2D8B57)),
          ),
        ),
      ],
    );
  }

  Widget _schedulePreviewRow(Memo memo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: todoCategoryBackgroundColor(memo.categoryId),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 50,
            decoration: BoxDecoration(
              color: todoCategoryAccentColor(memo.categoryId),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  limitText(memo.content),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Dcolor.defaultText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _dateRangeLabel(memo),
                  style: TextStyle(
                    fontSize: 12,
                    color: todoCategoryAccentColor(memo.categoryId),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Dcolor.textColorGrey,
        ),
      ),
    );
  }

  Widget _memoRow(Memo m, {bool isCompletedSection = false}) {
    final backgroundColor =
        isCompletedSection
            ? todoCategoryBackgroundColor(m.categoryId).withValues(alpha: 0.2)
            : todoCategoryBackgroundColor(m.categoryId);
    final accentColor =
        isCompletedSection
            ? todoCategoryAccentColor(m.categoryId).withValues(alpha: 0.35)
            : todoCategoryAccentColor(m.categoryId);
    final textColor =
        isCompletedSection
            ? Dcolor.defaultText.withValues(alpha: 0.45)
            : Dcolor.defaultText;

    return GestureDetector(
      onTap: () => _editMemo(m),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
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
                              color: textColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            m.isDone
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: accentColor,
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
