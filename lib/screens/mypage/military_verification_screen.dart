import 'package:flutter/material.dart';
import 'package:milzip/screens/mypage/military_confirm_screen.dart';
import 'package:milzip/services/auth_service.dart';
import 'package:milzip/theme/app_colors.dart';

/// 마이페이지 → 군인 인증 (단순 인증만, 회원가입 데이터 불필요)
class MilitaryVerificationScreen extends StatefulWidget {
  const MilitaryVerificationScreen({super.key});

  @override
  State<MilitaryVerificationScreen> createState() =>
      _MilitaryVerificationScreenState();
}

class _MilitaryVerificationScreenState
    extends State<MilitaryVerificationScreen> {
  final _identityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _sigunguController = TextEditingController();

  String? _selectedSido;
  bool _isLoading = false;

  static const List<String> _sidoList = [
    '서울특별시', '부산광역시', '대구광역시', '인천광역시', '광주광역시',
    '대전광역시', '울산광역시', '세종특별자치시', '경기도', '강원특별자치도',
    '충청북도', '충청남도', '전북특별자치도', '전라남도', '경상북도',
    '경상남도', '제주특별자치도',
  ];

  @override
  void dispose() {
    _identityController.dispose();
    _phoneController.dispose();
    _sigunguController.dispose();
    super.dispose();
  }

  bool get _isButtonEnabled =>
      _identityController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty &&
      _selectedSido != null &&
      _sigunguController.text.trim().isNotEmpty;

  Future<void> _handleRequest() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.requestMilitaryVerification(
        identity: _identityController.text.trim(),
        phoneNo: _phoneController.text.trim(),
        addrSido: _selectedSido!,
        addrSigungu: _sigunguController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MilitaryConfirmScreen()),
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

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
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
      );

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              '군인 인증을\n진행해 주세요.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              '입력한 정보로 카카오톡 간편인증 요청이 발송됩니다.',
              style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD)),
            ),
            const SizedBox(height: 32),

            const Text('주민등록번호', style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD))),
            const SizedBox(height: 6),
            TextField(
              controller: _identityController,
              keyboardType: TextInputType.number,
              obscureText: true,
              onChanged: (_) => setState(() {}),
              decoration: _inputDeco('주민등록번호 입력 (- 없이)'),
            ),

            const SizedBox(height: 16),

            const Text('휴대폰 번호', style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD))),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              decoration: _inputDeco('휴대폰 번호 입력 (- 없이)'),
            ),

            const SizedBox(height: 16),

            const Text('시/도', style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedSido,
              hint: const Text('시/도 선택', style: TextStyle(color: Color(0xFFADB5BD), fontSize: 14)),
              decoration: InputDecoration(
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
              items: _sidoList
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSido = v),
            ),

            const SizedBox(height: 16),

            const Text('시/군/구', style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD))),
            const SizedBox(height: 6),
            TextField(
              controller: _sigunguController,
              onChanged: (_) => setState(() {}),
              decoration: _inputDeco('시/군/구 입력 (예: 송파구)'),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isButtonEnabled && !_isLoading) ? _handleRequest : null,
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
                    : const Text('인증 요청', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
