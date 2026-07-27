import 'dart:typed_data';

class Diary {
  int? diaryId;
  int? userId;
  String diaryDate;
  String content;
  Uint8List image;

  Diary({
    this.diaryId,
    this.userId,
    required this.diaryDate,
    required this.content,
    required this.image,
  });

  Diary.fromMap(Map<String, dynamic> res)
    : diaryId = res['diaryId'],
      userId = res['userId'],
      diaryDate = res['diaryDate'],
      content = res['content'],
      image = res['image'];
}
