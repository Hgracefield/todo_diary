import 'dart:typed_data';

class Diary {
  int? diaryId;
  String diaryDate;
  String textContent;
  Uint8List image;

  Diary({
    this.diaryId,
    required this.diaryDate,
    required this.textContent,
    required this.image,
  });

  Diary.fromMap(Map<String, dynamic> res)
    : diaryId = res['diaryId'],
      diaryDate = res['diaryDate'],
      textContent = res['textContent'],
      image = res['image'];
}
