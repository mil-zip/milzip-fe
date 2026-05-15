import 'package:flutter/material.dart';
import 'package:milzip/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // 애니메이션 컨트롤러
  late AnimationController _controller;
  // 페이드 애니메이션 (0.0 → 1.0)
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화 (2초 동안)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 페이드 애니메이션 설정 (자연스러운 ease 곡선 적용)
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // 애니메이션 시작
    _controller.forward();

    // 2.5초 후 로그인 화면으로 이동
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위해 컨트롤러 해제
    _controller.dispose();
    super.dispose();
  }

  // 2.5초 후 로그인 화면으로 이동
  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    // 위젯이 아직 살아있는지 확인 (안전 장치)
    if (!mounted) return;

    // pushReplacement: 뒤로가기 못하게 스플래시를 스택에서 제거하고 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 영역
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '밀집',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Image.asset(
                    'assets/images/milzip_mascot.png',
                    width: 56,
                    height: 56,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '군인을 위한 맞춤형 혜택·추천 서비스, MILZIP',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
