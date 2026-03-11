import 'package:flutter/material.dart';
import 'package:my_todo_list_app/model/todo_category_config.dart';

Color stickerColor(int categoryId) {
  return todoCategoryAccentColor(categoryId);
}

Color stickerColorV2(int categoryId) {
  return todoCategoryBackgroundColor(categoryId);
}
