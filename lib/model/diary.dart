import 'dart:typed_data';

class Diary {
  int? diaryId;
  String diaryDate;
  String content;
  Uint8List image;

  Diary({
    this.diaryId,
    required this.diaryDate,
    required this.content,
    required this.image,
  });

  Diary.fromMap(Map<String, dynamic> res)
    : diaryId = res['diaryId'],
      diaryDate = res['diaryDate'],
      content = res['content'],
      image = res['image'];
}
