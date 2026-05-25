import 'package:flutter/material.dart';
import 'package:milzip/screens/auth/signup_password.dart'; // 비밀번호 설정

class SignupEmailScreen extends StatefulWidget {
  const SignupEmailScreen({super.key});

  @override
  State<SignupEmailScreen> createState() => _SignupEmailScreenState();
}

class _SignupEmailScreenState extends State<SignupEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  // 인증 요청을 보냈는지 여부 (이걸로 화면 단계 구분)
  bool _isVerificationRequested = false;

  // 안내 문구 (단계에 따라 바뀜)
  String _guideText = '밀집계정으로 사용할\n이메일을 입력해 주세요.';

  // 버튼 활성화 상태
  bool _isVerifyButtonEnabled = false; // 인증요청 버튼
  bool _isNextButtonEnabled = false; // 다음 버튼

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateVerifyButtonState);
    _codeController.addListener(_updateNextButtonState);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // 이메일 입력 시 인증요청 버튼 활성화 체크
  void _updateVerifyButtonState() {
    setState(() {
      _isVerifyButtonEnabled = _emailController.text.isNotEmpty;
    });
  }

  // 인증번호 6자리 입력 시 다음 버튼 활성화 체크
  void _updateNextButtonState() {
    setState(() {
      _isNextButtonEnabled = _codeController.text.length == 6;
    });
  }

  // 인증요청 버튼 클릭
  void _handleVerificationRequest() {
    // TODO: 실제 인증번호 발송 API 호출
    print('인증번호 발송: ${_emailController.text}');

    // 화면 단계 변경
    setState(() {
      _isVerificationRequested = true;
      _guideText = '이메일로 발송된\n인증번호를 입력해 주세요.';
    });
  }

  // 다음 버튼 클릭
  void _handleNext() {
    // TODO: 인증번호 검증 API 호출
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignupPasswordScreen(
          email: _emailController.text, // 이메일 전달
        ),
      ),
    );
  }

  // 공통 입력 필드 데코레이션
  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFFD5D7D9), width: 1),
      ),
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

            // 안내 문구 (단계에 따라 텍스트 변경)
            Text(
              _guideText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 32),

            // ========== 1단계 (인증 요청 전): 이메일 + 인증요청 버튼 ==========
            if (!_isVerificationRequested) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration('이메일 입력'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  ElevatedButton(
                    onPressed: _isVerifyButtonEnabled
                        ? _handleVerificationRequest
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF96D484),
                      disabledBackgroundColor: const Color(0xFFADB5BD),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      '인증요청',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              const Text(
                '* 입력한 이메일로 인증번호가 발송됩니다.',
                style: TextStyle(fontSize: 12, color: Color(0xFFADB5BD)),
              ),
            ],

            // ========== 2단계 (인증 요청 후): 이메일(읽기전용) + 인증번호 입력 ==========
            if (_isVerificationRequested) ...[
              // 이메일 표시 (읽기 전용)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD5D7D9), width: 1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  _emailController.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF495057),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 인증번호 입력
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: _buildInputDecoration(
                  '인증번호 6자 입력',
                ).copyWith(counterText: ''),
              ),
            ],

            const SizedBox(height: 16),

            // 다음 버튼 (양 단계 모두 표시)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerificationRequested && _isNextButtonEnabled
                    ? _handleNext
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF96D484),
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
