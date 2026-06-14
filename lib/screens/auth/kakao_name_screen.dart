import 'package:flutter/material.dart';
import 'package:milzip/screens/home.dart';
import 'package:milzip/services/auth_service.dart';
import 'package:milzip/services/user_service.dart';
import 'package:milzip/theme/app_colors.dart';

class KakaoNameScreen extends StatefulWidget {
  const KakaoNameScreen({super.key});

  @override
  State<KakaoNameScreen> createState() => _KakaoNameScreenState();
}

class _KakaoNameScreenState extends State<KakaoNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isButtonEnabled => _nameController.text.trim().isNotEmpty;

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.updateName(_nameController.text.trim());
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
        automaticallyImplyLeading: false,
        title: const Text(
          '프로필 설정',
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
              '서비스 이용을 위해\n본명을 입력해 주세요.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '카카오 계정으로 가입 시 이름 정보가 제공되지 않아\n직접 입력이 필요합니다.',
              style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD), height: 1.5),
            ),
            const SizedBox(height: 32),
            const Text(
              '이름 (본명)',
              style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: '실명 입력',
                hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(color: AppColors.border, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(color: AppColors.border, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isButtonEnabled && !_isLoading) ? _handleConfirm : null,
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        '완료',
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
