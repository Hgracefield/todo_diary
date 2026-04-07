import 'package:flutter/material.dart';
import 'package:my_todo_list_app/features/diary/diary_calendar_view.dart';
import 'package:my_todo_list_app/features/diary/diary_write_view.dart';
import 'package:my_todo_list_app/features/home/home_view.dart';
import 'package:my_todo_list_app/features/schedule/schedule_calendar_view.dart';
import 'package:my_todo_list_app/features/schedule/schedule_form_view.dart';
import 'package:my_todo_list_app/features/settings/settings_view.dart';
import 'package:my_todo_list_app/features/stats/stats_view.dart';

class AppRoutes {
  static const home = '/';
  static const scheduleCalendar = '/schedule/calendar';
  static const scheduleForm = '/schedule/form';
  static const diaryCalendar = '/diary/calendar';
  static const diaryWrite = '/diary/write';
  static const stats = '/stats';
  static const settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
    home: (_) => const HomeView(),
    scheduleCalendar: (_) => const ScheduleCalendarView(),
    scheduleForm: (_) => const ScheduleFormView(),
    diaryCalendar: (_) => const DiaryCalendarView(),
    diaryWrite: (_) => const DiaryWriteView(),
    stats: (_) => const StatsView(),
    settings: (_) => const SettingsView(),
  };
}
