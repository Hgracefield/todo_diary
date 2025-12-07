import 'package:flutter/material.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/view/calendar_memo.dart';
import 'package:my_todo_list_app/view/todo_view.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  // property
  late TabController tabBotController;

  @override
  void initState() {
    super.initState();
    tabBotController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x8BCBFFF3),
      // appBar: AppBar(),
      body: TabBarView(
        controller: tabBotController,
        children: [TodoView(), CalendarMemo()],
      ),
      bottomNavigationBar: Container(
        color: const Color(0x8BCBFFF3),
        height: 80,
        child: TabBar(
          controller: tabBotController,
          labelColor: Color.fromARGB(229, 1, 118, 81),
          unselectedLabelColor: Color.fromARGB(70, 36, 103, 81),
          indicatorColor: Color.fromARGB(229, 1, 118, 81),
          indicatorWeight: 5,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(icon: Icon(Icons.home_outlined, size: 30)),
            Tab(icon: Icon(Icons.calendar_today_outlined, size: 30)),
          ],
        ),
      ),
    );
  }
}
