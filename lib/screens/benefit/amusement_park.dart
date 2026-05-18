import 'package:flutter/material.dart';

// ─── 데이터 모델 ───────────────────────────────────────────────────────────────

class BenefitCategory {
  final String label;
  final IconData icon;
  const BenefitCategory({required this.label, required this.icon});
}

class BenefitCard {
  final String name;
  final String region;
  final String location;
  final String discountRate;
  final Color cardColor;
  final List<String> tags;
  bool isBookmarked;

  BenefitCard({
    required this.name,
    required this.region,
    required this.location,
    required this.discountRate,
    required this.cardColor,
    required this.tags,
    this.isBookmarked = false,
  });
}

// ─── 샘플 데이터 ───────────────────────────────────────────────────────────────

final List<BenefitCategory> categories = [
  BenefitCategory(label: '영화', icon: Icons.movie_outlined),
  BenefitCategory(label: '놀이공원', icon: Icons.attractions_outlined),
  BenefitCategory(label: '자기계발', icon: Icons.menu_book_outlined),
];

final List<BenefitCard> amusementParkCards = [
  BenefitCard(
    name: '에버랜드',
    region: '수도권',
    location: '경기 용인 / 연중무휴',
    discountRate: '100%',
    cardColor: const Color(0xFFD0312D),
    tags: ['자유이용권', '현장구매'],
  ),
  BenefitCard(
    name: '롯데월드',
    region: '수도권',
    location: '서울 잠실 / 연중무휴',
    discountRate: '30,000원 할인',
    cardColor: const Color(0xFF1A3A8F),
    tags: ['자유이용권', '현장구매'],
  ),
  BenefitCard(
    name: '서울랜드',
    region: '경기도권',
    location: '경기도 과천 / 연중무휴',
    discountRate: '70%',
    cardColor: const Color(0xFF2E7D32),
    tags: ['자유이용권', '현장구매'],
  ),
];

// ─── 메인 화면 ─────────────────────────────────────────────────────────────────

class BenefitCollectionScreen extends StatefulWidget {
  const BenefitCollectionScreen({super.key});

  @override
  State<BenefitCollectionScreen> createState() =>
      _BenefitCollectionScreenState();
}

class _BenefitCollectionScreenState extends State<BenefitCollectionScreen> {
  int _selectedCategoryIndex = 1; // 놀이공원 기본 선택

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 상단 헤더
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

              // ── 카테고리 탭
              _CategoryTabs(
                categories: categories,
                selectedIndex: _selectedCategoryIndex,
                onTap: (index) =>
                    setState(() => _selectedCategoryIndex = index),
              ),

              const SizedBox(height: 16),

              // ── 가로 스와이프 카드
              _BenefitCardSlider(cards: amusementParkCards),

              const SizedBox(height: 28),

              // ── 할인 이용 조건
              const _DiscountConditionSection(),

              const SizedBox(height: 20),

              // ── 유의사항
              const _NoticeSection(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 카테고리 탭 ───────────────────────────────────────────────────────────────

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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1A3A8F)
                        : const Color(0xFFD0D0D0),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 28,
                      color: isSelected
                          ? const Color(0xFF1A3A8F)
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
                            ? const Color(0xFF1A3A8F)
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

// ─── 가로 스와이프 카드 슬라이더 ────────────────────────────────────────────────

class _BenefitCardSlider extends StatefulWidget {
  final List<BenefitCard> cards;
  const _BenefitCardSlider({required this.cards});

  @override
  State<_BenefitCardSlider> createState() => _BenefitCardSliderState();
}

class _BenefitCardSliderState extends State<_BenefitCardSlider> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.cards.length,
        itemBuilder: (context, index) {
          final card = widget.cards[index];
          // return _BenefitCardItem(
          //   card: card,
          //   onBookmarkToggle: () {
          //     setState(() => card.isBookmarked = !card.isBookmarked);

          //     // 북마크 토글 시 스낵바 알림
          //     ScaffoldMessenger.of(context).clearSnackBars();
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       SnackBar(
          //         content: Text(
          //           card.isBookmarked
          //               ? '${card.name}이(가) 저장되었습니다 🔖'
          //               : '${card.name} 저장이 취소되었습니다',
          //         ),
          //         duration: const Duration(seconds: 1),
          //         behavior: SnackBarBehavior.floating,
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(10),
          //         ),
          //         margin: const EdgeInsets.symmetric(
          //           horizontal: 20,
          //           vertical: 10,
          //         ),
          //       ),
          //     );
          //   },
          // );
        },
      ),
    );
  }
}

// ─── 개별 혜택 카드 ────────────────────────────────────────────────────────────

class _BenefitCardItem extends StatelessWidget {
  final BenefitCard card;
  final VoidCallback onBookmarkToggle;

  const _BenefitCardItem({required this.card, required this.onBookmarkToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 컬러 카드 영역
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: card.cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 지역 뱃지 + 할인율
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          card.region,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        card.discountRate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // 브랜드명 + 북마크
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        card.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // ── 북마크 버튼
                      GestureDetector(
                        onTap: onBookmarkToggle,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            card.isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            key: ValueKey(card.isBookmarked),
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── 위치/시간 정보
          Text(
            card.location,
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),

          const SizedBox(height: 6),

          // ── 태그들
          Wrap(
            spacing: 6,
            children: card.tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── 할인 이용 조건 섹션 ────────────────────────────────────────────────────────

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
                final c = conditions[index];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          // 번호 원
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.subtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ],
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

// ─── 유의사항 섹션 ─────────────────────────────────────────────────────────────

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
