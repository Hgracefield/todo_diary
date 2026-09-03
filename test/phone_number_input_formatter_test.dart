import 'package:flutter_test/flutter_test.dart';
import 'package:my_todo_list_app/util/phone_number_input_formatter.dart';

void main() {
  group('formatPhoneNumber', () {
    test('10자리 번호를 3-3-4 형식으로 변환한다', () {
      expect(formatPhoneNumber('0101234567'), '010-123-4567');
    });

    test('11자리 번호를 3-4-4 형식으로 변환한다', () {
      expect(formatPhoneNumber('01012345678'), '010-1234-5678');
    });

    test('숫자가 아닌 문자를 제거하고 11자리까지만 입력한다', () {
      expect(formatPhoneNumber('010-ab12 3456-789'), '010-1234-5678');
    });
  });

  group('phoneNumberDigits', () {
    test('표시 형식과 관계없이 전화번호 숫자만 비교할 수 있다', () {
      expect(phoneNumberDigits('010-1234-5678'), '01012345678');
      expect(phoneNumberDigits('010 1234 5678'), '01012345678');
    });
  });
}
