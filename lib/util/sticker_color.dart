import 'package:flutter/material.dart';
import 'package:my_todo_list_app/util/dcolor.dart';

Color stickerColor(int categoryId) {
  switch (categoryId) {
    case 1:
      return Dcolor.stickerGreen;
    case 2:
      return Dcolor.stickerOrange;
    case 3:
      return Dcolor.stickerPink;
    default:
      return Dcolor.stickerGreen;
  }
}

Color stickerColorV2(int categoryId) {
  switch (categoryId) {
    case 1:
      return Dcolor.stickerGreenV2;
    case 2:
      return Dcolor.stickerOrangeV2;
    case 3:
      return Dcolor.stickerPinkV2;
    default:
      return Dcolor.stickerGreenV2;
  }
}
