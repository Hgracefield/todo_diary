class TodoModel {
  const TodoModel({
    this.id,
    required this.title,
    this.isDone = false,
  });

  final int? id;
  final String title;
  final bool isDone;
}
