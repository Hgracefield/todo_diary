class ScheduleModel {
  const ScheduleModel({
    this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
  });

  final int? id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
}
