import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:milzip/screens/auth/signup_complete.dart';

class SignupNicknameScreen extends StatefulWidget {
  final String email;
  final String password;

  const SignupNicknameScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<SignupNicknameScreen> createState() => _SignupNicknameScreenState();
}

class _SignupNicknameScreenState extends State<SignupNicknameScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      // 한 글자라도 입력하면 버튼 활성화
      _isButtonEnabled = _nicknameController.text.trim().isNotEmpty;
    });
  }

  void _handleConfirm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignupCompleteScreen(
          email: widget.email,
          nickname: _nicknameController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 현재 입력한 글자 수
    final currentLength = _nicknameController.text.length;

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
            // 안내 문구
            const Text(
              '밀집계정 프로필을\n설정해 주세요.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            // 닉네임 라벨 + 글자수 카운터
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '닉네임',
                  style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD)),
                ),
                Text(
                  '$currentLength/20',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFADB5BD),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 닉네임 입력
            TextField(
              controller: _nicknameController,
              // maxLength 제거하고 inputFormatters 사용
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              decoration: InputDecoration(
                hintText: '닉네임 입력',
                hintStyle: const TextStyle(
                  color: Color(0xFFADB5BD),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(
                    color: Color(0xFFD5D7D9),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(
                    color: Color(0xFFD5D7D9),
                    width: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 확인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isButtonEnabled ? _handleConfirm : null,
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
                  '확인',
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
