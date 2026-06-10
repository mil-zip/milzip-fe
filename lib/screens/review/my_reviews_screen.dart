import 'package:flutter/material.dart';

import '../../models/store_review.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import 'review_detail_screen.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<StoreReview> _reviews = [];
  bool _loading = false;
  bool _hasNext = false;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews(refresh: true);
  }

  Future<void> _loadReviews({bool refresh = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final nextPage = refresh ? 0 : _page + 1;
      final result = await UserService.getMyReviews(page: nextPage, size: 10);
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _reviews = result.content;
        } else {
          _reviews = [..._reviews, ...result.content];
        }
        _hasNext = result.hasNext;
        _page = nextPage;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(StoreReview review) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewDetailScreen(review: review, isOwner: true),
      ),
    );
    if (!mounted) return;
    if (result == 'deleted') {
      setState(() => _reviews.removeWhere((r) => r.id == review.id));
      _showSnackBar('리뷰가 삭제되었습니다.');
    } else if (result is StoreReview) {
      setState(() {
        final idx = _reviews.indexWhere((r) => r.id == result.id);
        if (idx >= 0) _reviews[idx] = result;
      });
      _showSnackBar('리뷰가 수정되었습니다.');
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 24, color: AppColors.textSub),
                  ),
                  const Expanded(
                    child: Text(
                      '내 리뷰',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMain,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            if (_loading && _reviews.isEmpty)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primaryAccent),
                ),
              )
            else if (_reviews.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    '작성한 리뷰가 없습니다.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSub,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primaryAccent,
                  onRefresh: () => _loadReviews(refresh: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    itemCount: _reviews.length + (_hasNext ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      if (index == _reviews.length) {
                        // 더 불러오기
                        _loadReviews();
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primaryAccent),
                          ),
                        );
                      }
                      return _ReviewCard(
                        review: _reviews[index],
                        onTap: () => _openDetail(_reviews[index]),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final StoreReview review;
  final VoidCallback onTap;

  const _ReviewCard({required this.review, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final metaItems = [
      review.visitTypeLabel,
      review.waitTimeLabel,
      review.visitPurposeLabel,
      review.visitWithLabel,
    ].where((s) => s.isNotEmpty).join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 별점 + 날짜
          Row(
            children: [
              Text(
                '★${review.rating.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF3B30),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                review.createdDateLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSub,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.textSub, size: 20),
            ],
          ),

          // 방문 정보
          if (metaItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              metaItems,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSub,
              ),
            ),
          ],

          // 혜택 여부
          if (review.benefitStatusLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.benefitStatusLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryAccent,
              ),
            ),
          ],

          // 좋았던 점 태그
          if (review.goodPointLabels.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: review.goodPointLabels.map((label) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.badge,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.badgeText,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // 리뷰 본문
          if (review.content.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.55,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
          ],

          // 이미지
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    review.imageUrls[i],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),  // Container
    );  // GestureDetector
  }
}
