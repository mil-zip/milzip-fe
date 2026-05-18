import 'package:flutter/material.dart';
import 'package:milzip/screens/auth/email_login_screen.dart'; // 로그인 화면
import 'package:milzip/screens/auth/signup_email.dart'; // 회원가입 화면
import 'package:flutter/gestures.dart'; // ← 회원가입 밑줄 생성 코드

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 3),
              // 로고 영역
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  // 고양이 마스코트 자리
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
              const Spacer(flex: 2),
              // 카카오 로그인 버튼
              GestureDetector(
                onTap: () {
                  // TODO: 카카오 로그인 연동
                },
                child: Image.asset(
                  'assets/images/kakao_login.png',
                  width: 56,
                  height: 56,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '카카오 계정으로 로그인하기',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 40),
              // 이메일 로그인 버튼
              SizedBox(
                width: double.infinity,
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
                    backgroundColor: const Color(0xFFF1F3F5),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '이메일 아이디로 로그인',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 둘러보기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: 메인 화면으로 이동 (게스트 모드)
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F3F5),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '둘러보기',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 회원가입 링크
              // 회원가입 링크
              // 회원가입 링크
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFADB5BD),
                  ),
                  children: [
                    const TextSpan(text: '계정이 없으신가요? '),
                    TextSpan(
                      text: '회원가입하기',
                      style: const TextStyle(
                        color: Color(0xFF495057),
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline, // 밑줄 추가
                        decorationColor: Color(0xFF495057), // 밑줄 색상
                      ),
                      // "회원가입하기" 글자만 클릭 가능
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
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
