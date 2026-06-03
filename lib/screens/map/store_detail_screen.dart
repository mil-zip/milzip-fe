import 'package:flutter/material.dart';

import '../../models/store.dart';
import 'review/review_start_screen.dart';

class StoreDetailScreen extends StatefulWidget {
  final Store store;

  const StoreDetailScreen({super.key, required this.store});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  int _selectedTabIndex = 0;
  int _selectedReviewTypeIndex = 0;

  final List<String> _tabs = ['홈', '메뉴', '군혜택', '리뷰', '사진'];

  Store get store => widget.store;

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _HomeTabContent(store: store);
      case 1:
        return _MenuTabContent(store: store);
      case 2:
        return _BenefitTabContent(store: store);
      case 3:
        return _ReviewTabContent(
          selectedReviewTypeIndex: _selectedReviewTypeIndex,
          onReviewTypeChanged: (index) {
            setState(() {
              _selectedReviewTypeIndex = index;
            });
          },
          onWriteReview: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReviewStartScreen(store: store),
              ),
            );
          },
        );
      case 4:
        return const _SimpleTabMessage(title: '사진 준비 중');
      default:
        return _HomeTabContent(store: store);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageAssets = List.generate(
      5,
      (index) => 'assets/images/store_yukhoe_${index + 1}.png',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 26),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.star_border, size: 34),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 34),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9FFF4),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: const Color(0xFF00C878)),
                    ),
                    child: const Text(
                      '밀집추천',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00A86B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 20,
                    color: Color(0xFF00C878),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      store.benefitDescription,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00C878),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Text(
                '현재 영업 중 · ${store.closeTime}에 영업 종료',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF555555),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 34),
              child: Text(
                '1.2km',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF555555),
                ),
              ),
            ),
            const SizedBox(height: 34),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 34),
                itemCount: imageAssets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _StoreDetailPhoto(
                    imageAsset: imageAssets[index],
                    highlighted: index == 0,
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            _DetailTabs(
              tabs: _tabs,
              selectedIndex: _selectedTabIndex,
              onTap: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 28, 34, 40),
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTabContent extends StatelessWidget {
  final int selectedReviewTypeIndex;
  final ValueChanged<int> onReviewTypeChanged;
  final VoidCallback onWriteReview;

  const _ReviewTabContent({
    required this.selectedReviewTypeIndex,
    required this.onReviewTypeChanged,
    required this.onWriteReview,
  });

  @override
  Widget build(BuildContext context) {
    final keywords = [
      ('🍗', '음식이 맛있어요', '670'),
      ('🛋️', '식당 분위기가 좋아요', '453'),
      ('🏃', '웨이팅이 없어요', '239'),
      ('💳', '할인율이 높아요', '140'),
      ('👨‍👩‍👧‍👦', '회식하기 좋아요', '111'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: onWriteReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C878),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '리뷰 작성',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _ReviewTypeSegmentedControl(
          selectedIndex: selectedReviewTypeIndex,
          onChanged: onReviewTypeChanged,
        ),
        const SizedBox(height: 24),
        const Text(
          '⭐ 4.8 · 1,562명의 군인들이 참여했어요',
          style: TextStyle(
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 22),
        ...keywords.map(
          (keyword) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ReviewKeywordRow(
              emoji: keyword.$1,
              label: keyword.$2,
              count: keyword.$3,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 24),
        const _ReviewCard(),
      ],
    );
  }
}

class _ReviewTypeSegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ReviewTypeSegmentedControl({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['🫡 군장병 리뷰', '일반 리뷰'];

    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(16),
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
                      ? const Color(0xFF5BDE7A)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  labels[index],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111111),
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
  final String label;
  final String count;

  const _ReviewKeywordRow({
    required this.emoji,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111111),
              ),
            ),
          ),
          Text(
            count,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF48B96A),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              '뽀야미',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111111),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          '🛡️ 점심에 방문  예약 없이 이용  대기시간 바로 입장 ★4.9',
          style: TextStyle(
            fontSize: 16,
            height: 1.45,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '분위기 나쁘지 않고 맛있게 먹었습니다. 근데 한 가지 아쉬운 점은 물이 미지근하다는 점입니다. 물은 셀프고요',
          style: TextStyle(
            fontSize: 16,
            height: 1.45,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
      ],
    );
  }
}

class _StoreDetailPhoto extends StatelessWidget {
  final String imageAsset;
  final bool highlighted;

  const _StoreDetailPhoto({required this.imageAsset, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      height: 210,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: highlighted
            ? Border.all(color: const Color(0xFF168DFF), width: 3)
            : null,
      ),
      child: Image.asset(imageAsset, fit: BoxFit.cover),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _DetailTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34),
      child: SizedBox(
        height: 58,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(tabs.length, (index) {
            final selected = selectedIndex == index;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(index),
              child: SizedBox(
                height: 58,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tabs[index],
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? const Color(0xFF111111)
                            : const Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 28,
                      height: 3,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF111111)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _HomeTabContent extends StatelessWidget {
  final Store store;

  const _HomeTabContent({required this.store});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DetailInfoRow(icon: Icons.push_pin, text: store.address),
        const SizedBox(height: 22),
        _DetailInfoRow(
          icon: Icons.access_time,
          text:
              '현재 영업 중 · ${store.closeTime}에 영업 종료\n운영 시간 ${store.businessHours}',
        ),
        const SizedBox(height: 22),
        _DetailInfoRow(icon: Icons.call, text: store.phone),
      ],
    );
  }
}

class _MenuTabContent extends StatelessWidget {
  final Store store;

  const _MenuTabContent({required this.store});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DetailInfoRow(
          icon: Icons.restaurant_menu,
          text: '대표 메뉴 ${store.menu}',
        ),
      ],
    );
  }
}

class _BenefitTabContent extends StatelessWidget {
  final Store store;

  const _BenefitTabContent({required this.store});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DetailInfoRow(
          icon: Icons.verified_user_outlined,
          text: store.benefitDescription,
        ),
      ],
    );
  }
}

class _SimpleTabMessage extends StatelessWidget {
  final String title;

  const _SimpleTabMessage({required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF888888),
          ),
        ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 25, color: const Color(0xFF666666)),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 17,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
          ),
        ),
      ],
    );
  }
}
