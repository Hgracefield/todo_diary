import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:my_todo_list_app/storage/session_storage.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/view/login/login_page.dart';
import 'package:my_todo_list_app/view/tab_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await SessionStorage.isLoggedIn();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.isLoggedIn});
  final bool isLoggedIn;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 33, 147, 71),
        ),
        datePickerTheme: DatePickerThemeData(
          cancelButtonStyle: TextButton.styleFrom(
            backgroundColor: Dcolor.stickerOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          confirmButtonStyle: TextButton.styleFrom(
            backgroundColor: Dcolor.stickerGreen,
            foregroundColor: const Color(0xFF333333),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: isLoggedIn ? const TabBarPage() : const LoginPage(),
    );
  }
}
