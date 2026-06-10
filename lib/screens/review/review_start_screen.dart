import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/store.dart';
import '../../models/store_review_draft.dart';
import '../../services/auth_service.dart';
import '../../services/store_review_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/auth_expired_exception.dart';
import '../login_screen.dart';
import 'review_survey_screen.dart';

class ReviewStartScreen extends StatefulWidget {
  final Store store;

  const ReviewStartScreen({super.key, required this.store});

  @override
  State<ReviewStartScreen> createState() => _ReviewStartScreenState();
}

class _ReviewStartScreenState extends State<ReviewStartScreen> {
  bool _verifying = false;
  bool _isMilitary = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadMilitaryStatus();
  }

  Future<void> _loadMilitaryStatus() async {
    final info = await AuthService.getUserInfo();
    if (mounted) {
      setState(() => _isMilitary = info['militaryStatus'] == 'VERIFIED');
    }
  }

  Future<void> _pickAndVerify() async {
    final source = await _showSourcePicker();
    if (source == null) return;

    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image == null) return;

    setState(() => _verifying = true);
    try {
      await StoreReviewApi.verifyReceipt(
        storeId: widget.store.id,
        receiptImage: File(image.path),
      );
      if (!mounted) return;
      _goSurvey('영수증');
    } catch (e) {
      if (!mounted) return;
      if (e is AuthExpiredException) {
        await _showSessionExpiredAndLogin();
        return;
      }
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isNotEmpty ? msg : '영수증 인증에 실패했습니다. 다시 시도해 주세요.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<ImageSource?> _showSourcePicker() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.textMain),
                title: const Text(
                  '카메라로 촬영',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textMain),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.textMain),
                title: const Text(
                  '갤러리에서 선택',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textMain),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSessionExpiredAndLogin() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: const Text(
          '로그인 시간이 만료되었습니다.\n다시 로그인하신 후 리뷰를 이어서 작성하실 수 있습니다.',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '로그인하러 가기',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    PendingNavigation.returnStore = widget.store;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _goSurvey(String method) async {
    final result = await Navigator.push<SubmittedStoreReview>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewSurveyScreen(
          store: widget.store,
          verificationMethod: method,
          isMilitary: _isMilitary,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 상단 바
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 28,
                          color: AppColors.textSub,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          size: 36,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ),

                // 타이틀
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 34),
                  child: Text(
                    '당신의 경험을 공유해주세요!',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 34),
                  child: Text(
                    '영수증으로 방문을 인증해야 리뷰를 작성할 수 있어요.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSub,
                    ),
                  ),
                ),
                const SizedBox(height: 45),
                Image.asset(
                  'assets/images/review_soldier_salute.png',
                  height: 200,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 16),

                // 영수증 인증하기 버튼 (풀 너비)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 34),
                  child: _ReceiptButton(onTap: _pickAndVerify),
                ),

                const Spacer(),

                // 광고 배너 (여백·radius 없이 풀 너비, 맨 아래 고정)
                GestureDetector(
                  onTap: () => launchUrl(
                    Uri.parse('https://m.hanacard.co.kr/MKEVT1010M.web?EVN_SEQ=60171'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Image.asset(
                    'assets/images/card_ad.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ],
            ),

            // 검증 중 로딩 오버레이
            if (_verifying)
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primaryAccent),
                        SizedBox(height: 20),
                        Text(
                          '영수증을 인증하는 중...',
                          style: TextStyle(
                            color: AppColors.textMain,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptButton extends StatefulWidget {
  final VoidCallback onTap;

  const _ReceiptButton({required this.onTap});

  @override
  State<_ReceiptButton> createState() => _ReceiptButtonState();
}

class _ReceiptButtonState extends State<_ReceiptButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: _pressed ? AppColors.pressed : AppColors.primaryAccent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/review_receipt.png',
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 12),
              const Text(
                '영수증 인증하기',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
