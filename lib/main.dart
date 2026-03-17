import 'package:flutter/material.dart';
import 'screens/home_page.dart';

// 莫兰迪配色
const Color morandiBlue = Color(0xFFA7C7E7);   // 淡蓝紫
const Color morandiPurple = Color(0xFFB6A2D0); // 淡紫
const Color morandiPink = Color(0xFFD9B8C4);   // 粉紫
const Color morandiGreen = Color(0xFFB8C9B0);  // 灰绿（可选）
const Color morandiRed = Color(0xFFE3B9B2);    // 粉红（用于删除）

void main() => runApp(MyApp());

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