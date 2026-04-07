import 'package:flutter/material.dart';
import 'package:my_todo_list_app/model/memo.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/vm/database_handler.dart';

class InsightView extends StatefulWidget {
  const InsightView({super.key});

  @override
  State<InsightView> createState() => _InsightViewState();
}

class _InsightViewState extends State<InsightView> {
  final db = DatabaseHandler();

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _includesDay(Memo memo, DateTime day) {
    final normalizedDay = _normalizeDate(day);
    final start = _normalizeDate(DateTime.parse(memo.startDate));
    final end = _normalizeDate(DateTime.parse(memo.endDate));
    return !normalizedDay.isBefore(start) && !normalizedDay.isAfter(end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x8BCBFFF3),
      appBar: AppBar(
        toolbarHeight: 90,
        title: const Text(
          'INSIGHT',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color.fromARGB(16, 203, 255, 243),
      ),
      body: FutureBuilder<List<Memo>>(
        future: db.getAllMemos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final memos = snapshot.data!;
          final today = _normalizeDate(DateTime.now());
          final todayMemos = memos.where((memo) => _includesDay(memo, today)).toList();
          final completedToday = todayMemos.where((memo) => memo.isDone).length;
          final todayRate = todayMemos.isEmpty
              ? 0
              : ((completedToday / todayMemos.length) * 100).round();
          final totalDone = memos.where((memo) => memo.isDone).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _insightCard(
                title: '완료율',
                subtitle: '오늘 기준 완료 퍼센트',
                child: Text(
                  '$todayRate%',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Dcolor.defaultText,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _insightCard(
                title: '감정 흐름',
                subtitle: '다음 단계에서 감정 데이터를 붙일 영역',
                child: Text(
                  '아직 감정 데이터가 없어서 준비 영역으로 비워두었어요.',
                  style: TextStyle(fontSize: 14, color: Dcolor.textColorGrey),
                ),
              ),
              const SizedBox(height: 16),
              _insightCard(
                title: '누적 기록 분석',
                subtitle: '전체 일정/완료 누적 보기',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '전체 기록 ${memos.length}개',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Dcolor.defaultText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '완료 누적 $totalDone개',
                      style: TextStyle(
                        fontSize: 14,
                        color: Dcolor.textColorGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _insightCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
