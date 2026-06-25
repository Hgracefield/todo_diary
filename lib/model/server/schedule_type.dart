class ScheduleType {
  final int? scheduleTypeId;
  final String scheduleTypeName;
  final String scheduleTypeColor;
  final String? scheduleTypeCreatedAt;

  const ScheduleType({
    this.scheduleTypeId,
    required this.scheduleTypeName,
    required this.scheduleTypeColor,
    this.scheduleTypeCreatedAt,
  });

  factory ScheduleType.fromJson(Map<String, dynamic> json) {
    return ScheduleType(
      scheduleTypeId: json['scheduleTypeId'] ?? json['SCHEDULE_TYPE_ID'],
      scheduleTypeName:
          json['scheduleTypeName'] ?? json['SCHEDULE_TYPE_NAME'] ?? '',
      scheduleTypeColor:
          json['scheduleTypeColor'] ?? json['SCHEDULE_TYPE_COLOR'] ?? '',
      scheduleTypeCreatedAt:
          json['scheduleTypeCreatedAt'] ?? json['SCHEDULE_TYPE_CREATED_AT'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (scheduleTypeId != null) 'scheduleTypeId': scheduleTypeId,
      'scheduleTypeName': scheduleTypeName,
      'scheduleTypeColor': scheduleTypeColor,
    };
  }
}
