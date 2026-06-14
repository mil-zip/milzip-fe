import 'package:flutter/material.dart';
import 'package:milzip/screens/auth/signup_nickname.dart';
import 'package:milzip/theme/app_colors.dart';

class SignupPasswordScreen extends StatefulWidget {
  final String email;

  const SignupPasswordScreen({super.key, required this.email});

  @override
  State<SignupPasswordScreen> createState() => _SignupPasswordScreenState();
}

class _SignupPasswordScreenState extends State<SignupPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  // 에러 메시지 (null이면 에러 없음)
  String? _passwordError;
  String? _passwordConfirmError;

  bool _isButtonEnabled = false;
  bool _isPasswordVisible = false; // 비밀번호 보이기 여부
  bool _isPasswordConfirmVisible = false; // 비밀번호 재입력 보이기 여부

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _passwordConfirmController.addListener(_validatePasswordConfirm);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  // 비밀번호 유효성 검사
  bool _isPasswordValid(String password) {
    if (password.length < 8 || password.length > 20) return false;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    return hasUpper && hasLower && hasNumber && hasSpecial;
  }

  // 비밀번호 검증
  void _validatePassword() {
    final password = _passwordController.text;

    setState(() {
      if (password.isEmpty) {
        // 안 적었으면 에러 표시 안 함
        _passwordError = null;
      } else if (!_isPasswordValid(password)) {
        _passwordError = '* 8~20자리의 영문 대소문자, 숫자, 특수문자를 조합해 주세요.';
      } else {
        _passwordError = null;
      }
    });

    // 비밀번호 바뀌면 재입력도 다시 검증
    _validatePasswordConfirm();
  }

  // 비밀번호 재입력 검증
  void _validatePasswordConfirm() {
    final password = _passwordController.text;
    final confirm = _passwordConfirmController.text;

    setState(() {
      if (confirm.isEmpty) {
        _passwordConfirmError = null;
      } else if (password != confirm) {
        _passwordConfirmError = '* 비밀번호가 일치하지 않습니다.';
      } else {
        _passwordConfirmError = null;
      }

      // 두 조건 모두 만족할 때 버튼 활성화
      _isButtonEnabled =
          _isPasswordValid(password) &&
          password == confirm &&
          confirm.isNotEmpty;
    });
  }

  void _handleNext() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignupNicknameScreen(
          email: widget.email, // 이메일 전달
          password: _passwordController.text, // 비밀번호 전달
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String hint, {
    bool hasError = false,
    bool hasSuccess = false,
  }) {
    final borderColor = hasError
        ? const Color(0xFFE24B4A)
        : hasSuccess
            ? const Color(0xFF34C759)
            : AppColors.border;

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: borderColor, width: 1),
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
          '회원가입',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            const Text(
              '밀집계정 로그인에 사용할\n비밀번호를 등록해 주세요.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 32),

            // 밀집계정 라벨 + 이메일
            const Text(
              '밀집계정',
              style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD)),
            ),

            const SizedBox(height: 6),

            Text(
              widget.email,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 24),

            // 비밀번호 라벨
            const Text(
              '비밀번호',
              style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD)),
            ),

            const SizedBox(height: 6),

            // 비밀번호 입력
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration:
                  _buildInputDecoration(
                    '비밀번호 입력 (8~20자리)',
                    hasError: _passwordError != null,
                    hasSuccess: _passwordError == null &&
                        _passwordController.text.isNotEmpty &&
                        _isPasswordValid(_passwordController.text),
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.border,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
            ),

            // 비밀번호 에러 메시지
            if (_passwordError != null) ...[
              const SizedBox(height: 6),
              Text(
                _passwordError!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFE24B4A)),
              ),
            ],

            const SizedBox(height: 10),

            // 비밀번호 재입력
            TextField(
              controller: _passwordConfirmController,
              obscureText: !_isPasswordConfirmVisible,
              decoration:
                  _buildInputDecoration(
                    '비밀번호 재입력',
                    hasError: _passwordConfirmError != null,
                    hasSuccess: _passwordConfirmError == null &&
                        _passwordConfirmController.text.isNotEmpty &&
                        _passwordController.text == _passwordConfirmController.text,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordConfirmVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.border,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordConfirmVisible =
                              !_isPasswordConfirmVisible;
                        });
                      },
                    ),
                  ),
            ),

            // 비밀번호 재입력 에러 메시지
            if (_passwordConfirmError != null) ...[
              const SizedBox(height: 6),
              Text(
                _passwordConfirmError!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFE24B4A)),
              ),
            ],

            // 에러가 없을 때만 회색 안내 문구 표시
            if (_passwordError == null && _passwordConfirmError == null) ...[
              const SizedBox(height: 8),
              const Text(
                '* 비밀번호는 8~20자리의 영문 대소문자, 숫자, 특수문자를 조합하여 설정해 주세요.',
                style: TextStyle(fontSize: 12, color: Color(0xFFADB5BD)),
              ),
            ],

            const SizedBox(height: 24),

            // 다음 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isButtonEnabled ? _handleNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  disabledBackgroundColor: AppColors.border,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
                  '다음',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
