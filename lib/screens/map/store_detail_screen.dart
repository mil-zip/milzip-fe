import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/store.dart';
import '../../models/store_review_draft.dart';
import '../../theme/app_colors.dart';
import 'review/review_start_screen.dart';

class StoreDetailScreen extends StatefulWidget {
  final Store store;

  const StoreDetailScreen({super.key, required this.store});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  static const double _baseAverageRating = 4.8;
  static const int _baseReviewCount = 1562;

  int _selectedTabIndex = 0;
  int _selectedReviewTypeIndex = 0;
  bool _isFavorite = false;

  final List<SubmittedStoreReview> _submittedReviews = [];

  final List<String> _baseImageAssets = const [
    'assets/images/store_yukhoe_1.png',
    'assets/images/store_yukhoe_2.png',
    'assets/images/store_yukhoe_3.png',
    'assets/images/store_yukhoe_4.png',
    'assets/images/store_yukhoe_5.png',
  ];

  List<String> get _submittedImagePaths {
    return _submittedReviews.expand((review) => review.imagePaths).toList();
  }

  double get _averageRating {
    if (_submittedReviews.isEmpty) return _baseAverageRating;

    final submittedScore = _submittedReviews.fold<double>(
      0,
      (sum, review) => sum + review.draft.rating,
    );

    final totalScore = (_baseAverageRating * _baseReviewCount) + submittedScore;
    final totalCount = _baseReviewCount + _submittedReviews.length;

    return totalScore / totalCount;
  }

  int get _totalReviewCount {
    return _baseReviewCount + _submittedReviews.length;
  }

  Future<void> _openReviewWriteScreen() async {
    final result = await Navigator.push<SubmittedStoreReview>(
      context,
      MaterialPageRoute(builder: (_) => ReviewStartScreen(store: widget.store)),
    );

    if (result == null) return;

    setState(() {
      _submittedReviews.insert(0, result);
      _selectedTabIndex = 3;
      _selectedReviewTypeIndex = 0;
    });
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? '즐겨찾기에 추가되었습니다.' : '즐겨찾기가 해제되었습니다.'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _StoreDetailHeader(
              isFavorite: _isFavorite,
              onFavoriteToggle: _toggleFavorite,
              onBack: () => Navigator.pop(context),
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StoreSummary(
                      store: store,
                      averageRating: _averageRating,
                      onWriteReview: _openReviewWriteScreen,
                    ),
                    const SizedBox(height: 24),
                    _PhotoCarousel(imageAssets: _baseImageAssets),
                    const SizedBox(height: 28),
                    _DetailTabs(
                      selectedIndex: _selectedTabIndex,
                      onChanged: (index) {
                        setState(() {
                          _selectedTabIndex = index;
                        });
                      },
                    ),
                    _buildSelectedTabContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _HomeTabContent(store: widget.store);
      case 1:
        return _MenuTabContent(store: widget.store);
      case 2:
        return _BenefitTabContent(store: widget.store);
      case 3:
        return _ReviewTabContent(
          selectedReviewTypeIndex: _selectedReviewTypeIndex,
          submittedReviews: _submittedReviews,
          averageRating: _averageRating,
          totalReviewCount: _totalReviewCount,
          onReviewTypeChanged: (index) {
            setState(() {
              _selectedReviewTypeIndex = index;
            });
          },
        );
      case 4:
        return _PhotoTabContent(
          assetImages: _baseImageAssets,
          submittedImagePaths: _submittedImagePaths,
        );
      default:
        return _HomeTabContent(store: widget.store);
    }
  }
}

class _StoreDetailHeader extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _StoreDetailHeader({
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
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
          IconButton(
            onPressed: onFavoriteToggle,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                key: ValueKey(isFavorite),
                size: 38,
                color: isFavorite
                    ? AppColors.secondaryDark
                    : AppColors.textMain,
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 38, color: AppColors.textMain),
          ),
        ],
      ),
    );
  }
}

class _StoreSummary extends StatelessWidget {
  final Store store;
  final double averageRating;
  final VoidCallback onWriteReview;

  const _StoreSummary({
    required this.store,
    required this.averageRating,
    required this.onWriteReview,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 42, 34, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            store.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const _RecommendBadge(),
              const SizedBox(width: 8),
              Text(
                '★${averageRating.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textSub,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _ReviewWriteButton(onPressed: onWriteReview),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: AppColors.primaryAccent,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  store.benefitDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '현재 영업 중 · ${store.closeTime}에 영업 종료',
            style: const TextStyle(
              fontSize: 19,
              height: 1.35,
              color: AppColors.textSub,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '1.2km',
            style: TextStyle(
              fontSize: 19,
              height: 1.35,
              color: AppColors.textSub,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewWriteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ReviewWriteButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.badge,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        splashColor: AppColors.primaryHover.withOpacity(0.16),
        highlightColor: AppColors.pressed.withOpacity(0.10),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            '리뷰 작성',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textMain,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoCarousel extends StatelessWidget {
  final List<String> imageAssets;

  const _PhotoCarousel({required this.imageAssets});

  @override
  Widget build(BuildContext context) {
    final viewerItems = imageAssets
        .map((path) => _PhotoViewerItem(path: path, isAsset: true))
        .toList();

    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 34),
        itemCount: imageAssets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return _StorePhoto(
            path: imageAssets[index],
            isAsset: true,
            isPrimary: index == 0,
            width: 260,
            height: 210,
            viewerItems: viewerItems,
            initialIndex: index,
          );
        },
      ),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _DetailTabs({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tabs = ['홈', '메뉴', '군혜택', '리뷰', '사진'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final selected = selectedIndex == index;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(index),
                  child: SizedBox(
                    height: 54,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tabs[index],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: selected
                                ? AppColors.textMain
                                : AppColors.textSub,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: selected ? 34 : 0,
                          height: 3,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.textMain
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _HomeTabContent extends StatelessWidget {
  final Store store;

  const _HomeTabContent({required this.store});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 24, 34, 46),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailInfoRow(icon: Icons.push_pin, text: store.address),
          _DetailInfoRow(
            icon: Icons.access_time,
            text:
                '현재 영업 중 · ${store.closeTime}에 영업 종료\n운영 시간 ${store.businessHours}',
          ),
          _DetailInfoRow(icon: Icons.phone, text: store.phone),
          _DetailInfoRow(icon: Icons.restaurant, text: '대표 메뉴 ${store.menu}'),
        ],
      ),
    );
  }
}

class _MenuTabContent extends StatelessWidget {
  final Store store;

  const _MenuTabContent({required this.store});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 28, 34, 46),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '대표 메뉴',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu, size: 28),
                const SizedBox(width: 14),
                Text(
                  store.menu,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitTabContent extends StatelessWidget {
  final Store store;

  const _BenefitTabContent({required this.store});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 28, 34, 46),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.badge,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '군장병 혜택',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.primaryAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    store.benefitDescription,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              '방문 전 매장에 군인 할인 적용 가능 여부를 한 번 더 확인해주세요.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSub,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTabContent extends StatelessWidget {
  final int selectedReviewTypeIndex;
  final List<SubmittedStoreReview> submittedReviews;
  final double averageRating;
  final int totalReviewCount;
  final ValueChanged<int> onReviewTypeChanged;

  const _ReviewTabContent({
    required this.selectedReviewTypeIndex,
    required this.submittedReviews,
    required this.averageRating,
    required this.totalReviewCount,
    required this.onReviewTypeChanged,
  });

  String _formatCount(int count) {
    return count.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 28, 34, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewSegmentedControl(
            selectedIndex: selectedReviewTypeIndex,
            onChanged: onReviewTypeChanged,
          ),
          const SizedBox(height: 26),
          Text(
            '⭐ ${averageRating.toStringAsFixed(1)} · ${_formatCount(totalReviewCount)}명의 군인들이 참여했어요',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textSub,
            ),
          ),
          const SizedBox(height: 22),
          const _ReviewKeywordRow(emoji: '🍗', text: '음식이 맛있어요', count: 670),
          const _ReviewKeywordRow(
            emoji: '🛋️',
            text: '식당 분위기가 좋아요',
            count: 453,
          ),
          const _ReviewKeywordRow(emoji: '🏃', text: '웨이팅이 없어요', count: 239),
          const _ReviewKeywordRow(emoji: '💳', text: '할인율이 높아요', count: 140),
          const _ReviewKeywordRow(emoji: '👥', text: '회식하기 좋아요', count: 111),
          const SizedBox(height: 34),
          const Divider(color: AppColors.border),
          const SizedBox(height: 24),
          ...submittedReviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: _SubmittedReviewCard(review: review),
            ),
          ),
          const _DummyReviewCard(),
        ],
      ),
    );
  }
}

class _ReviewSegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ReviewSegmentedControl({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['🫡 군장병 리뷰', '일반 리뷰'];

    return Container(
      height: 72,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryAccent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: selected ? AppColors.textWhite : AppColors.textMain,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ReviewKeywordRow extends StatelessWidget {
  final String emoji;
  final String text;
  final int count;

  const _ReviewKeywordRow({
    required this.emoji,
    required this.text,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmittedReviewCard extends StatelessWidget {
  final SubmittedStoreReview review;

  const _SubmittedReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final draft = review.draft;
    final date =
        '${review.createdAt.year}.${review.createdAt.month.toString().padLeft(2, '0')}.${review.createdAt.day.toString().padLeft(2, '0')}';
    final viewerItems = review.imagePaths
        .map((path) => _PhotoViewerItem(path: path, isAsset: false))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              review.nickname,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textMain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          '🛡️ ${draft.waitTimeAnswer} · ${draft.purposeAnswer} · ${draft.companionAnswer} ★${draft.rating.toStringAsFixed(1)}',
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w900,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$date · ${draft.verificationMethod}',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSub,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          draft.benefitSentence,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.primaryAccent,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: draft.goodPoints.map((point) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.badge,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                point,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
            );
          }).toList(),
        ),
        if (review.content.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            review.content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.55,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
        ],
        if (review.imagePaths.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: review.imagePaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return _StorePhoto(
                  path: review.imagePaths[index],
                  isAsset: false,
                  width: 124,
                  height: 124,
                  viewerItems: viewerItems,
                  initialIndex: index,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _DummyReviewCard extends StatelessWidget {
  const _DummyReviewCard();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _DummyProfile(),
            SizedBox(width: 14),
            Text(
              '뽀야미',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textMain,
              ),
            ),
          ],
        ),
        SizedBox(height: 18),
        Text(
          '🛡️ 점심에 방문 예약 없이 이용  대기시간 바로 입장 ★4.9',
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w900,
            color: AppColors.textMain,
          ),
        ),
        SizedBox(height: 14),
        Text(
          '분위기 나쁘지 않고 맛있게 먹었습니다. 근데 한 가지 아쉬운 점은 물이 미지근하다는 점입니다. 물은 셀프고요',
          style: TextStyle(
            fontSize: 16,
            height: 1.55,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
      ],
    );
  }
}

class _DummyProfile extends StatelessWidget {
  const _DummyProfile();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      child: SizedBox(width: 54, height: 54),
    );
  }
}

class _PhotoTabContent extends StatelessWidget {
  final List<String> assetImages;
  final List<String> submittedImagePaths;

  const _PhotoTabContent({
    required this.assetImages,
    required this.submittedImagePaths,
  });

  @override
  Widget build(BuildContext context) {
    final assetItems = assetImages
        .map((path) => _PhotoViewerItem(path: path, isAsset: true))
        .toList();
    final submittedItems = submittedImagePaths
        .map((path) => _PhotoViewerItem(path: path, isAsset: false))
        .toList();
    final viewerItems = [...assetItems, ...submittedItems];
    final totalCount = viewerItems.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '사진 $totalCount',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final item = viewerItems[index];

              return _StorePhoto(
                path: item.path,
                isAsset: item.isAsset,
                width: double.infinity,
                height: double.infinity,
                viewerItems: viewerItems,
                initialIndex: index,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: AppColors.textSub),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                height: 1.45,
                color: AppColors.textSub,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoViewerItem {
  final String path;
  final bool isAsset;

  const _PhotoViewerItem({required this.path, required this.isAsset});
}

class _StorePhoto extends StatelessWidget {
  final String path;
  final bool isAsset;
  final bool isPrimary;
  final double width;
  final double height;
  final List<_PhotoViewerItem> viewerItems;
  final int initialIndex;

  const _StorePhoto({
    required this.path,
    required this.isAsset,
    required this.width,
    required this.height,
    required this.viewerItems,
    required this.initialIndex,
    this.isPrimary = false,
  });

  void _openPhotoViewer(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.88),
      builder: (_) {
        return _PhotoViewerDialog(
          items: viewerItems,
          initialIndex: initialIndex,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);

    return GestureDetector(
      onTap: () => _openPhotoViewer(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: isPrimary
              ? Border.all(color: AppColors.primaryAccent, width: 3)
              : null,
        ),
        clipBehavior: Clip.hardEdge,
        child: isAsset
            ? Image.asset(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _ImageFallback(path: path),
              )
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _ImageFallback(path: path),
              ),
      ),
    );
  }
}

class _PhotoViewerDialog extends StatefulWidget {
  final List<_PhotoViewerItem> items;
  final int initialIndex;

  const _PhotoViewerDialog({required this.items, required this.initialIndex});

  @override
  State<_PhotoViewerDialog> createState() => _PhotoViewerDialogState();
}

class _PhotoViewerDialogState extends State<_PhotoViewerDialog> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImage(_PhotoViewerItem item) {
    if (item.isAsset) {
      return Image.asset(
        item.path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _ImageFallback(path: item.path),
      );
    }

    return Image.file(
      File(item.path),
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _ImageFallback(path: item.path),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final item = widget.items[index];

                return Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: _buildImage(item),
                  ),
                );
              },
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 34),
              ),
            ),
            if (widget.items.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 22,
                child: Text(
                  '${_currentIndex + 1} / ${widget.items.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final String path;

  const _ImageFallback({required this.path});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceSoft,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: Text(
        path,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSub,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RecommendBadge extends StatelessWidget {
  const _RecommendBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.badge,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primaryAccent),
      ),
      child: const Text(
        '밀집추천',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.badgeText,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
