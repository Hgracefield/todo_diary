String limitText(String text, {int max = 45}) {
  if (text.length <= max) return text;
  return '${text.substring(0, max)}...';
}
