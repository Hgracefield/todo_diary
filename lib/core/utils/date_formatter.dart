class DateFormatter {
  static String ymd(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String monthLabel(DateTime date) {
    return '${date.year}년 ${date.month}월';
  }

  const DateFormatter._();
}
