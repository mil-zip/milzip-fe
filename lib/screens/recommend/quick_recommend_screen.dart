import 'dart:async';
import 'package:flutter/material.dart';
import 'package:milzip/models/place.dart';
import 'package:milzip/theme/app_colors.dart';
import 'package:milzip/widgets/place_card.dart';

class QuickRecommendScreen extends StatefulWidget {
  const QuickRecommendScreen({super.key});

  @override
  State<QuickRecommendScreen> createState() => _QuickRecommendScreenState();
}

class _QuickRecommendScreenState extends State<QuickRecommendScreen>
    with TickerProviderStateMixin {
  int _selectedCategory = 0;
  int _heroIconIndex = 0;
  Timer? _heroTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 히어로 애니메이션 아이콘 목록
  static const _heroIcons = [
    Icons.restaurant,
    Icons.local_cafe,
    Icons.local_activity,
    Icons.hotel,
    Icons.local_offer,
  ];

  static const _categoryIcons = [
    Icons.restaurant,
    Icons.local_cafe,
    Icons.local_activity,
    Icons.hotel,
    Icons.more_horiz,
  ];
  static const _categoryLabels = ['음식', '카페', '여가', '숙박', '기타'];

  static const _mockPlaces = [
    Place(
      id: '1',
      name: '꼬숩집 미아사거리점',
      categories: ['삼겹살', '오겹살'],
      militaryDiscount: '군장병 15% 할인',
      distanceKm: 1.2,
      isMilzipRecommended: true,
    ),
    Place(
      id: '2',
      name: '꼬숩집 미아사거리점',
      categories: ['삼겹살', '오겹살'],
      militaryDiscount: '군장병 15% 할인',
      distanceKm: 1.2,
      isMilzipRecommended: true,
    ),
    Place(
      id: '3',
      name: '꼬숩집 미아사거리점',
      categories: ['삼겹살', '오겹살'],
      militaryDiscount: '군장병 15% 할인',
      distanceKm: 1.2,
      isMilzipRecommended: true,
    ),
  ];

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
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildBestBanner(),
          ),
          const SizedBox(height: 24),
          _buildCategories(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSortRow(),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: _mockPlaces
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PlaceCard(place: p),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
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
          // ── 텍스트 (왼쪽 정렬, 레이아웃 높이 결정) ──────────────────────
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
                    color: Color(0xFF4A7E2E),
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
          // ── 애니메이션 아이콘 (우상단 고정 — 레이아웃 비영향) ─────────
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
                      // 외부 링 2
                      Container(
                        width: 140 + p * 30,
                        height: 140 + p * 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF4A7E2E).withAlpha(
                            (7 + p * 10).toInt(),
                          ),
                        ),
                      ),
                      // 외부 링 1
                      Container(
                        width: 112 + p * 16,
                        height: 112 + p * 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF4A7E2E).withAlpha(
                            (16 + p * 20).toInt(),
                          ),
                        ),
                      ),
                      // 메인 아이콘 (스핀 + 바운스)
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
                              colors: [Color(0xFF5E9642), Color(0xFF3A6B24)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4A7E2E).withAlpha(
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

  // ── BEST 배너 ─────────────────────────────────────────────────────────────
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
            colors: [Color(0xFF344B37), Color(0xFF4A6B3E)],
          ),
        ),
        child: Stack(
          children: [
            // 배경 — 배지 이미지 희미하게
            Positioned(
              right: -12,
              top: -8,
              bottom: -8,
              child: Opacity(
                opacity: 0.13,
                child: Image.asset(
                  'assets/images/milzip_badge.png',
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
            // 텍스트 콘텐츠
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
        children: List.generate(_categoryIcons.length, _buildCategoryItem),
      ),
    );
  }

  Widget _buildCategoryItem(int index) {
    final isSelected = index == _selectedCategory;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = index),
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
                    ? AppColors.secondaryBg
                    : const Color(0xFFF7F7F7),
                border: Border.all(
                  color: isSelected ? AppColors.secondary : AppColors.border,
                  width: isSelected ? 2.0 : 1.2,
                ),
              ),
              child: Icon(
                _categoryIcons[index],
                size: 26,
                color: isSelected
                    ? AppColors.secondaryDark
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
                    ? AppColors.secondaryDark
                    : const Color(0xFFAAAAAA),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '지금 가장 많이 조회된 TOP 3',
          style: TextStyle(color: AppColors.textSub, fontSize: 12),
        ),
        GestureDetector(
          onTap: () {},
          child: const Row(
            children: [
              Text(
                '밀집 추천 순',
                style: TextStyle(color: AppColors.textSub, fontSize: 12),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.textSub,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
