import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_page.dart';
import 'models/task_set.dart';
import 'models/todo_item.dart';

// 莫兰迪配色
const Color morandiBlue = Color(0xFFA7C7E7);
const Color morandiPurple = Color(0xFFB6A2D0);
const Color morandiPink = Color(0xFFD9B8C4);
const Color morandiGreen = Color(0xFFB8C9B0);
const Color morandiRed = Color(0xFFE3B9B2);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // 注册适配器
  Hive.registerAdapter(TaskSetAdapter());
  Hive.registerAdapter(TodoItemAdapter());
  Hive.registerAdapter(SubTaskAdapter());
  // 打开盒子
  await Hive.openBox('tasks');      // 用于存储 daily/weekly/longterm/deadline 列表
  await Hive.openBox('taskSets');    // 用于存储任务集列表
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '待办清单',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.light(
          primary: morandiBlue,
          secondary: morandiPurple,
          surface: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: morandiBlue,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: morandiPurple,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: morandiPurple,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
        ),
      ),
      home: TodoHomePage(),
    );
  }
}