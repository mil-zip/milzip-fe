import 'package:flutter/material.dart';
import 'package:milzip/services/auth_service.dart';
import 'package:milzip/theme/app_colors.dart';

/// 마이페이지 → 비밀번호 변경 (3단계)
/// 1단계: 이메일 확인 + 인증코드 발송
/// 2단계: 인증코드 입력
/// 3단계: 새 비밀번호 입력
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  // 단계: 1=코드발송, 2=코드확인, 3=새비밀번호
  int _step = 1;
  bool _isLoading = false;

  String _email = '';
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;
  String? _passwordError;
  String? _passwordConfirmError;
  bool _codeButtonEnabled = false;
  bool _newPasswordButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadEmail();
    _codeController.addListener(() {
      setState(() => _codeButtonEnabled = _codeController.text.length == 6);
    });
    _passwordController.addListener(_validatePasswords);
    _passwordConfirmController.addListener(_validatePasswords);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _loadEmail() async {
    final email = await AuthService.getStoredEmail();
    if (mounted) setState(() => _email = email ?? '');
  }

  bool _isPasswordValid(String pw) {
    if (pw.length < 8 || pw.length > 20) return false;
    return pw.contains(RegExp(r'[A-Z]')) &&
        pw.contains(RegExp(r'[a-z]')) &&
        pw.contains(RegExp(r'[0-9]')) &&
        pw.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  void _validatePasswords() {
    final pw = _passwordController.text;
    final confirm = _passwordConfirmController.text;
    setState(() {
      _passwordError = pw.isNotEmpty && !_isPasswordValid(pw)
          ? '* 8~20자리의 영문 대소문자, 숫자, 특수문자를 조합해 주세요.'
          : null;
      _passwordConfirmError = confirm.isNotEmpty && pw != confirm
          ? '* 비밀번호가 일치하지 않습니다.'
          : null;
      _newPasswordButtonEnabled =
          _isPasswordValid(pw) && pw == confirm && confirm.isNotEmpty;
    });
  }

  // ── 단계별 핸들러 ──────────────────────────────────────

  Future<void> _handleSendCode() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.sendPasswordResetCode(_email);
      setState(() => _step = 2);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyCode() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.verifyPasswordResetCode(_email, _codeController.text.trim());
      setState(() => _step = 3);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.resetPassword(
        email: _email,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 변경되었습니다.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UI 헬퍼 ───────────────────────────────────────────

  InputDecoration _inputDeco(String hint, {bool hasError = false}) {
    final borderColor = hasError ? const Color(0xFFE24B4A) : AppColors.border;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
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
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
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
          '비밀번호 변경',
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              _step == 1
                  ? '본인 확인을 위해\n인증코드를 발송합니다.'
                  : _step == 2
                      ? '이메일로 발송된\n인증코드를 입력해 주세요.'
                      : '새 비밀번호를\n입력해 주세요.',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // ── 1단계: 이메일 표시 + 발송 버튼 ──────────────
            if (_step == 1) ...[
              const Text('등록된 이메일', style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD))),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(_email, style: const TextStyle(fontSize: 14, color: AppColors.textMain)),
              ),
              const SizedBox(height: 24),
              _buildPrimaryButton(
                label: '인증코드 발송',
                onPressed: (_email.isNotEmpty && !_isLoading) ? _handleSendCode : null,
              ),
            ],

            // ── 2단계: 인증코드 입력 ──────────────────────────
            if (_step == 2) ...[
              const Text('인증코드', style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD))),
              const SizedBox(height: 6),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: _inputDeco('인증코드 6자리 입력').copyWith(counterText: ''),
              ),
              const SizedBox(height: 16),
              _buildPrimaryButton(
                label: '확인',
                onPressed: (_codeButtonEnabled && !_isLoading) ? _handleVerifyCode : null,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _handleSendCode,
                  child: const Text('인증코드 재발송', style: TextStyle(color: Color(0xFFADB5BD), fontSize: 13)),
                ),
              ),
            ],

            // ── 3단계: 새 비밀번호 입력 ──────────────────────
            if (_step == 3) ...[
              const Text('새 비밀번호', style: TextStyle(fontSize: 13, color: Color(0xFFADB5BD))),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _inputDeco(
                  '비밀번호 입력 (8~20자리)',
                  hasError: _passwordError != null,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: const Color(0xFFADB5BD),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),
              if (_passwordError != null) ...[
                const SizedBox(height: 6),
                Text(_passwordError!, style: const TextStyle(fontSize: 12, color: Color(0xFFE24B4A))),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _passwordConfirmController,
                obscureText: !_isPasswordConfirmVisible,
                decoration: _inputDeco(
                  '비밀번호 재입력',
                  hasError: _passwordConfirmError != null,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordConfirmVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: const Color(0xFFADB5BD),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isPasswordConfirmVisible = !_isPasswordConfirmVisible),
                  ),
                ),
              ),
              if (_passwordConfirmError != null) ...[
                const SizedBox(height: 6),
                Text(_passwordConfirmError!, style: const TextStyle(fontSize: 12, color: Color(0xFFE24B4A))),
              ],
              if (_passwordError == null && _passwordConfirmError == null) ...[
                const SizedBox(height: 8),
                const Text(
                  '* 비밀번호는 8~20자리의 영문 대소문자, 숫자, 특수문자를 조합해 주세요.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFADB5BD)),
                ),
              ],
              const SizedBox(height: 24),
              _buildPrimaryButton(
                label: '변경 완료',
                onPressed: (_newPasswordButtonEnabled && !_isLoading) ? _handleResetPassword : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
