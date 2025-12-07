import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_todo_list_app/view/home.dart';
import 'package:my_todo_list_app/vm/database_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseHandler();
  await db.forceResetDB();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 33, 147, 71),
        ),
      ),
      home: const Home(),
    );
  }
}
