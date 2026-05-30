import 'package:flutter/material.dart';
import 'package:milzip/screens/splash_screen.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

const String kakaoJavaScriptKey = '475d290f611228d57558d105bc36862b';

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
