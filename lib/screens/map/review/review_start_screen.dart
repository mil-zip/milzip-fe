import 'package:flutter/material.dart';

import '../../../models/store.dart';
import 'review_survey_screen.dart';

class ReviewStartScreen extends StatelessWidget {
  final Store store;

  const ReviewStartScreen({super.key, required this.store});

  void _goSurvey(BuildContext context, String method) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReviewSurveyScreen(store: store, verificationMethod: method),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 28),
                  ),
                  const Spacer(),
                  const Icon(Icons.star_border, size: 36),
                  const SizedBox(width: 18),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 36),
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
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
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
                    icon: '🧾',
                    label: '영수증',
                    onTap: () => _goSurvey(context, '영수증'),
                  ),
                  _MethodCard(
                    icon: '🎥',
                    label: '사진/영상',
                    onTap: () => _goSurvey(context, '사진/영상'),
                  ),
                  _MethodCard(
                    icon: '🔍',
                    label: '검색',
                    onTap: () => _goSurvey(context, '검색'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 42),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 34),
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Text('💳', style: TextStyle(fontSize: 42)),
                  SizedBox(width: 24),
                  Expanded(
                    child: Text(
                      '아직 못 쓴 카드 혜택,\n여기서 확인하세요',
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Text('🫡', style: TextStyle(fontSize: 140)),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 112,
        height: 132,
        decoration: BoxDecoration(
          color: const Color(0xFF8FE0A6),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
