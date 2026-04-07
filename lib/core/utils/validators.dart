class Validators {
  static bool isNotEmpty(String value) => value.trim().isNotEmpty;

  static String? requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '필수 입력 항목입니다.';
    }
    return null;
  }

  const Validators._();
}
