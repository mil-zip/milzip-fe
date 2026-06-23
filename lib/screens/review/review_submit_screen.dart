import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/store.dart';
import '../../models/store_review_draft.dart';
import '../../theme/app_colors.dart';

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
      imageFiles: _images,
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.secondaryDark),
                        const SizedBox(width: 3),
                        Text(
                          '${draft.rating.toStringAsFixed(1)} · $date',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSub,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        draft.visitTypeAnswer,
                        draft.waitTimeAnswer,
                        draft.purposeAnswer,
                        draft.companionAnswer,
                      ].where((s) => s.isNotEmpty).map((s) => _SubmitMetaChip(label: s)).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: Row(
                      children: [
                        Text(
                          draft.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _StaticStarRating(rating: draft.rating),
                      ],
                    ),
                  ),
                  if (draft.benefitSentence.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 34),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: AppColors.primaryAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              draft.benefitSentence,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: draft.goodPoints.map((point) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.badge,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            point,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.textSub,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w500,
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
                                  child: FutureBuilder<Uint8List>(
                                    future: entry.value.readAsBytes(),
                                    builder: (_, snap) => snap.hasData
                                        ? Image.memory(
                                            snap.data!,
                                            width: 150,
                                            height: 150,
                                            fit: BoxFit.cover,
                                          )
                                        : const SizedBox(width: 150, height: 150),
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
              size: 22,
              color: AppColors.textSub,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 24, color: AppColors.textMain),
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
          width: 26,
          height: 26,
          child: Stack(
            children: [
              const Icon(Icons.star_rounded, size: 26, color: Color(0xFFE8E8E8)),
              ClipRect(
                clipper: _StarClipper(fill),
                child: const Icon(
                  Icons.star_rounded,
                  size: 26,
                  color: Color(0xFFFFD600),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SubmitMetaChip extends StatelessWidget {
  final String label;
  const _SubmitMetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSub,
        ),
      ),
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
