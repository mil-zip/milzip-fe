import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/store.dart';
import '../../models/store_review.dart';
import '../../models/store_review_draft.dart';
import '../../services/auth_service.dart';
import '../../services/store_api.dart';
import '../../services/store_review_api.dart';
import '../../services/user_service.dart';
import '../../utils/auth_expired_exception.dart';
import '../login_screen.dart';
import '../../theme/app_colors.dart';
import '../review/review_detail_screen.dart';
import '../review/review_start_screen.dart';

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
  bool _favoriteLoading = false;
  bool _loadingStore = false;
  bool _loadingReviews = false;
  int _selectedTabIndex = 0;

  List<StoreReview> _serverReviews = [];
  final List<SubmittedStoreReview> _submittedReviews = [];
  Map<String, int> _goodPointCounts = {};
  int? _currentUserId;

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
    _loadFavoriteStatus();
    _loadCurrentUserId();
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
      final result = await StoreReviewApi.getList(
        storeId: widget.store.id,
        page: 0,
        size: 10,
      );

      if (!mounted) return;

      setState(() {
        _serverReviews = result.page.content;
        _goodPointCounts = result.goodPointCounts;
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

  Future<void> _loadCurrentUserId() async {
    try {
      final data = await UserService.getMyInfo();
      if (!mounted) return;
      setState(() => _currentUserId = data['id'] as int?);
    } catch (_) {}
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final favorites = await UserService.getFavorites();
      if (!mounted) return;
      setState(() {
        _isFavorite = favorites.any((f) => f['id'] == _store.id);
      });
    } catch (_) {
      // 비로그인 상태 등 오류 시 무시
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteLoading) return;
    setState(() => _favoriteLoading = true);

    final willFavorite = !_isFavorite;
    try {
      if (willFavorite) {
        await UserService.addFavorite(_store.id);
      } else {
        await UserService.removeFavorite(_store.id);
      }
      if (!mounted) return;
      setState(() => _isFavorite = willFavorite);
      _showSnackBar(willFavorite ? '즐겨찾기에 저장되었습니다.' : '즐겨찾기가 해제되었습니다.');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('즐겨찾기 처리에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _favoriteLoading = false);
    }
  }

  Future<void> _openReviewWriteScreen() async {
    final result = await Navigator.push<SubmittedStoreReview>(
      context,
      MaterialPageRoute(builder: (_) => ReviewStartScreen(store: _store)),
    );

    if (result == null || !mounted) return;

    try {
      // 리뷰 작성 전 토큰 선제 갱신 — 설문 작성 시간 동안 만료될 수 있음
      try {
        await AuthService.refreshTokens();
      } catch (_) {
        // 갱신 실패는 create() 안에서 처리
      }
      await StoreReviewApi.create(storeId: _store.id, submitted: result);
      if (!mounted) return;
      // 서버에서 최신 목록 다시 로드
      await _loadReviews();
      if (!mounted) return;
      setState(() => _selectedTabIndex = 2);
      _showSnackBar('리뷰가 등록되었습니다.');
    } catch (e) {
      if (!mounted) return;
      if (e is AuthExpiredException) {
        await _showSessionExpiredAndLogin();
        return;
      }
      // 서버 오류 시 로컬에만 표시
      setState(() {
        _submittedReviews.insert(0, result);
        _selectedTabIndex = 2;
      });
      _showSnackBar('리뷰 등록 중 오류가 발생했습니다.');
    }
  }

  void _showImageViewer(int initialIndex) {
    _openImageViewer(context, _imageItems, initialIndex);
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
    PendingNavigation.returnStore = _store;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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
                        _BenefitTabContent(store: _store),
                        _ReviewTabContent(
                          rating: _averageRating,
                          reviewCount: _reviewCount,
                          serverReviews: _serverReviews,
                          submittedReviews: _submittedReviews,
                          goodPointCounts: _goodPointCounts,
                          currentUserId: _currentUserId,
                          onReviewUpdated: (updated) => setState(() {
                            final idx = _serverReviews
                                .indexWhere((r) => r.id == updated.id);
                            if (idx >= 0) _serverReviews[idx] = updated;
                          }),
                          onReviewDeleted: (id) => setState(() {
                            _serverReviews.removeWhere((r) => r.id == id);
                          }),
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
              color: isFavorite ? const Color(0xFFFFD600) : AppColors.textMain,
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
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: '⭐ '),
              TextSpan(
                text: rating.toStringAsFixed(1),
                style: const TextStyle(color: Color(0xFFFF3B30)),
              ),
            ],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textMain,
            ),
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

  static const tabs = ['홈', '군혜택', '리뷰', '사진'];

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
