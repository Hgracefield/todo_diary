import 'package:flutter/material.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/view/account/account_page.dart';

class MemoPageHeader extends StatelessWidget {
  const MemoPageHeader({super.key, required this.focusedDay});

  final DateTime focusedDay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            "${focusedDay.year}년 ${focusedDay.month}월",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Dcolor.defaultText,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 28),
            tooltip: '내 계정',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
