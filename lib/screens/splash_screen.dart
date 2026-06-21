import 'package:flutter/material.dart';
import 'package:milzip/screens/auth/kakao_name_screen.dart';
import 'package:milzip/screens/home.dart';
import 'package:milzip/screens/login_screen.dart';
import 'package:milzip/services/auth_service.dart';
import 'package:milzip/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    // ── 웹 카카오 로그인 콜백(/auth/callback) 우선 처리 ──
    final callback = await AuthService.handleWebKakaoCallback();
    if (!mounted) return;

    if (callback == 'name') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KakaoNameScreen()),
      );
      return;
    }
    if (callback == 'home') {
      try {
        await AuthService.fetchAndSaveMyInfo();
      } catch (_) {
        // 정보 조회 실패해도 토큰은 있으니 홈으로 진행
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }
    if (callback == 'error') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // ── 일반 진입 ──
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final token = await AuthService.getAccessToken();
    if (!mounted) return;
    final destination = (token != null && token.isNotEmpty)
        ? const HomeScreen()
        : const LoginScreen();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary1,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 이미지
              Image.asset(
                'assets/images/milzip_logo.png',
                width: 110,
                height: 110,
              ),
              const SizedBox(height: 20),
              // MIL.ZIP 화이트 텍스트 이미지
              Image.asset(
                'assets/images/milzip_white.png',
                width: 160,
                fit: BoxFit.fitWidth,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
