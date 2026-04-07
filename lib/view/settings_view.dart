import 'package:flutter/material.dart';
import 'package:my_todo_list_app/util/dcolor.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Setting'),
        backgroundColor: const Color(0xFFF6F7F9),
        foregroundColor: Dcolor.defaultText,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '설정 페이지입니다.\n필요한 옵션을 여기에 이어서 추가하면 됩니다.',
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Dcolor.defaultText,
            ),
          ),
        ),
      ),
    );
  }
}
