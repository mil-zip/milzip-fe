import 'package:flutter/material.dart';
import 'package:milzip/services/auth_service.dart';
import 'package:milzip/theme/app_colors.dart';

/// 마이페이지 → 군인 인증 2차 확인 (카카오톡 인증 완료 후 버튼 클릭)
class MilitaryConfirmScreen extends StatefulWidget {
  const MilitaryConfirmScreen({super.key});

  @override
  State<MilitaryConfirmScreen> createState() => _MilitaryConfirmScreenState();
}

class _MilitaryConfirmScreenState extends State<MilitaryConfirmScreen> {
  bool _isLoading = false;

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.confirmMilitaryVerification();
      // 인증 완료 → 로컬 military_status 갱신
      final info = await AuthService.getUserInfo();
      await AuthService.saveUserInfo(
        email: info['email'] ?? '',
        nickname: info['nickname'] ?? '',
        militaryStatus: 'VERIFIED',
        profileImageUrl: info['profileImageUrl'],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('군인 인증이 완료되었습니다.')),
      );
      // my page로 돌아가기 (verify screen + confirm screen 둘 다 pop)
      Navigator.popUntil(context, (route) => route.isFirst || route.settings.name == '/home');
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
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 60),

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
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF191600)),
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              '카카오톡 앱에서\n인증을 진행해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.5),
            ),

            const SizedBox(height: 16),

            const Text(
              '카카오톡 간편인증을 완료한 후\n하단의 인증완료 버튼을 클릭해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.6),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('인증 완료하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
