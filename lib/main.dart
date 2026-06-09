import 'package:flutter/material.dart';
import 'package:milzip/screens/splash_screen.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

const String kakaoJavaScriptKey = '475d290f611228d57558d105bc36862b';

/// 앱 전역 네비게이터 키 — 위젯 컨텍스트 없이도 화면 이동에 사용
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  AuthRepository.initialize(
    appKey: kakaoJavaScriptKey,
    baseUrl: 'http://localhost',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MILZIP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Pretendard',
      ),
      home: const SplashScreen(),
    );
  }
}
