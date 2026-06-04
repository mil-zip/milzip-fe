import 'package:flutter/material.dart';
import 'package:milzip/screens/favorite_stores_screen.dart';
import 'package:milzip/screens/saved_benefits_screen.dart';
import 'package:milzip/theme/app_colors.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  static const _favoriteStores = [
    {'name': '우즈마키 문정본점', 'category': '음식'},
    {'name': '굿모닝쌀국수', 'category': '음식'},
    {'name': '버텍스 미국식 덮밥 하월곡점', 'category': '음식'},
    {'name': '로이파스타', 'category': '카페'},
  ];

  static IconData _categoryToIcon(String category) {
    switch (category) {
      case '음식':
        return Icons.restaurant_rounded;
      case '카페':
        return Icons.local_cafe_rounded;
      case '여가':
      case '영화':
      case '놀이공원':
        return Icons.local_activity_rounded;
      case '숙박':
        return Icons.hotel_rounded;
      default:
        return Icons.store_rounded;
    }
  }

  static const List<Map<String, dynamic>> _reviews = [
    {
      'store': '꼬숩집 미아사거리점',
      'location': '서울 성북구 미아동',
      'category': '음식',
      'rating': 5,
      'image': null,
    },
    {
      'store': '굿모닝쌀국수',
      'location': '서울 송파구 문정동',
      'category': '음식',
      'rating': 4,
      'image': null,
    },
    {
      'store': '버텍스 미국식 덮밥 하월곡점',
      'location': '서울 성북구 하월곡동',
      'category': '음식',
      'rating': 4,
      'image': null,
    },
    {
      'store': '마띠에르',
      'location': '서울 종로구',
      'category': '숙박',
      'rating': 3,
      'image': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF3F4F7),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfile(),
            const SizedBox(height: 6),
            _buildFavoriteStores(),
            const SizedBox(height: 6),
            _buildSavedBenefits(),
            const SizedBox(height: 6),
            _buildReviews(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── 프로필 ─────────────────────────────────────────────────────────────────
  Widget _buildProfile() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: ShapeDecoration(
                  color: const Color(0xFFD0D3D8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 38,
                  color: Colors.white,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 13,
                    color: AppColors.textSub,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '뉴채린',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.edit_rounded,
                size: 14,
                color: AppColors.textSub,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 즐겨찾기한 매장 ────────────────────────────────────────────────────────
  Widget _buildFavoriteStores() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const FavoriteStoresScreen(),
        ),
      ),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 18, 0, 18),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '즐겨찾기한 매장',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textSub,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 152,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _favoriteStores.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final store = _favoriteStores[index];
                final icon = _categoryToIcon(store['category'] ?? '');
                return SizedBox(
                  width: 101,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 101,
                        height: 101,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0D3D8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        store['name']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMain,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }

  // ── 저장한 혜택 (컴팩트 링크 카드) ─────────────────────────────────────────
  Widget _buildSavedBenefits() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SavedBenefitsScreen()),
      ),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '저장한 혜택',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textSub,
            ),
          ],
        ),
      ),
    );
  }

  // ── 리뷰 목록 ──────────────────────────────────────────────────────────────
  Widget _buildReviews() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          const Text(
            '내 리뷰',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '최신순',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSub,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // 2열 그리드
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _reviews.map((review) {
              final icon = _categoryToIcon(
                review['category'] as String? ?? '',
              );
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 40 - 7) / 2,
                height: 214,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0D3D8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // 썸네일 (이미지 or 카테고리 아이콘)
                      Positioned.fill(
                        child: review['image'] != null
                            ? Image.asset(
                                review['image'] as String,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Icon(
                                  icon,
                                  size: 40,
                                  color: Colors.white.withAlpha(180),
                                ),
                              ),
                      ),
                      // 텍스트 오버레이 (하단)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(140),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review['location'] as String,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                              Text(
                                review['store'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
