import 'package:flutter/material.dart';
import 'package:my_todo_list_app/view/diary/calendar_diary.dart';
import 'package:my_todo_list_app/view/life_log_home.dart';
import 'package:my_todo_list_app/view/memo/calendar_memo.dart';

class TabBarPage extends StatefulWidget {
  const TabBarPage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<TabBarPage> createState() => _TabBarPageState();
}

class _TabBarPageState extends State<TabBarPage>
    with SingleTickerProviderStateMixin {
  static const _tabColors = [
    Color(0xFFA3D1C6),
    Color(0xFF2D9CFF),
    Color(0xFFE67E22),
  ];

  // property
  late TabController tabBotController;

  @override
  void initState() {
    super.initState();
    tabBotController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    tabBotController.addListener(_refreshTabColor);
  }

  void _refreshTabColor() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    tabBotController.removeListener(_refreshTabColor);
    tabBotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0x8B99CCC2),
      // backgroundColor: Color(0xFFEDF2F1),
      // appBar: AppBar(),
      body: TabBarView(
        controller: tabBotController,
        children: [
          LifeLogHome(onAddMemoPressed: () => tabBotController.animateTo(1)),
          CalendarMemo(),
          CalendarDiary(),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        height: 100,
        child: TabBar(
          controller: tabBotController,
          labelColor: _tabColors[tabBotController.index],
          unselectedLabelColor: Color.fromARGB(70, 36, 103, 81),
          indicator: _TopTabIndicator(
            color: _tabColors[tabBotController.index],
            height: 5,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(
              icon: Icon(
                Icons.home_outlined,
                size: 30,
                color: _tabIconColor(0),
              ),
            ),
            Tab(
              icon: Icon(
                Icons.calendar_today_outlined,
                size: 30,
                color: _tabIconColor(1),
              ),
            ),
            Tab(
              icon: Icon(
                Icons.menu_book_outlined,
                size: 30,
                color: _tabIconColor(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _tabIconColor(int index) {
    if (tabBotController.index == index) return _tabColors[index];
    return const Color.fromARGB(70, 36, 103, 81);
  }
}

class _TopTabIndicator extends Decoration {
  const _TopTabIndicator({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _TopTabIndicatorPainter(color: color, height: height);
  }
}

class _TopTabIndicatorPainter extends BoxPainter {
  const _TopTabIndicatorPainter({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;

    final paint = Paint()..color = color;
    final rect = Rect.fromLTWH(offset.dx, offset.dy, size.width, height);
    canvas.drawRect(rect, paint);
  }
}
