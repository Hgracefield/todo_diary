class Category {
  int? categoryId;
  String categoryName;
  String categoryColor;

  Category({
    this.categoryId,
    required this.categoryName,
    required this.categoryColor,
  });

  Category.fromMap(Map<String, dynamic> res)
    : categoryId = res['categoryId'],
      categoryName = res['categoryName'],
      categoryColor = res['categoryColor'];
}
