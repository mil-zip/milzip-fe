import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // ← 추가
import 'package:milzip/screens/auth/signup_email.dart'; // 회원가입 창
//import 'package:milzip/screens/bottom_navigator.dart'; // 메인화면 창
import 'package:milzip/screens/home.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled =
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  void _handleLogin() {
    // TODO: 실제 로그인 API 연동
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false, // 모든 이전 화면 제거
    );
  }

  // 공통 입력 필드 스타일 (피그마 스펙 반영)
  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      // 평상시 보더
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFFD5D7D9), width: 1),
      ),
      // 클릭(포커스)했을 때 보더
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFFD5D7D9), width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '이메일 아이디로 로그인',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            // 이메일 입력
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _buildInputDecoration('이메일 아이디'),
            ),
            const SizedBox(height: 10),
            // 비밀번호 입력
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: _buildInputDecoration('비밀번호'),
            ),
            const SizedBox(height: 10),
            // 로그인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isButtonEnabled ? _handleLogin : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFADB5BD),
                  disabledBackgroundColor: const Color(0xFFADB5BD),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
                  '로그인',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 회원가입 링크 (두 부분으로 나눠서 스타일 다르게)
            Center(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
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
                      // "회원가입하기" 글자만 클릭 가능하게
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
            ),
          ],
        ),
      ),
    );
  }
}
