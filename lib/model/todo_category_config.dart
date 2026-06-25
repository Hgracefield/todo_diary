import 'package:flutter/material.dart';
import 'package:my_todo_list_app/util/dcolor.dart';

class TodoCategoryConfig {
  final int id;
  final String name;
  final String colorName;
  final Color accentColor;
  final Color backgroundColor;

  const TodoCategoryConfig({
    required this.id,
    required this.name,
    required this.colorName,
    required this.accentColor,
    required this.backgroundColor,
  });
}

final List<TodoCategoryConfig> todoCategoryConfigs = [
  TodoCategoryConfig(
    id: 1,
    name: '기본',
    colorName: 'green',
    accentColor: Dcolor.stickerGreen,
    backgroundColor: Dcolor.stickerGreenV2,
  ),
  TodoCategoryConfig(
    id: 2,
    name: '중요',
    colorName: 'orange',
    accentColor: Dcolor.stickerOrange,
    backgroundColor: Dcolor.stickerOrangeV2,
  ),
  TodoCategoryConfig(
    id: 3,
    name: '기타',
    colorName: 'purple',
    accentColor: Dcolor.stickerPP,
    backgroundColor: Dcolor.stickerPPV2,
  ),
];

TodoCategoryConfig todoCategoryById(int categoryId) {
  return todoCategoryConfigs.firstWhere(
    (category) => category.id == categoryId,
    orElse: () => todoCategoryConfigs.first,
  );
}

Color todoCategoryAccentColor(int categoryId) {
  return todoCategoryById(categoryId).accentColor;
}

Color todoCategoryBackgroundColor(int categoryId) {
  return todoCategoryById(categoryId).backgroundColor;
}

String todoCategoryName(int categoryId) {
  return todoCategoryById(categoryId).name;
}
