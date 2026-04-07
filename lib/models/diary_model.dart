class DiaryModel {
  const DiaryModel({
    this.id,
    required this.date,
    required this.content,
  });

  final int? id;
  final DateTime date;
  final String content;
}
