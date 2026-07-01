class Schedule {
  final int? scheduleId;
  final int userId;
  final int scheduleTypeId;
  final String scheduleTitle;
  final String? scheduleContent;
  final String scheduleStartDate;
  final String scheduleEndDate;
  final bool scheduleIsDone;
  final String? scheduleCreatedAt;
  final String? scheduleUpdatedAt;

  const Schedule({
    this.scheduleId,
    required this.userId,
    required this.scheduleTypeId,
    required this.scheduleTitle,
    this.scheduleContent,
    required this.scheduleStartDate,
    required this.scheduleEndDate,
    this.scheduleIsDone = false,
    this.scheduleCreatedAt,
    this.scheduleUpdatedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      scheduleId: json['scheduleId'] ?? json['SCHEDULE_ID'],
      userId: json['userId'] ?? json['USER_ID'] ?? 1,
      scheduleTypeId: json['scheduleTypeId'] ?? json['SCHEDULE_TYPE_ID'] ?? 1,
      scheduleTitle: json['scheduleTitle'] ?? json['SCHEDULE_TITLE'] ?? '',
      scheduleContent: json['scheduleContent'] ?? json['SCHEDULE_CONTENT'],
      scheduleStartDate:
          json['scheduleStartDate'] ?? json['SCHEDULE_START_DATE'] ?? '',
      scheduleEndDate:
          json['scheduleEndDate'] ?? json['SCHEDULE_END_DATE'] ?? '',
      scheduleIsDone:
          json['scheduleIsDone'] == true ||
          json['SCHEDULE_IS_DONE'] == true ||
          json['scheduleIsDone'] == 1 ||
          json['SCHEDULE_IS_DONE'] == 1,
      scheduleCreatedAt:
          json['scheduleCreatedAt'] ?? json['SCHEDULE_CREATED_AT'],
      scheduleUpdatedAt:
          json['scheduleUpdatedAt'] ?? json['SCHEDULE_UPDATED_AT'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (scheduleId != null) 'scheduleId': scheduleId,
      'userId': userId,
      'scheduleTypeId': scheduleTypeId,
      'scheduleTitle': scheduleTitle,
      'scheduleContent': scheduleContent,
      'scheduleStartDate': scheduleStartDate,
      'scheduleEndDate': scheduleEndDate,
      'scheduleIsDone': scheduleIsDone,
    };
  }
}
