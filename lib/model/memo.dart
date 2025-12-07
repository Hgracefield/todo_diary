class Memo {
  int? memoId;
  String date; // yyyy-MM-dd
  String content;
  int categoryId;
  bool isDone;

  Memo({
    this.memoId,
    required this.date,
    required this.content,
    required this.categoryId,
    required this.isDone,
  });

  Memo.fromMap(Map<String, dynamic> res)
    : memoId = res['memoId'],
      date = res['date'],
      content = res['content'],
      categoryId = res['categoryId'],
      isDone = res['isDone'] == 1;
}
