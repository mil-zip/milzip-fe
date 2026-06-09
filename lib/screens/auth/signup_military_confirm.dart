import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:milzip/screens/auth/signup_complete.dart';
import 'package:milzip/services/auth_service.dart';
import 'package:milzip/services/user_service.dart';
import 'package:milzip/theme/app_colors.dart';

class SignupMilitaryConfirmScreen extends StatefulWidget {
  final String email;
  final String password;
  final String nickname;
  final String name;
  final Uint8List? profileImageBytes;

  const SignupMilitaryConfirmScreen({
    super.key,
    required this.email,
    required this.password,
    required this.nickname,
    required this.name,
    this.profileImageBytes,
  });

  @override
  State<SignupMilitaryConfirmScreen> createState() =>
      _SignupMilitaryConfirmScreenState();
}

class _SignupMilitaryConfirmScreenState
    extends State<SignupMilitaryConfirmScreen> {
  bool _isLoading = false;

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    try {
      // 2차: 인증 확인
      await AuthService.confirmMilitaryVerification();

      // 인증 완료 후 회원가입
      await AuthService.register(
        email: widget.email,
        password: widget.password,
        nickname: widget.nickname,
        name: widget.name,
        profileImageBytes: widget.profileImageBytes,
      );
      // 회원가입 후 자동 로그인 + 유저 정보 캐시
      await AuthService.login(widget.email, widget.password);
      await UserService.getMyInfo();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => SignupCompleteScreen(
            email: widget.email,
            nickname: widget.nickname,
            profileImageBytes: widget.profileImageBytes,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          '군인 인증',
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
            const SizedBox(height: 60),

            // 카카오톡 아이콘 영역
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE500),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  '카카오톡',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191600),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              '카카오톡 앱에서\n인증을 진행해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              '카카오톡 간편인증을 완료한 후\n하단의 인증완료 버튼을 클릭해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.6,
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleConfirm,
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
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '인증 완료하기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
