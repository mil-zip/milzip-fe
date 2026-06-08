import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/store.dart';
import '../../models/store_review.dart';
import '../../models/store_review_draft.dart';
import '../../services/store_api.dart';
import '../../services/store_review_api.dart';
import '../../theme/app_colors.dart';
import 'review/review_start_screen.dart';

class StoreDetailScreen extends StatefulWidget {
  final Store store;

  const StoreDetailScreen({super.key, required this.store});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  late Store _store;

  bool _isFavorite = false;
  bool _loadingStore = false;
  bool _loadingReviews = false;
  int _selectedTabIndex = 0;

  List<StoreReview> _serverReviews = [];
  final List<SubmittedStoreReview> _submittedReviews = [];

  final List<String> _fallbackImageAssets = const [
    'assets/images/store_yukhoe_1.png',
    'assets/images/store_yukhoe_2.png',
    'assets/images/store_yukhoe_3.png',
    'assets/images/store_yukhoe_4.png',
    'assets/images/store_yukhoe_5.png',
  ];

  @override
  void initState() {
    super.initState();
    _store = widget.store;
    _loadStoreDetail();
    _loadReviews();
  }

  Future<void> _loadStoreDetail() async {
    setState(() {
      _loadingStore = true;
    });

    try {
      final detail = await StoreApi.getDetail(widget.store.id);

      if (!mounted) return;

      setState(() {
        _store = detail;
      });
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('매장 상세 정보를 불러오지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingStore = false;
        });
      }
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loadingReviews = true;
    });

    try {
      final page = await StoreReviewApi.getList(
        storeId: widget.store.id,
        page: 0,
        size: 10,
      );

      if (!mounted) return;

      setState(() {
        _serverReviews = page.content;
      });
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('리뷰를 불러오지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingReviews = false;
        });
      }
    }
  }

  List<_StoreImageItem> get _imageItems {
    final networkImages = _store.imageUrls
        .where((url) => url.trim().isNotEmpty && url.trim() != 'string')
        .map(_StoreImageItem.network)
        .toList();

    final fallbackImages = _fallbackImageAssets.map(_StoreImageItem.asset);

    final serverReviewImages = _serverReviews
        .expand((review) => review.imageUrls)
        .where((url) => url.trim().isNotEmpty)
        .map(_StoreImageItem.network)
        .toList();

    final localReviewImages = _submittedReviews
        .expand((review) => review.imagePaths)
        .map(_StoreImageItem.file)
        .toList();

    if (networkImages.isNotEmpty) {
      return [...networkImages, ...serverReviewImages, ...localReviewImages];
    }

    return [...fallbackImages, ...serverReviewImages, ...localReviewImages];
  }

  double get _averageRating {
    final ratings = [
      ..._serverReviews.map((review) => review.rating),
      ..._submittedReviews.map((review) => review.draft.rating),
    ];

    if (ratings.isEmpty) return 4.8;

    final sum = ratings.fold<double>(0, (total, rating) => total + rating);
    return sum / ratings.length;
  }

  int get _reviewCount {
    return _serverReviews.length + _submittedReviews.length;
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    _showSnackBar(_isFavorite ? '즐겨찾기에 저장되었습니다.' : '즐겨찾기가 해제되었습니다.');
  }

  Future<void> _openReviewWriteScreen() async {
    final result = await Navigator.push<SubmittedStoreReview>(
      context,
      MaterialPageRoute(builder: (_) => ReviewStartScreen(store: _store)),
    );

    if (result == null || !mounted) return;

    setState(() {
      _submittedReviews.insert(0, result);
      _selectedTabIndex = 3;
    });

    _showSnackBar('리뷰가 등록되었습니다.');
  }

  void _showImageViewer(int initialIndex) {
    _openImageViewer(context, _imageItems, initialIndex);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageItems = _imageItems;
    final loading = _loadingStore || _loadingReviews;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              isFavorite: _isFavorite,
              onBack: () => Navigator.pop(context),
              onFavoriteTap: _toggleFavorite,
              onClose: () => Navigator.pop(context),
            ),
            if (loading)
              const LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.primaryAccent,
                backgroundColor: Colors.transparent,
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                      child: _StoreSummary(
                        store: _store,
                        rating: _averageRating,
                        onReviewTap: _openReviewWriteScreen,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _PhotoCarousel(
                      images: imageItems,
                      onImageTap: _showImageViewer,
                    ),
                    const SizedBox(height: 28),
                    _DetailTabs(
                      selectedIndex: _selectedTabIndex,
                      onTap: (index) {
                        setState(() {
                          _selectedTabIndex = index;
                        });
                      },
                    ),
                    IndexedStack(
                      index: _selectedTabIndex,
                      children: [
                        _HomeTabContent(store: _store),
                        _MenuTabContent(store: _store),
                        _BenefitTabContent(store: _store),
                        _ReviewTabContent(
                          rating: _averageRating,
                          reviewCount: _reviewCount,
                          serverReviews: _serverReviews,
                          submittedReviews: _submittedReviews,
                        ),
                        _PhotoTabContent(
                          images: imageItems,
                          onImageTap: _showImageViewer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openImageViewer(
  BuildContext context,
  List<_StoreImageItem> images,
  int initialIndex,
) {
  if (images.isEmpty) return;

  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.92),
    builder: (_) {
      final controller = PageController(initialPage: initialIndex);

      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: controller,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    panEnabled: false,
                    scaleEnabled: true,
                    child: images[index].buildImage(BoxFit.contain),
                  ),
                );
              },
            ),
            Positioned(
              top: 44,
              right: 18,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _TopBar extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFavoriteTap;
  final VoidCallback onClose;

  const _TopBar({
    required this.isFavorite,
    required this.onBack,
    required this.onFavoriteTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 24),
          ),
          const Spacer(),
          IconButton(
            onPressed: onFavoriteTap,
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              size: 34,
              color: isFavorite ? AppColors.secondary : AppColors.textMain,
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 34),
          ),
        ],
      ),
    );
  }
}

String _formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()}m';
  return '${km.toStringAsFixed(1)}km';
}

class _StoreSummary extends StatelessWidget {
  final Store store;
  final double rating;
  final VoidCallback onReviewTap;

  const _StoreSummary({
    required this.store,
    required this.rating,
    required this.onReviewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                store.name,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: FilledButton(
                onPressed: onReviewTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.badge,
                  foregroundColor: AppColors.textMain,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  '리뷰 작성',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: AppColors.primaryAccent,
              size: 23,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                store.mainBenefitDescription,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '현재 영업 중 · ${store.closeTimeLabel}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textSub,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '★${rating.toStringAsFixed(1)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.textSub,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          store.distanceLabel,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textSub,
          ),
        ),
      ],
    );
  }
}

class _PhotoCarousel extends StatelessWidget {
  final List<_StoreImageItem> images;
  final ValueChanged<int> onImageTap;

  const _PhotoCarousel({required this.images, required this.onImageTap});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onImageTap(index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 260,
                height: 190,
                child: images[index].buildImage(BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _DetailTabs({required this.selectedIndex, required this.onTap});

  static const tabs = ['홈', '메뉴', '군혜택', '리뷰', '사진'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = selectedIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              child: Container(
                height: 58,
                alignment: Alignment.center,
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
                      duration: const Duration(milliseconds: 150),
                      width: selected ? 28 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.textMain,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _HomeTabContent extends StatelessWidget {
  final Store store;

  const _HomeTabContent({required this.store});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        children: [
          _InfoLine(icon: Icons.push_pin, text: store.address),
          _InfoLine(
            icon: Icons.access_time,
            text: '운영 시간 ${store.businessHours}',
          ),
          _InfoLine(icon: Icons.phone, text: store.phoneLabel),
          _InfoLine(
            icon: Icons.local_offer_outlined,
            text: store.mainBenefitDescription,
          ),
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
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '대표 메뉴',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '${store.categoryLabel} 매장',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
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
    final benefits = store.benefits;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '군 장병 혜택',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 14),
          if (benefits.isEmpty)
            const Text(
              '등록된 혜택 정보가 없습니다.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textSub,
              ),
            )
          else
            ...benefits.map(
              (benefit) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefit.description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    if (benefit.conditionText != null &&
                        benefit.conditionText!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        benefit.conditionText!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewTabContent extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final List<StoreReview> serverReviews;
  final List<SubmittedStoreReview> submittedReviews;

  const _ReviewTabContent({
    required this.rating,
    required this.reviewCount,
    required this.serverReviews,
    required this.submittedReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewSummary(
            rating: rating,
            reviewCount: reviewCount,
            serverReviews: serverReviews,
            submittedReviews: submittedReviews,
          ),
          const SizedBox(height: 28),
          const Divider(color: AppColors.border),
          const SizedBox(height: 22),
          if (serverReviews.isEmpty && submittedReviews.isEmpty)
            const _EmptyReviewMessage()
          else ...[
            ...serverReviews.map(_ServerReviewCard.new),
            ...submittedReviews.map(_SubmittedReviewCard.new),
          ],
        ],
      ),
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  static const Color _rankedBackgroundColor = Color(0xFFE9DDC9);
  static const Color _rankedBorderColor = Color(0xFFD4B896);
  static const Color _rankedTextColor = Color(0xFF2D3B2D);
  static const Color _normalBackgroundColor = AppColors.surfaceSoft;
  static const Color _normalTextColor = AppColors.textMain;
  static const Color _normalCountColor = AppColors.primaryAccent;

  final double rating;
  final int reviewCount;
  final List<StoreReview> serverReviews;
  final List<SubmittedStoreReview> submittedReviews;

  const _ReviewSummary({
    required this.rating,
    required this.reviewCount,
    required this.serverReviews,
    required this.submittedReviews,
  });

  Map<String, int> get _goodPointCounts {
    final counts = <String, int>{};

    for (final review in serverReviews) {
      for (final label in review.goodPointLabels) {
        counts[label] = (counts[label] ?? 0) + 1;
      }
    }

    for (final review in submittedReviews) {
      for (final label in review.draft.goodPoints) {
        counts[label] = (counts[label] ?? 0) + 1;
      }
    }

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _goodPointCounts;

    final baseItems = [
      _ReviewSummaryItem(emoji: '🍗', label: '음식이 맛있어요', order: 0),
      _ReviewSummaryItem(emoji: '🍚', label: '양이 많아요', order: 1),
      _ReviewSummaryItem(emoji: '💰', label: '가성비가 좋아요', order: 2),
      _ReviewSummaryItem(emoji: '🍽️', label: '혼밥하기 좋아요', order: 3),
      _ReviewSummaryItem(emoji: '👥', label: '단체로 오기 좋아요', order: 4),
      _ReviewSummaryItem(emoji: '🤫', label: '조용하고 좋아요', order: 5),
      _ReviewSummaryItem(emoji: '🛋️', label: '식당 분위기가 좋아요', order: 6),
      _ReviewSummaryItem(emoji: '🏃', label: '웨이팅이 없어요', order: 7),
      _ReviewSummaryItem(emoji: '💳', label: '할인율이 높아요', order: 8),
    ];

    final sortedItems = [...baseItems]
      ..sort((a, b) {
        final aCount = counts[a.label] ?? 0;
        final bCount = counts[b.label] ?? 0;

        final countCompare = bCount.compareTo(aCount);
        if (countCompare != 0) return countCompare;

        return a.order.compareTo(b.order);
      });

    final rankedLabels = sortedItems
        .where((item) => (counts[item.label] ?? 0) > 0)
        .take(3)
        .map((item) => item.label)
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⭐ ${rating.toStringAsFixed(1)} · $reviewCount명의 군인들이 참여했어요',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textSub,
          ),
        ),
        const SizedBox(height: 18),
        ...sortedItems.map((item) {
          final count = counts[item.label] ?? 0;
          final ranked = rankedLabels.contains(item.label);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: ranked ? _rankedBackgroundColor : _normalBackgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: ranked
                  ? Border.all(color: _rankedBorderColor, width: 1.4)
                  : null,
            ),
            child: Row(
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: ranked ? FontWeight.w900 : FontWeight.w800,
                      color: ranked ? _rankedTextColor : _normalTextColor,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: ranked ? _rankedTextColor : _normalCountColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ReviewSummaryItem {
  final String emoji;
  final String label;
  final int order;

  const _ReviewSummaryItem({
    required this.emoji,
    required this.label,
    required this.order,
  });
}

class _EmptyReviewMessage extends StatelessWidget {
  const _EmptyReviewMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        '아직 등록된 리뷰가 없습니다.',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textSub,
        ),
      ),
    );
  }
}

class _ServerReviewCard extends StatelessWidget {
  final StoreReview review;

  const _ServerReviewCard(this.review);

  @override
  Widget build(BuildContext context) {
    final metaItems = [
      review.waitTimeLabel,
      review.visitPurposeLabel,
      review.visitWithLabel,
    ].where((item) => item.isNotEmpty).join(' · ');

    final reviewImages = review.imageUrls
        .where((url) => url.trim().isNotEmpty)
        .map(_StoreImageItem.network)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ProfileImage(url: review.profileImageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  review.nickname,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '★${review.rating.toStringAsFixed(1)}'
            '${review.createdDateLabel.isNotEmpty ? ' · ${review.createdDateLabel}' : ''}'
            '${metaItems.isNotEmpty ? ' · $metaItems' : ''}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textSub,
            ),
          ),
          if (review.benefitStatusLabel.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.benefitStatusLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryAccent,
              ),
            ),
          ],
          if (review.goodPointLabels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: review.goodPointLabels.map((point) {
                return _ReviewTag(label: point);
              }).toList(),
            ),
          ],
          if (review.content.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
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
          if (reviewImages.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ReviewImageStrip(images: reviewImages),
          ],
        ],
      ),
    );
  }
}

class _SubmittedReviewCard extends StatelessWidget {
  final SubmittedStoreReview review;

  const _SubmittedReviewCard(this.review);

  @override
  Widget build(BuildContext context) {
    final draft = review.draft;
    final reviewImages = review.imagePaths.map(_StoreImageItem.file).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review.nickname,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '★${draft.rating.toStringAsFixed(1)} · '
            '${draft.waitTimeAnswer} · '
            '${draft.purposeAnswer} · '
            '${draft.companionAnswer}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textSub,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            draft.benefitSentence,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryAccent,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: draft.goodPoints.map((point) {
              return _ReviewTag(label: point);
            }).toList(),
          ),
          if (review.content.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
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
          if (reviewImages.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ReviewImageStrip(images: reviewImages),
          ],
        ],
      ),
    );
  }
}

class _ReviewImageStrip extends StatelessWidget {
  final List<_StoreImageItem> images;

  const _ReviewImageStrip({required this.images});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openImageViewer(context, images, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 96,
                height: 96,
                child: images[index].buildImage(BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReviewTag extends StatelessWidget {
  final String label;

  const _ReviewTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
  }
}

class _ProfileImage extends StatelessWidget {
  final String? url;

  const _ProfileImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return const CircleAvatar(radius: 18, backgroundColor: Color(0xFFD9D9D9));
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFD9D9D9),
      backgroundImage: NetworkImage(imageUrl),
    );
  }
}

class _PhotoTabContent extends StatelessWidget {
  final List<_StoreImageItem> images;
  final ValueChanged<int> onImageTap;

  const _PhotoTabContent({required this.images, required this.onImageTap});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '등록된 사진이 없습니다.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textSub,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => onImageTap(index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: images[index].buildImage(BoxFit.cover),
          ),
        );
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 23, color: AppColors.textSub),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textSub,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreImageItem {
  final String value;
  final _StoreImageType type;

  const _StoreImageItem._(this.value, this.type);

  factory _StoreImageItem.asset(String value) {
    return _StoreImageItem._(value, _StoreImageType.asset);
  }

  factory _StoreImageItem.network(String value) {
    return _StoreImageItem._(value, _StoreImageType.network);
  }

  factory _StoreImageItem.file(String value) {
    return _StoreImageItem._(value, _StoreImageType.file);
  }

  Widget buildImage(BoxFit fit) {
    switch (type) {
      case _StoreImageType.asset:
        return Image.asset(
          value,
          fit: fit,
          errorBuilder: (_, __, ___) => _fallbackBox(),
        );
      case _StoreImageType.network:
        return Image.network(
          value,
          fit: fit,
          errorBuilder: (_, __, ___) => _fallbackBox(),
        );
      case _StoreImageType.file:
        return Image.file(
          File(value),
          fit: fit,
          errorBuilder: (_, __, ___) => _fallbackBox(),
        );
    }
  }

  Widget _fallbackBox() {
    return Container(
      color: AppColors.surfaceSoft,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textSub,
      ),
    );
  }
}

enum _StoreImageType { asset, network, file }
