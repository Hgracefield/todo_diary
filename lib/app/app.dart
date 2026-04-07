import 'package:flutter/material.dart';
import 'package:my_todo_list_app/app/routes.dart';
import 'package:my_todo_list_app/app/theme/app_theme.dart';

class TodoDiaryApp extends StatelessWidget {
  const TodoDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo Diary',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}
