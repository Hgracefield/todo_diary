// 텍스트 길이 조절 45자 까지.

String limitText(String text, {int max = 45}) {
  if (text.length <= max) return text;
  return '${text.substring(0, max)}…';
}

// 텍스트 길이 조절 45자 까지.
