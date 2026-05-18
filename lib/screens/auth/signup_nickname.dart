import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:milzip/screens/auth/signup_complete.dart';
import 'dart:typed_data'; // ← 추가 (Uint8List 사용을 위해)

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

  // 선택된 프로필 사진 (null이면 사진 없음)
  // 변경: 바이트 데이터로 저장 (웹/모바일 둘 다 호환)
  Uint8List? _profileImageBytes;

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
      _isButtonEnabled = _nicknameController.text.trim().isNotEmpty;
    });
  }

  // 갤러리에서 사진 선택
  // 변경: 바이트로 읽어서 저장
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        // 이미지를 바이트로 읽기 (웹/모바일 둘 다 동작)
        final bytes = await image.readAsBytes();
        setState(() {
          _profileImageBytes = bytes;
        });
      }
    } catch (e) {
      print('이미지 선택 에러: $e');
    }
  }

  // 변경: 바이트 데이터 전달
  void _handleConfirm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignupCompleteScreen(
          email: widget.email,
          nickname: _nicknameController.text,
          profileImageBytes: _profileImageBytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // 닉네임 라벨 + 글자수
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
            const SizedBox(height: 24),
            // 프로필 사진 라벨
            const Text(
              '프로필 사진 (선택)',
              style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD)),
            ),
            const SizedBox(height: 12),
            // 프로필 사진 영역 (가운데 정렬)
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    children: [
                      // 프로필 원형
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9ECEF),
                          shape: BoxShape.circle,
                          // 사진이 있으면 이미지로 채우기
                          // 변경: 바이트 데이터를 MemoryImage로 표시
                          image: _profileImageBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_profileImageBytes!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                      ),
                      // 카메라 아이콘 (우측 하단)
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
              ),
            ),
            const SizedBox(height: 24),
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
