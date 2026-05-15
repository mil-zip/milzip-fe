import 'package:flutter/material.dart';
import 'package:milzip/screens/splash_screen.dart'; // 스플래쉬 화면

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MILZIP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Pretendard', // 폰트 적용했을 경우
      ),
      home: const SplashScreen(),
    );
  }
}
