import 'package:flutter/material.dart';
import 'package:my_todo_list_app/api/rest_api_service.dart';
import 'package:my_todo_list_app/storage/session_storage.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/vm/database_handler.dart';

class ScheduleReportPage extends StatefulWidget {
  const ScheduleReportPage({super.key});

  @override
  State<ScheduleReportPage> createState() => _ScheduleReportPageState();
}

class _ScheduleReportPageState extends State<ScheduleReportPage> {
  final api = RestApiService();
  final db = DatabaseHandler();

  late Future<_MonthlyReport> reportFuture;
  late int selectedMonth;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedYear = now.year;
    selectedMonth = now.month;
    reportFuture = _loadReport(selectedYear, selectedMonth);
  }

  Future<_MonthlyReport> _loadReport(int year, int month) async {
    final userId = await SessionStorage.userId();
    if (userId == null) {
      throw StateError('로그인한 사용자 정보가 없습니다.');
    }

    final firstDayOfYear = DateTime(year);
    final lastDayOfYear = DateTime(year, 12, 31);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final schedules = await api.getSchedules(
      userId: userId,
      startDate: _dateKey(firstDayOfYear),
      endDate: _dateKey(lastDayOfYear),
    );
    final monthlySchedules = schedules.where((schedule) {
      final date = DateTime.tryParse(schedule.scheduleStartDate);
      return date?.year == year && date?.month == month;
    }).toList();
    final diaries = await db.getDiaryList();
    final yearlyDiaryDates = diaries
        .map((diary) => DateTime.tryParse(diary.diaryDate))
        .whereType<DateTime>()
        .where((date) => date.year == year)
        .map(_dateKey)
        .toSet();
    final monthlyDiaryDates = yearlyDiaryDates.where((date) {
      return DateTime.parse(date).month == month;
    }).toSet();

    return _MonthlyReport(
      year: year,
      month: month,
      completedTodos: monthlySchedules
          .where((schedule) => schedule.scheduleIsDone)
          .length,
      totalTodos: monthlySchedules.length,
      diaryDays: monthlyDiaryDates.length,
      daysInMonth: lastDayOfMonth.day,
      yearlyCompletedTodos: schedules
          .where((schedule) => schedule.scheduleIsDone)
          .length,
      yearlyTotalTodos: schedules.length,
      yearlyDiaryDays: yearlyDiaryDates.length,
      daysInYear: DateTime(year + 1).difference(firstDayOfYear).inDays,
    );
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _refresh() async {
    final nextReport = _loadReport(selectedYear, selectedMonth);
    setState(() {
      reportFuture = nextReport;
    });
    await nextReport;
  }

  void _selectMonth(int month) {
    if (month == selectedMonth) return;
    setState(() {
      selectedMonth = month;
      reportFuture = _loadReport(selectedYear, month);
    });
  }

  void _changeYear(int offset) {
    final nextYear = selectedYear + offset;
    final currentYear = DateTime.now().year;
    if (nextYear < 2000 || nextYear > currentYear) return;
    setState(() {
      selectedYear = nextYear;
      reportFuture = _loadReport(nextYear, selectedMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDF2F1),
        elevation: 0,
        foregroundColor: Dcolor.defaultText,
        title: const Text('개인 레포트'),
      ),
      body: FutureBuilder<_MonthlyReport>(
        future: reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Dcolor.stickerGreen),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _ReportError(onRetry: _refresh);
          }

          final report = snapshot.data!;
          return RefreshIndicator(
            color: Dcolor.stickerGreen,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: selectedYear > 2000
                          ? () => _changeYear(-1)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        '${report.year}년',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Dcolor.defaultText,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: selectedYear < DateTime.now().year
                          ? () => _changeYear(1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '${report.year}년 ${report.month}월',
                  style: TextStyle(
                    color: Dcolor.defaultText,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${report.month}월의 일정과 기록을 확인해보세요.',
                  style: TextStyle(
                    color: Dcolor.textColorGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                _ReportCard(
                  label: 'todo',
                  title: '${report.month}월 일정',
                  current: report.completedTodos,
                  total: report.totalTodos,
                  description:
                      '${report.totalTodos}개 중 ${report.completedTodos}개의 일정을 완료했습니다.',
                  color: Dcolor.stickerGreen,
                ),
                const SizedBox(height: 14),
                _ReportCard(
                  label: 'diary',
                  title: '${report.month}월 다이어리',
                  current: report.diaryDays,
                  total: report.daysInMonth,
                  description:
                      '${report.daysInMonth}일 중 ${report.diaryDays}일의 다이어리를 작성했습니다.',
                  color: Dcolor.stickerOrange,
                ),
                const SizedBox(height: 24),
                _YearlyReportCard(report: report),
                const SizedBox(height: 30),
                Text(
                  '다른 달 보기',
                  style: TextStyle(
                    color: Dcolor.defaultText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    return _MonthButton(
                      month: month,
                      isSelected: month == selectedMonth,
                      onTap: () => _selectMonth(month),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _YearlyReportCard extends StatelessWidget {
  const _YearlyReportCard({required this.report});

  final _MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Dcolor.defaultText,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${report.year}년 총량',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _YearlyValueRow(
            label: 'todo',
            value: '${report.yearlyCompletedTodos}/${report.yearlyTotalTodos}',
            description:
                '${report.yearlyTotalTodos}개 중 ${report.yearlyCompletedTodos}개 완료',
            color: Dcolor.stickerGreen,
          ),
          const SizedBox(height: 14),
          _YearlyValueRow(
            label: 'diary',
            value: '${report.yearlyDiaryDays}/${report.daysInYear}',
            description:
                '${report.daysInYear}일 중 ${report.yearlyDiaryDays}일 작성',
            color: Dcolor.stickerOrange,
          ),
        ],
      ),
    );
  }
}

class _YearlyValueRow extends StatelessWidget {
  const _YearlyValueRow({
    required this.label,
    required this.value,
    required this.description,
    required this.color,
  });

  final String label;
  final String value;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(
            '$label:',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            description,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFFB8B8B8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({
    required this.month,
    required this.isSelected,
    required this.onTap,
  });

  final int month;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        decoration: BoxDecoration(
          color: isSelected ? Dcolor.stickerGreen : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Dcolor.stickerGreen
                : Dcolor.stickerGreen.withValues(alpha: 0.45),
          ),
        ),
        child: Center(
          child: Text(
            '$month월',
            style: TextStyle(
              color: isSelected ? Colors.white : Dcolor.defaultText,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.label,
    required this.title,
    required this.current,
    required this.total,
    required this.description,
    required this.color,
  });

  final String label;
  final String title;
  final int current;
  final int total;
  final String description;
  final Color color;

  double get progress {
    if (total == 0) return 0;
    return (current / total).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Dcolor.defaultText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$current/$total',
                style: TextStyle(
                  color: Dcolor.defaultText,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: Dcolor.textColorGrey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportError extends StatelessWidget {
  const _ReportError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '리포트 정보를 불러오지 못했습니다.',
            style: TextStyle(color: Dcolor.textColorGrey),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              backgroundColor: Dcolor.stickerGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

class _MonthlyReport {
  const _MonthlyReport({
    required this.year,
    required this.month,
    required this.completedTodos,
    required this.totalTodos,
    required this.diaryDays,
    required this.daysInMonth,
    required this.yearlyCompletedTodos,
    required this.yearlyTotalTodos,
    required this.yearlyDiaryDays,
    required this.daysInYear,
  });

  final int year;
  final int month;
  final int completedTodos;
  final int totalTodos;
  final int diaryDays;
  final int daysInMonth;
  final int yearlyCompletedTodos;
  final int yearlyTotalTodos;
  final int yearlyDiaryDays;
  final int daysInYear;
}
