import 'package:flutter/services.dart';

String phoneNumberDigits(String value) {
  return value.replaceAll(RegExp(r'[^0-9]'), '');
}

String formatPhoneNumber(String value) {
  var digits = phoneNumberDigits(value);
  if (digits.length > 11) {
    digits = digits.substring(0, 11);
  }

  if (digits.length <= 3) return digits;
  if (digits.length <= 7) {
    return '${digits.substring(0, 3)}-${digits.substring(3)}';
  }
  if (digits.length <= 10) {
    return '${digits.substring(0, 3)}-'
        '${digits.substring(3, 6)}-'
        '${digits.substring(6)}';
  }
  return '${digits.substring(0, 3)}-'
      '${digits.substring(3, 7)}-'
      '${digits.substring(7)}';
}

class PhoneNumberInputFormatter extends TextInputFormatter {
  const PhoneNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatPhoneNumber(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
