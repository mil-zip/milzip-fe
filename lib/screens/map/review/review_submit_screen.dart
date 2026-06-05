import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/store.dart';
import '../../../models/store_review_draft.dart';
import '../../../theme/app_colors.dart';

class ReviewSubmitScreen extends StatefulWidget {
  final Store store;
  final StoreReviewDraft draft;

  const ReviewSubmitScreen({
    super.key,
    required this.store,
    required this.draft,
  });

  @override
  State<ReviewSubmitScreen> createState() => _ReviewSubmitScreenState();
}

class _ReviewSubmitScreenState extends State<ReviewSubmitScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  bool get canRegister => _contentController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _images.add(image);
    });
  }

  void _register() {
    if (!canRegister) return;

    final submitted = SubmittedStoreReview(
      draft: widget.draft,
      content: _contentController.text.trim(),
      imagePaths: _images.map((image) => image.path).toList(),
      createdAt: DateTime.now(),
    );

    Navigator.pop(context, submitted);
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final now = DateTime.now();
    final date =
        '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(34, 10, 34, 18),
        child: Align(
          alignment: Alignment.centerRight,
          heightFactor: 1,
          child: ElevatedButton(
            onPressed: canRegister ? _register : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              disabledBackgroundColor: AppColors.surfaceSoft,
              foregroundColor: AppColors.textWhite,
              disabledForegroundColor: AppColors.textSub,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
              '등록',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _SubmitHeader(
              onBack: () => Navigator.pop(context),
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 34),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: Text(
                      widget.store.name,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: Text(
                      '★${draft.rating.toStringAsFixed(1)} · $date · 1번째 방문',
                      style: const TextStyle(
                        fontSize: 17,
                        color: AppColors.textSub,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: Text(
                      '${draft.waitTimeAnswer} · ${draft.purposeAnswer} · ${draft.companionAnswer}',
                      style: const TextStyle(
                        fontSize: 17,
                        color: AppColors.textSub,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: Row(
                      children: [
                        Text(
                          draft.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF5A4F),
                          ),
                        ),
                        const SizedBox(width: 18),
                        _StaticStarRating(rating: draft.rating),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.primaryAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            draft.benefitSentence,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: draft.goodPoints.map((point) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.badge,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            point,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.badgeText,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 34),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _contentController,
                      maxLines: 6,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText:
                            '✎ 당신의 후기를 작성해주세요!\n\n리뷰 작성 시 욕설, 비방, 명예훼손성 표현은 삼가해주세요.',
                        hintStyle: TextStyle(
                          fontSize: 17,
                          height: 1.45,
                          color: AppColors.textSub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.45,
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: Row(
                      children: [
                        ..._images.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(entry.value.path),
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _images.removeAt(entry.key);
                                      });
                                    },
                                    child: const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppColors.pressed,
                                      child: Icon(
                                        Icons.close,
                                        color: AppColors.textWhite,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 42,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _SubmitHeader({required this.onBack, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 28,
              color: AppColors.textSub,
            ),
          ),
          const Spacer(),
          const Icon(Icons.star_border, size: 36, color: AppColors.textMain),
          const SizedBox(width: 18),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 36, color: AppColors.textMain),
          ),
        ],
      ),
    );
  }
}

class _StaticStarRating extends StatelessWidget {
  final double rating;

  const _StaticStarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final fill = (rating - index).clamp(0.0, 1.0);

        return SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            children: [
              const Icon(Icons.star, size: 38, color: Color(0xFFF0F0F0)),
              ClipRect(
                clipper: _StarClipper(fill),
                child: const Icon(
                  Icons.star,
                  size: 38,
                  color: Color(0xFFFF5A4F),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StarClipper extends CustomClipper<Rect> {
  final double fill;

  _StarClipper(this.fill);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fill, size.height);
  }

  @override
  bool shouldReclip(covariant _StarClipper oldClipper) {
    return oldClipper.fill != fill;
  }
}
