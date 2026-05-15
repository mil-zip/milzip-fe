import 'package:flutter/material.dart';

class SignupCompleteScreen extends StatelessWidget {
  final String email;
  final String nickname;

  const SignupCompleteScreen({
    super.key,
    required this.email,
    required this.nickname,
  });

  void _handleStart(BuildContext context) {
    // TODO: 메인 화면으로 이동 (지금은 임시로 콘솔 출력만)
    print('시작하기! 이메일: $email, 닉네임: $nickname');
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
          children: [
            const SizedBox(height: 40),
            // 환영합니다 타이틀
            const Text(
              '환영합니다!',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            // 안내 문구
            const Text(
              '밀집계정 가입이 완료되었습니다.\n밀집의 다양한 서비스를 편리하게 이용해 보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF495057),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 48),
            // 프로필 영역
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                children: [
                  // 회색 원형 프로필 (기본)
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9ECEF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // 우측 하단 카메라 아이콘
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: 프로필 이미지 선택
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFFADB5BD),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 이메일 (이전 화면에서 받은 값)
            Text(
              email,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            // 닉네임 (이전 화면에서 받은 값)
            Text(
              nickname,
              style: const TextStyle(fontSize: 17, color: Color(0xFFADB5BD)),
            ),
            const SizedBox(height: 40),
            // 시작하기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleStart(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F3F5),
                  foregroundColor: const Color(0xFF495057),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
                  '시작하기',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
