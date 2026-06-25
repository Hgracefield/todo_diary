import 'package:my_todo_list_app/model/server/diary_image.dart';

class ServerDiary {
  final int? diaryId;
  final int userId;
  final String diaryDate;
  final String diaryTitle;
  final String? diaryContent;
  final String? diaryCreatedAt;
  final String? diaryUpdatedAt;
  final List<DiaryImage> images;

  const ServerDiary({
    this.diaryId,
    required this.userId,
    required this.diaryDate,
    required this.diaryTitle,
    this.diaryContent,
    this.diaryCreatedAt,
    this.diaryUpdatedAt,
    this.images = const [],
  });

  factory ServerDiary.fromJson(Map<String, dynamic> json) {
    final rawImages =
        json['images'] ?? json['diaryImages'] ?? json['DIARY_IMAGES'];

    return ServerDiary(
      diaryId: json['diaryId'] ?? json['DIARY_ID'],
      userId: json['userId'] ?? json['USER_ID'] ?? 1,
      diaryDate: json['diaryDate'] ?? json['DIARY_DATE'] ?? '',
      diaryTitle: json['diaryTitle'] ?? json['DIARY_TITLE'] ?? '',
      diaryContent: json['diaryContent'] ?? json['DIARY_CONTENT'],
      diaryCreatedAt: json['diaryCreatedAt'] ?? json['DIARY_CREATED_AT'],
      diaryUpdatedAt: json['diaryUpdatedAt'] ?? json['DIARY_UPDATED_AT'],
      images: rawImages is List
          ? rawImages
                .map(
                  (item) => DiaryImage.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (diaryId != null) 'diaryId': diaryId,
      'userId': userId,
      'diaryDate': diaryDate,
      'diaryTitle': diaryTitle,
      'diaryContent': diaryContent,
    };
  }
}
