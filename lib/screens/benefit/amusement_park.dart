import 'package:flutter/material.dart';
import '../../models/theme_park.dart';
import '../../data/theme_park_dummy.dart';
import '../../services/amusement_park_api.dart';
import 'movie.dart';
import 'self_development.dart';

class BenefitCategory {
  final String label;
  final IconData icon;

  const BenefitCategory({required this.label, required this.icon});
}

final List<BenefitCategory> categories = [
  BenefitCategory(label: '영화', icon: Icons.local_movies),
  BenefitCategory(label: '놀이공원', icon: Icons.attractions_outlined),
  BenefitCategory(label: '청년정책', icon: Icons.menu_book_outlined),
];

class BenefitCollectionScreen extends StatefulWidget {
  const BenefitCollectionScreen({super.key});

  @override
  State<BenefitCollectionScreen> createState() =>
      _BenefitCollectionScreenState();
}

class _BenefitCollectionScreenState extends State<BenefitCollectionScreen> {
  int _selectedCategoryIndex = 1;
  List<ThemePark> _themeParks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // ignore: avoid_print
    print('[benefit] init selected=$_selectedCategoryIndex');
    _loadAmusementParks();
  }

  /// React의 useEffect + fetch와 동일한 역할
  Future<void> _loadAmusementParks() async {
    // ignore: avoid_print
    print('[benefit-amusement] load start');
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await AmusementParkApi.getList();
      // ignore: avoid_print
      print('[benefit-amusement] load success count=${data.length}');
      if (!mounted) return;
      setState(() {
        _themeParks = data.map((json) => ThemePark.fromApi(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('[benefit-amusement] load error $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // 실패 시 더미 데이터 폴백
        _themeParks = getDummyThemeParks();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Text(
                  '군인 전용 혜택 Zone',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              _CategoryTabs(
                categories: categories,
                selectedIndex: _selectedCategoryIndex,
                onTap: (index) {
                  // ignore: avoid_print
                  print('[benefit] tab change index=$index');
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (_selectedCategoryIndex == 0) ...[
                const MovieSection(),
              ] else if (_selectedCategoryIndex == 1) ...[
              if (_isLoading)
                const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('불러오기 실패: $_error',
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      const Text('더미 데이터로 표시합니다.',
                          style: TextStyle(color: Color(0xFF888888))),
                    ],
                  ),
                ),
                _ThemeParkCarousel(
                  themeParks: _themeParks,
                  onBookmarkToggle: (id) {
                    setState(() {
                      final park = _themeParks.firstWhere((p) => p.id == id);
                      park.isBookmarked = !park.isBookmarked;
                    });
                  },
                ),
                const SizedBox(height: 28),
                const _DiscountConditionSection(),
                const SizedBox(height: 20),
                const _NoticeSection(),
                const SizedBox(height: 24),
              ] else ...[
                const SelfDevelopmentSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  final List<BenefitCategory> categories;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _CategoryTabs({
    required this.categories,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(categories.length, (index) {
          final cat = categories[index];
          final isSelected = index == selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                // ⬇️ 변경: 위쪽 padding을 더 줘서 아이콘에 여유 공간 확보
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF293C2C)
                        : const Color(0xFFD0D0D0),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ⬇️ 변경: Transform.translate 제거하고 그냥 Icon으로
                    Icon(
                      cat.icon,
                      size: 28,
                      color: isSelected
                          ? const Color(0xFF293C2C)
                          : const Color(0xFFAAAAAA),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? const Color(0xFF293C2C)
                            : const Color(0xFFAAAAAA),
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

class _ThemeParkCarousel extends StatefulWidget {
  final List<ThemePark> themeParks;
  final ValueChanged<int> onBookmarkToggle;

  const _ThemeParkCarousel({
    required this.themeParks,
    required this.onBookmarkToggle,
  });

  @override
  State<_ThemeParkCarousel> createState() => _ThemeParkCarouselState();
}

class _ThemeParkCarouselState extends State<_ThemeParkCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.93);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 390,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.themeParks.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final park = widget.themeParks[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _ThemeParkCard(
                    park: park,
                    onBookmarkToggle: () {
                      widget.onBookmarkToggle(park.id);

                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            park.isBookmarked
                                ? '${park.name}이(가) 저장되었습니다!'
                                : '${park.name} 저장이 취소되었습니다.',
                          ),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.themeParks.length, (index) {
            final isActive = index == _currentPage;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF293C2C)
                    : const Color(0xFFD0D0D0),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ThemeParkCard extends StatelessWidget {
  final ThemePark park;
  final VoidCallback onBookmarkToggle;

  const _ThemeParkCard({required this.park, required this.onBookmarkToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 340,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 이미지 영역 ────────────────────────────────────────────────
          SizedBox(
            height: 165,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: park.cardColor,
                image: park.displayImage != null
                    ? DecorationImage(
                        image: AssetImage(park.displayImage!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.32),
                          BlendMode.darken,
                        ),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          park.region,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          park.discountLabel,
                          style: TextStyle(
                            color: park.cardColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          park.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onBookmarkToggle,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              park.isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              key: ValueKey(park.isBookmarked),
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 15,
                      color: Color(0xFF888888),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${park.shortAddress} · ${park.validUntilLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  park.benefit,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      park.discountType == DiscountType.free
                          ? '무료'
                          : '${park.formatPrice(park.discountedPrice)}원',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${park.formatPrice(park.originalPrice)}원',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFAAAAAA),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    park.benefit,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        park.discountType == DiscountType.free
                            ? '무료'
                            : '${park.formatPrice(park.discountedPrice)}원',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${park.formatPrice(park.originalPrice)}원',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFAAAAAA),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.assignment_outlined,
                          size: 14,
                          color: Color(0xFF555555),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            park.requiredDocument,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountConditionSection extends StatelessWidget {
  const _DiscountConditionSection();

  @override
  Widget build(BuildContext context) {
    final conditions = [
      (title: '군인증 / 신분증 지참', subtitle: '현역 군인 본인 확인 필수'),
      (title: '현장 구매에 한해 적용', subtitle: '온라인 사전 예매 미적용'),
      (title: '본인 1매 한정', subtitle: '동반할인 별도 안내'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '할인 이용 조건',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E5E5)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: List.generate(conditions.length, (index) {
                final condition = conditions[index];

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A1A1A),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  condition.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  condition.subtitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < conditions.length - 1)
                      const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFEEEEEE),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeSection extends StatelessWidget {
  const _NoticeSection();

  @override
  Widget build(BuildContext context) {
    final notices = [
      '파크별 운영 시간 및 휴장일이 다르므로 방문 전 확인 필수',
      '할인율은 놀이 공원 정책에 따라 변경될 수 있습니다.',
      '일부 파크는 성수기, 공휴일 할인이 제한될 수 있으니 확인 부탁드립니다.',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '유의사항',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 10),
            ...notices.map(
              (notice) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                    ),
                    Expanded(
                      child: Text(
                        notice,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                          height: 1.5,
                        ),
                      ),
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
