class Memo {
  int? memoId;
  String content;
  String category;
  String color;
  String isCompleted;
  String date;

  Memo({
    this.memoId,
    required this.content,
    required this.category,
    required this.color,
    required this.isCompleted,
    required this.date,
  });

  Memo.fromMap(Map<String, dynamic> res)
    : memoId = res['memo_id'],
      content = res['content'],
      category = res['category'],
      color = res['color'],
      isCompleted = res['isCompleted'],
      date = res['date'];
}
