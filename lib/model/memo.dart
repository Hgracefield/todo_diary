class Memo {
  int? scheduleId;
  int userId;
  int scheduleTypeId;
  String scheduleTitle;
  String? scheduleContent;
  String scheduleStartDate;
  String scheduleEndDate;
  String? scheduleCreatedAt;
  String? scheduleUpdatedAt;

  // SCHEDULE에는 완료 여부 컬럼이 없어서 기존 UI 호환용으로만 유지합니다.
  bool isDone;

  Memo({
    this.scheduleId,
    this.userId = 1,
    required this.scheduleTypeId,
    required this.scheduleTitle,
    this.scheduleContent,
    required this.scheduleStartDate,
    String? scheduleEndDate,
    this.scheduleCreatedAt,
    this.scheduleUpdatedAt,
    this.isDone = false,
  }) : scheduleEndDate = scheduleEndDate ?? scheduleStartDate;

  factory Memo.fromMap(Map<String, dynamic> res) {
    String normalizeDate(dynamic value) {
      final text = value?.toString() ?? '';
      return text.length >= 10 ? text.substring(0, 10) : text;
    }

    String normalizeDateTime(dynamic value) {
      final text = value?.toString() ?? '';
      if (text.length >= 16) return text.substring(0, 16);
      if (text.length == 10) return '${text}T00:00';
      return text;
    }

    String normalizeTime(dynamic value) {
      final text = value?.toString() ?? '';
      if (text.length >= 5) return text.substring(0, 5);
      return '00:00';
    }

    final startSource =
        res['scheduleStartDate'] ?? res['SCHEDULE_START_DATE'] ?? res['date'];
    final endSource =
        res['scheduleEndDate'] ?? res['SCHEDULE_END_DATE'] ?? startSource;
    final time = normalizeTime(res['time']);
    final scheduleStartDate = startSource == res['date']
        ? '${normalizeDate(startSource)}T$time'
        : normalizeDateTime(startSource);

    return Memo(
      scheduleId: res['scheduleId'] ?? res['SCHEDULE_ID'] ?? res['memoId'],
      userId: res['userId'] ?? res['USER_ID'] ?? 1,
      scheduleTypeId:
          res['scheduleTypeId'] ??
          res['SCHEDULE_TYPE_ID'] ??
          res['categoryId'] ??
          1,
      scheduleTitle:
          res['scheduleTitle'] ?? res['SCHEDULE_TITLE'] ?? res['content'] ?? '',
      scheduleContent: res['scheduleContent'] ?? res['SCHEDULE_CONTENT'],
      scheduleStartDate: scheduleStartDate,
      scheduleEndDate: normalizeDateTime(endSource),
      scheduleCreatedAt: res['scheduleCreatedAt'] ?? res['SCHEDULE_CREATED_AT'],
      scheduleUpdatedAt: res['scheduleUpdatedAt'] ?? res['SCHEDULE_UPDATED_AT'],
      isDone: res['isDone'] == 1 || res['isDone'] == true,
    );
  }

  factory Memo.fromJson(Map<String, dynamic> json) => Memo.fromMap(json);

  Map<String, dynamic> toJson() {
    return {
      if (scheduleId != null) 'scheduleId': scheduleId,
      'userId': userId,
      'scheduleTypeId': scheduleTypeId,
      'scheduleTitle': scheduleTitle,
      'scheduleContent': scheduleContent,
      'scheduleStartDate': scheduleStartDate,
      'scheduleEndDate': scheduleEndDate,
    };
  }

  int? get memoId => scheduleId;
  set memoId(int? value) => scheduleId = value;

  String get date {
    return scheduleStartDate.length >= 10
        ? scheduleStartDate.substring(0, 10)
        : scheduleStartDate;
  }

  set date(String value) {
    scheduleStartDate = value;
    scheduleEndDate = value;
  }

  String get time {
    if (scheduleStartDate.length >= 16) {
      return scheduleStartDate.substring(11, 16);
    }
    return '00:00';
  }

  String get content {
    if (scheduleContent != null && scheduleContent!.isNotEmpty) {
      return scheduleContent!;
    }
    return scheduleTitle;
  }

  set content(String value) {
    scheduleTitle = value;
    scheduleContent = value;
  }

  int get categoryId => scheduleTypeId;
  set categoryId(int value) => scheduleTypeId = value;
}
