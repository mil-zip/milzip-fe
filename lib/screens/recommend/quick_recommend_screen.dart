import 'dart:async';
import 'package:flutter/material.dart';
import 'package:milzip/models/quick_store.dart';
import 'package:milzip/models/store.dart';
import 'package:milzip/screens/map/store_detail_screen.dart';
import 'package:milzip/services/location_service.dart';
import 'package:milzip/services/quick_recommend_api.dart';
import 'package:milzip/theme/app_colors.dart';

class QuickRecommendScreen extends StatefulWidget {
  const QuickRecommendScreen({super.key});

  @override
  State<QuickRecommendScreen> createState() => _QuickRecommendScreenState();
}

class _QuickRecommendScreenState extends State<QuickRecommendScreen>
    with TickerProviderStateMixin {
  int _selectedCategory = 0;
  String _sortBy = 'recommend';
  int _heroIconIndex = 0;
  Timer? _heroTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTop = false;

  List<QuickStore> _stores = [];
  int _page = 0;
  bool _hasNext = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  static const _heroIcons = [
    Icons.restaurant,
    Icons.local_cafe,
    Icons.local_activity,
    Icons.hotel,
    Icons.local_offer,
  ];

  static const List<String?> _categoryValues = [
    'FOOD',
    'CAFE',
    'LEISURE',
    'ACCOMMODATION',
    'ETC',
  ];
  static const _categoryIcons = [
    Icons.restaurant,
    Icons.local_cafe,
    Icons.local_activity,
    Icons.hotel,
    Icons.more_horiz,
  ];
  static const _categoryLabels = ['음식', '카페', '여가', '숙박', '기타'];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    _heroTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      setState(() {
        _heroIconIndex = (_heroIconIndex + 1) % _heroIcons.length;
      });
    });
    _scrollController.addListener(_onScroll);
    _loadData(reset: true);
  }

  void _onScroll() {
    final px = _scrollController.position.pixels;

    // 상단 이동 버튼 표시 기준 (300px 이상 스크롤)
    final shouldShow = px > 300;
    if (shouldShow != _showScrollTop) {
      setState(() => _showScrollTop = shouldShow);
    }

    // 무한 스크롤
    if (px >= _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasNext) {
      _loadMore();
    }
  }

  Future<void> _loadData({bool reset = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
      if (reset) {
        _stores = [];
        _page = 0;
      }
    });
    try {
      final pos = LocationService.instance.position;
      final result = await QuickRecommendApi.fetch(
        lat: pos?.latitude,
        lng: pos?.longitude,
        category: _categoryValues[_selectedCategory],
        sortBy: _sortBy,
        page: 0,
        size: 20,
      );
      if (!mounted) return;
      setState(() {
        _stores = result.content;
        _page = 0;
        _hasNext = result.hasNext;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _parseError(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasNext) return;
    setState(() => _isLoadingMore = true);
    try {
      final pos = LocationService.instance.position;
      final result = await QuickRecommendApi.fetch(
        lat: pos?.latitude,
        lng: pos?.longitude,
        category: _categoryValues[_selectedCategory],
        sortBy: _sortBy,
        page: _page + 1,
        size: 20,
      );
      if (!mounted) return;
      setState(() {
        _stores.addAll(result.content);
        _page++;
        _hasNext = result.hasNext;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            // SliverToBoxAdapter(
            //   child: Padding(
            //     padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            //     child: _buildBestBanner(),
            //   ),
            // ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: _buildCategories(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_buildSortRow()],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: CircularProgressIndicator(
                      color: AppColors.primary2,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildError(),
              )
            else if (_stores.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmpty(),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildStoreCard(_stores[index]),
                    ),
                    childCount: _stores.length,
                  ),
                ),
              ),
              if (_isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary2,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ),
              if (!_hasNext && _stores.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        '총 ${_stores.length}개의 매장을 모두 불러왔어요',
                        style: const TextStyle(
                          color: AppColors.textSub,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      // ── 상단으로 이동 FAB ──────────────────────────────────────────────────
      AnimatedPositioned(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        bottom: _showScrollTop ? 24 : -72,
        right: 20,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _showScrollTop ? 1.0 : 0.0,
          child: GestureDetector(
            onTap: () {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary2,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary2.withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  // ── 히어로 ────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.white),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 130, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '밀집추천',
                  style: TextStyle(
                    fontFamily: 'TmoneyRoundWind',
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary2,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '근처 군장병 혜택을 빠르게 찾아드려요!',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSub,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -28,
            right: -28,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) {
                final p = _pulseAnimation.value;
                return SizedBox(
                  width: 176,
                  height: 176,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140 + p * 30,
                        height: 140 + p * 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary2.withAlpha(
                            (7 + p * 10).toInt(),
                          ),
                        ),
                      ),
                      Container(
                        width: 112 + p * 16,
                        height: 112 + p * 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary2.withAlpha(
                            (16 + p * 20).toInt(),
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 550),
                        transitionBuilder: (child, anim) {
                          return RotationTransition(
                            turns: Tween<double>(
                              begin: 0.18,
                              end: 0.0,
                            ).animate(
                              CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOutBack,
                              ),
                            ),
                            child: ScaleTransition(
                              scale: CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOutBack,
                              ),
                              child: FadeTransition(
                                opacity: anim,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          key: ValueKey(_heroIconIndex),
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryLight,
                                AppColors.primary2,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary2.withAlpha(
                                  (55 + p * 50).toInt(),
                                ),
                                blurRadius: 20 + p * 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            _heroIcons[_heroIconIndex],
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── BEST 배너 (현재 미사용) ───────────────────────────────────────────────
  // ignore: unused_element
  Widget _buildBestBanner() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 114,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary1, AppColors.hover],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              top: -8,
              bottom: -8,
              child: Opacity(
                opacity: 0.13,
                child: Image.asset(
                  'assets/images/milzip_logo.png',
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 120, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'BEST',
                      style: TextStyle(
                        color: Color(0xFF3A2800),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    '군장병 할인 15%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '군장병 인기 혜택 매장을 지금 확인해보세요',
                    style: TextStyle(
                      color: Colors.white.withAlpha(160),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white30,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 카테고리 탭 ───────────────────────────────────────────────────────────
  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_categoryLabels.length, _buildCategoryItem),
      ),
    );
  }

  Widget _buildCategoryItem(int index) {
    final isSelected = index == _selectedCategory;

    return GestureDetector(
      onTap: () {
        if (_selectedCategory != index) {
          setState(() => _selectedCategory = index);
          _loadData(reset: true);
        }
      },
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.surfaceSoft
                    : const Color(0xFFF7F7F7),
                border: Border.all(
                  color: isSelected ? AppColors.primary2 : AppColors.border,
                  width: isSelected ? 2.0 : 1.2,
                ),
              ),
              child: Icon(
                _categoryIcons[index],
                size: 26,
                color: isSelected
                    ? AppColors.primary2
                    : const Color(0xFFBBBBBB),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _categoryLabels[index],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? AppColors.primary2
                    : const Color(0xFFAAAAAA),
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 정렬 필터 ─────────────────────────────────────────────────────────────
  static const _sortOptions = [
    ('recommend', '추천순'),
    ('discount', '할인율순'),
    ('distance', '거리순'),
  ];

  String get _currentSortLabel =>
      _sortOptions.firstWhere((o) => o.$1 == _sortBy).$2;

  final _sortButtonKey = GlobalKey();

  Widget _buildSortRow() {
    return GestureDetector(
      key: _sortButtonKey,
      onTap: _showSortDropdown,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentSortLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textSub,
            ),
          ],
        ),
      ),
    );
  }

  void _showSortDropdown() {
    final box =
        _sortButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screenWidth = MediaQuery.of(context).size.width;

    showMenu<String>(
      context: context,
      color: AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // 버튼 오른쪽 끝 기준 우측 정렬, 너비는 내용 크기에 맡김
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        screenWidth - (offset.dx + size.width),
        0,
      ),
      items: _sortOptions.map((opt) {
        final (value, label) = opt;
        final isSelected = _sortBy == value;
        return PopupMenuItem<String>(
          value: value,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primary2
                      : AppColors.textMain,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_rounded,
                    color: AppColors.primary2, size: 16),
              ],
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null && value != _sortBy) {
        setState(() => _sortBy = value);
        _loadData(reset: true);
      }
    });
  }

  // ── 매장 카드 ─────────────────────────────────────────────────────────────
  Widget _buildStoreCard(QuickStore store) {
    final firstImage =
        store.imageUrls.isNotEmpty ? store.imageUrls.first : null;
    final icon = _iconForCategory(store.category);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                StoreDetailScreen(store: _toStore(store)),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Container(
                width: 100,
                height: 100,
                color: AppColors.surfaceSoft,
                child: firstImage != null
                    ? Image.network(
                        firstImage,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => Icon(
                          icon,
                          size: 36,
                          color: AppColors.border,
                        ),
                      )
                    : Icon(icon, size: 36, color: AppColors.border),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    store.address,
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (store.maxDiscountRate > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.discountBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.discountBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shield,
                            size: 13,
                            color: AppColors.discountBorder,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _discountLabel(store.maxDiscountRate),
                            style: const TextStyle(
                              color: AppColors.discountText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (store.distanceKm != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 13,
                          color: AppColors.textSub,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _distanceLabel(store.distanceKm!),
                          style: const TextStyle(
                            color: AppColors.textSub,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'FOOD':
        return Icons.restaurant;
      case 'CAFE':
        return Icons.local_cafe;
      case 'LEISURE':
        return Icons.local_activity;
      case 'ACCOMMODATION':
        return Icons.hotel;
      default:
        return Icons.local_offer;
    }
  }

  // 100 초과면 금액(1,000원 할인), 이하면 퍼센트(10% 할인)
  String _discountLabel(int rate) {
    if (rate > 100) {
      final formatted = rate.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '$formatted원 할인';
    }
    return '$rate% 할인';
  }

  // 소수점 1자리, 1km 미만이면 m 단위
  String _distanceLabel(double km) {
    if (km < 1) {
      final m = (km * 1000).round();
      return '${m}m';
    }
    return '${km.toStringAsFixed(1)}km';
  }

  Store _toStore(QuickStore qs) {
    return Store(
      id: qs.id,
      name: qs.name,
      category: _mapStoreCategory(qs.category),
      categoryDetail: _categoryLabelFor(qs.category),
      address: qs.address,
      latitude: qs.latitude,
      longitude: qs.longitude,
      phone: qs.phone ?? '',
      openTime: qs.openTime,
      closeTime: qs.closeTime,
      menu: '',
      benefitDescription: _discountLabel(qs.maxDiscountRate),
      discountRate: qs.maxDiscountRate > 0 ? qs.maxDiscountRate : null,
      isMilitaryBenefit: qs.militaryBenefit,
      isBenefitVerified: qs.benefitVerified,
      imageUrls: qs.imageUrls,
      distanceKm: qs.distanceKm,
    );
  }

  StoreCategory _mapStoreCategory(String category) {
    switch (category) {
      case 'FOOD':
        return StoreCategory.food;
      case 'ACCOMMODATION':
        return StoreCategory.lodging;
      default:
        return StoreCategory.service;
    }
  }

  String _categoryLabelFor(String category) {
    switch (category) {
      case 'FOOD':
        return '음식';
      case 'CAFE':
        return '카페';
      case 'LEISURE':
        return '여가';
      case 'ACCOMMODATION':
        return '숙박';
      default:
        return '기타';
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('네트워크')) {
      return '네트워크 연결을 확인해 주세요';
    }
    if (msg.contains('TimeoutException') || msg.contains('시간 초과')) {
      return '요청 시간이 초과됐어요. 다시 시도해 주세요';
    }
    if (msg.contains("type 'Null'") || msg.contains('Null check')) {
      return '데이터를 불러오는 중 문제가 발생했어요';
    }
    return msg.replaceFirst('Exception: ', '');
  }

  // ── 빈 상태 / 에러 ────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_mall_directory_outlined,
                size: 48, color: AppColors.border),
            SizedBox(height: 12),
            Text(
              '근처 매장이 없어요',
              style: TextStyle(color: AppColors.textSub, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.border),
            const SizedBox(height: 12),
            Text(
              _error ?? '오류가 발생했어요',
              style:
                  const TextStyle(color: AppColors.textSub, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _loadData(reset: true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary2,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '다시 시도',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
