import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:milzip/screens/auth/email_login_screen.dart';
import 'package:milzip/screens/auth/signup_email.dart';
import 'package:milzip/screens/home.dart';
import 'package:milzip/services/auth_service.dart';
import 'package:milzip/services/user_service.dart';
import 'package:milzip/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isKakaoLoading = false;

  Future<void> _handleKakaoLogin() async {
    setState(() => _isKakaoLoading = true);
    try {
      await AuthService.kakaoLogin();
      await UserService.getMyInfo();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isKakaoLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── 로고 이미지 (배경 없이 radius만) ────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/milzip_logo.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 30),

              // ── MIL.ZIP 로고 이미지 (초록색) ────────────────────────────
              Image.asset(
                'assets/images/milzip.png',
                width: 140,
                fit: BoxFit.fitWidth,
              ),

              const SizedBox(height: 28),

              // ── 서브타이틀 ───────────────────────────────────────────────
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '군인을 위한\n',
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.62,
                      ),
                    ),
                    const TextSpan(
                      text: '맞춤형 혜택·추천 서비스, MILZIP',
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.62,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // ── 카카오 로그인 (공식 가이드라인: #FEE500 / 어두운 텍스트) ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isKakaoLoading ? null : _handleKakaoLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500),
                    foregroundColor: const Color(0xFF191919),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isKakaoLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF191919),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/kakao_login.png',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '카카오로 로그인',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // ── 이메일 로그인 (solid, 연한 강조) ─────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmailLoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary2,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '이메일 아이디로 로그인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── 둘러보기 (gradient + border + shadow — 더 강조) ───────────
              GestureDetector(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.hover, AppColors.primaryLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary1,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary1.withAlpha(130),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '둘러보기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ── 회원가입 링크 ─────────────────────────────────────────────
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSub,
                  ),
                  children: [
                    const TextSpan(text: '계정이 없으신가요?  '),
                    TextSpan(
                      text: '회원가입하기',
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.textMain,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupEmailScreen(),
                            ),
                          );
                        },
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
