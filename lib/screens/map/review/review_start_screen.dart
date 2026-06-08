import 'package:flutter/material.dart';

import '../../../models/store.dart';
import '../../../models/store_review_draft.dart';
import '../../../theme/app_colors.dart';
import 'review_survey_screen.dart';

class ReviewStartScreen extends StatelessWidget {
  final Store store;

  const ReviewStartScreen({super.key, required this.store});

  Future<void> _goSurvey(BuildContext context, String method) async {
    final result = await Navigator.push<SubmittedStoreReview>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReviewSurveyScreen(store: store, verificationMethod: method),
      ),
    );

    if (result != null && context.mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 34),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '당신의 경험을 공유해주세요!',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MethodCard(
                    imageAsset: 'assets/images/review_receipt.png',
                    label: '영수증',
                    onTap: () => _goSurvey(context, '영수증'),
                  ),
                  _MethodCard(
                    imageAsset: 'assets/images/review_video.png',
                    label: '사진/영상',
                    onTap: () => _goSurvey(context, '사진/영상'),
                  ),
                  _MethodCard(
                    imageAsset: 'assets/images/review_search.png',
                    label: '검색',
                    onTap: () => _goSurvey(context, '검색'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 42),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 34),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/review_card.png',
                    width: 58,
                    height: 58,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 24),
                  const Expanded(
                    child: Text(
                      '아직 못 쓴 카드 혜택,\n여기서 확인하세요',
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Image.asset(
              'assets/images/review_soldier_salute.png',
              width: 300,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatefulWidget {
  final String imageAsset;
  final String label;
  final VoidCallback onTap;

  const _MethodCard({
    required this.imageAsset,
    required this.label,
    required this.onTap,
  });

  @override
  State<_MethodCard> createState() => _MethodCardState();
}

class _MethodCardState extends State<_MethodCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _pressed ? AppColors.pressed : AppColors.badge;
    final borderColor = _pressed ? AppColors.pressed : AppColors.border;
    final textColor = _pressed ? AppColors.textWhite : AppColors.textMain;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 112,
          height: 132,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(widget.imageAsset, width: 58, height: 58),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
