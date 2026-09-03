// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_todo_list_app/main.dart';
import 'package:my_todo_list_app/view/account/account_page.dart';

void main() {
  testWidgets('shows login page when logged out', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
  });

  testWidgets('email suggestions do not overflow the login page', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'account_email_history': [
        'first@naver.com',
        'second@gmail.com',
        'third@daum.net',
      ],
    });
    await tester.binding.setSurfaceSize(const Size(390, 650));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp(isLoggedIn: false));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    expect(find.text('first@naver.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account fields have separate change buttons', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: AccountPage()));
    await tester.pumpAndSettle();

    expect(find.text('비밀번호 변경'), findsOneWidget);
    expect(find.text('이름 변경'), findsOneWidget);
    expect(find.text('생년월일 변경'), findsOneWidget);
    expect(find.text('핸드폰번호 변경'), findsOneWidget);
    expect(find.text('주소 변경'), findsOneWidget);
    expect(find.text('저장'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
