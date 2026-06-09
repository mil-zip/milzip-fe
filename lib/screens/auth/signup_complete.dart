import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:milzip/screens/home.dart';
import 'package:milzip/theme/app_colors.dart';

class SignupCompleteScreen extends StatelessWidget {
  final String email;
  final String nickname;
  final Uint8List? profileImageBytes;

  const SignupCompleteScreen({
    super.key,
    required this.email,
    required this.nickname,
    this.profileImageBytes,
  });

  void _handleStart(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
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
          children: [
            const SizedBox(height: 40),

            const Text(
              '환영합니다!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 12),

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
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9ECEF),
                      shape: BoxShape.circle,
                      image: profileImageBytes != null
                          ? DecorationImage(
                              image: MemoryImage(profileImageBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),

                  if (profileImageBytes == null)
                    Positioned(
                      bottom: 0,
                      right: 0,
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              email,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              nickname,
              style: const TextStyle(fontSize: 14, color: Color(0xFFADB5BD)),
            ),

            const SizedBox(height: 40),

            // 시작하기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleStart(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
                  '시작하기',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
