import 'package:flutter/material.dart';

import '../../models/store_review.dart';
import '../../services/store_review_api.dart';
import '../../theme/app_colors.dart';
import 'review_edit_screen.dart';

/// isOwner = true 이면 수정/삭제 버튼 노출
class ReviewDetailScreen extends StatefulWidget {
  final StoreReview review;
  final bool isOwner;

  const ReviewDetailScreen({
    super.key,
    required this.review,
    this.isOwner = false,
  });

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  late StoreReview _review;

  @override
  void initState() {
    super.initState();
    _review = widget.review;
  }

  Future<void> _edit() async {
    final updated = await Navigator.push<StoreReview>(
      context,
      MaterialPageRoute(builder: (_) => ReviewEditScreen(review: _review)),
    );
    if (updated == null || !mounted) return;
    setState(() => _review = updated);
    _showSnackBar('리뷰가 수정되었습니다.');
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: const Text(
          '리뷰를 삭제하시겠습니까?\n삭제한 리뷰는 복구할 수 없습니다.',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소',
                style: TextStyle(
                    color: AppColors.textSub, fontWeight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await StoreReviewApi.deleteReview(
        storeId: _review.storeId,
        reviewId: _review.id,
      );
      if (!mounted) return;
      Navigator.pop(context, 'deleted');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final r = _review;

    final metaItems = [
      r.visitTypeLabel,
      r.waitTimeLabel,
      r.visitPurposeLabel,
      r.visitWithLabel,
    ].where((s) => s.isNotEmpty).join(' · ');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context, _review),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 24, color: AppColors.textSub),
                  ),
                  const Spacer(),
                  if (widget.isOwner) ...[
                    TextButton(
                      onPressed: _edit,
                      child: const Text('수정',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMain)),
                    ),
                    TextButton(
                      onPressed: _delete,
                      child: const Text('삭제',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: Colors.red)),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                children: [
                  // 프로필 + 닉네임
                  Row(
                    children: [
                      _ProfileAvatar(url: r.profileImageUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          r.nickname,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 별점 + 날짜
                  Row(
                    children: [
                      Text(
                        r.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _StarRow(rating: r.rating),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.createdDateLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSub,
                    ),
                  ),

                  // 방문 정보
                  if (metaItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        r.visitTypeLabel,
                        r.waitTimeLabel,
                        r.visitPurposeLabel,
                        r.visitWithLabel,
                      ].where((s) => s.isNotEmpty).map((s) => _DetailMetaChip(label: s)).toList(),
                    ),
                  ],

                  // 혜택 여부
                  if (r.benefitStatusLabel.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.verified_user_outlined,
                            color: AppColors.primaryAccent, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          r.benefitStatusLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // 좋았던 점
                  if (r.goodPointLabels.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: r.goodPointLabels.map((label) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.badge,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.badgeText,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // 리뷰 본문
                  if (r.content.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 14),
                    Text(
                      r.content,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.65,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMain,
                      ),
                    ),
                  ],

                  // 이미지
                  if (r.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    ...r.imageUrls.map((url) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              url,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailMetaChip extends StatelessWidget {
  final String label;
  const _DetailMetaChip({required this.label});

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

class _ProfileAvatar extends StatelessWidget {
  final String? url;
  const _ProfileAvatar({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return const CircleAvatar(radius: 20, backgroundColor: Color(0xFFD9D9D9));
    }
    return CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFFD9D9D9),
        backgroundImage: NetworkImage(url!));
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final fill = (rating - i).clamp(0.0, 1.0);
        return SizedBox(
          width: 22,
          height: 22,
          child: Stack(children: [
            const Icon(Icons.star_rounded, size: 22, color: Color(0xFFE8E8E8)),
            ClipRect(
              clipper: _Clip(fill),
              child: const Icon(Icons.star_rounded, size: 22, color: Color(0xFFFFD600)),
            ),
          ]),
        );
      }),
    );
  }
}

class _Clip extends CustomClipper<Rect> {
  final double fill;
  _Clip(this.fill);
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * fill, size.height);
  @override
  bool shouldReclip(covariant _Clip old) => old.fill != fill;
}
