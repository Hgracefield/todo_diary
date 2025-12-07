import 'dart:ui';

Color hexToColor(String hex, double opacity) {
  // # 제거
  hex = hex.replaceAll("#", "");

  // Opacity(0.0~1.0)를 0~255(0x00~0xFF)로 변환
  int alpha = (opacity * 255).round();

  // HEX 기반 Color 생성
  return Color(
    int.parse(
      (alpha.toRadixString(16).padLeft(2, '0') + hex).toUpperCase(),
      radix: 16,
    ),
  );
}
