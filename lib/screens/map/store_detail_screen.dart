import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/store.dart';
import '../../models/store_review.dart';
import '../../models/store_review_draft.dart';
import '../../services/store_api.dart';
import '../../services/store_review_api.dart';
import '../../theme/app_colors.dart';
import 'review/review_start_screen.dart';

part '_store_detail_image.dart';
part '_store_detail_tabs.dart';
part '_store_detail_review.dart';

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
