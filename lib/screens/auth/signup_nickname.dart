import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:milzip/screens/auth/signup_military.dart';
import 'package:milzip/services/auth_service.dart';
import 'package:milzip/theme/app_colors.dart';

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
  final TextEditingController _nameController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_updateButtonState);
    _nameController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled =
          _nicknameController.text.trim().isNotEmpty &&
          _nameController.text.trim().isNotEmpty;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() => _profileImageBytes = bytes);
      }
    } catch (_) {}
  }

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    try {
      final nickname = _nicknameController.text.trim();
      final available = await AuthService.checkNicknameAvailability(nickname);
      if (!available) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 사용 중인 닉네임입니다.')),
        );
        return;
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignupMilitaryScreen(
            email: widget.email,
            password: widget.password,
            nickname: nickname,
            name: _nameController.text.trim(),
            profileImageBytes: _profileImageBytes,
          ),
        ),
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

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
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
      body: SingleChildScrollView(
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

            // 이름 라벨
            const Text(
              '이름 (본명)',
              style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: _buildInputDecoration('실명 입력'),
            ),

            const SizedBox(height: 20),

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
                  style: const TextStyle(fontSize: 13, color: Color(0xFFADB5BD)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nicknameController,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              decoration: _buildInputDecoration('닉네임 입력'),
            ),

            const SizedBox(height: 24),

            // 프로필 사진 라벨
            const Text(
              '프로필 사진 (선택)',
              style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD)),
            ),
            const SizedBox(height: 12),

            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: SizedBox(
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
                          image: _profileImageBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_profileImageBytes!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                      ),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '다음',
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
