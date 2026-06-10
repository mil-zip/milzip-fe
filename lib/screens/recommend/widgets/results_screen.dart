import 'package:flutter/material.dart';
import 'package:milzip/models/ai_recommend_result.dart';
import 'package:milzip/models/store.dart';
import 'package:milzip/screens/map/store_detail_screen.dart';
import 'package:milzip/theme/app_colors.dart';

// 코스별 구분 색상
const List<Color> _kCourseColors = [
  Color(0xFF455F3B), // Course 1 — olive green
  Color(0xFF2D5F7A), // Course 2 — slate blue
  Color(0xFF7A5520), // Course 3 — amber brown
];

Color _courseColor(int courseNumber) =>
    _kCourseColors[(courseNumber - 1).clamp(0, _kCourseColors.length - 1)];

class ResultsScreen extends StatelessWidget {
  final AiRecommendResult result;
  final VoidCallback onReset;

  const ResultsScreen({super.key, required this.result, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.missingCategories.isNotEmpty) _buildMissingBanner(),
          if (result.courses.isEmpty)
            _buildEmptyState()
          else
            ...result.courses.map(
              (course) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _CourseCard(course: course),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMissingBanner() {
    final labels = result.missingCategories.map(_categoryLabel).join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD580)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: Color(0xFFD4973A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$labels 카테고리에 해당하는 매장을 찾지 못했어요',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7A5520),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: AppColors.border),
            SizedBox(height: 12),
            Text(
              '추천 결과를 찾지 못했어요\n다른 조건으로 다시 시도해 보세요',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSub, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String value) {
    switch (value) {
      case 'FOOD':
        return '식사';
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
}

class _CourseCard extends StatelessWidget {
  final AiCourse course;

  const _CourseCard({required this.course});

  Color get _color => _courseColor(course.courseNumber);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withAlpha(50), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _color.withAlpha(25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: _buildStoreList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: _color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Course number badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withAlpha(60)),
            ),
            child: Text(
              'COURSE ${course.courseNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (course.region != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                course.region!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withAlpha(220),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStoreList(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < course.stores.length; i++)
          _buildStoreRow(context, course.stores[i], i, course.stores.length),
      ],
    );
  }

  Widget _buildStoreRow(
    BuildContext context,
    AiCourseStore store,
    int index,
    int total,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타임라인 컬럼
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _color,
                    boxShadow: [
                      BoxShadow(
                        color: _color.withAlpha(60),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (index < total - 1)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        color: _color.withAlpha(40),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: index < total - 1 ? 16 : 0),
              child: _StoreCard(store: store, accentColor: _color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final AiCourseStore store;
  final Color accentColor;

  const _StoreCard({required this.store, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoreDetailScreen(store: _toStore()),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageStrip(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CategoryChip(category: store.category, color: accentColor),
                      const SizedBox(width: 6),
                      if (store.maxDiscountRate != null)
                        _DiscountChip(rate: store.maxDiscountRate!),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    store.address,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSub,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (store.reason != null && store.reason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: accentColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              store.reason!,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: AppColors.textMain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (store.distanceKm != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _DistanceInfo(distanceKm: store.distanceKm!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageStrip() {
    if (store.imageUrls.isEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        child: Container(
          height: 120,
          color: AppColors.surfaceSoft,
          child: const Center(
            child: Icon(Icons.store_mall_directory_outlined,
                size: 40, color: AppColors.border),
          ),
        ),
      );
    }

    if (store.imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        child: Image.network(
          store.imageUrls.first,
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 120,
            color: AppColors.surfaceSoft,
            child: const Center(
              child: Icon(Icons.broken_image_outlined,
                  size: 36, color: AppColors.border),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: SizedBox(
        height: 120,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Image.network(
                store.imageUrls[0],
                fit: BoxFit.cover,
                height: 120,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppColors.surfaceSoft),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  for (int i = 1; i < store.imageUrls.length && i < 3; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: i > 1 ? 2 : 0),
                        child: Image.network(
                          store.imageUrls[i],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AppColors.surfaceSoft),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Store _toStore() {
    return Store(
      id: store.id,
      name: store.name,
      category: _parseCategory(store.category),
      address: store.address,
      latitude: store.latitude,
      longitude: store.longitude,
      phone: store.phone,
      openTime: store.openTime,
      closeTime: store.closeTime,
      maxDiscountRate: store.maxDiscountRate,
      imageUrls: store.imageUrls,
      distanceKm: store.distanceKm,
    );
  }

  StoreCategory _parseCategory(String value) {
    switch (value) {
      case 'FOOD':
        return StoreCategory.food;
      case 'CAFE':
        return StoreCategory.cafe;
      case 'LEISURE':
        return StoreCategory.leisure;
      case 'ACCOMMODATION':
        return StoreCategory.accommodation;
      default:
        return StoreCategory.etc;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  final Color color;

  const _CategoryChip({required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        _label(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  String _label() {
    switch (category) {
      case 'FOOD':
        return '식사';
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
}

class _DiscountChip extends StatelessWidget {
  final int rate;

  const _DiscountChip({required this.rate});

  @override
  Widget build(BuildContext context) {
    final label = rate > 100
        ? '${_formatNumber(rate)}원 할인'
        : '$rate% 할인';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.discountBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.discountBorder.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield, size: 11, color: AppColors.discountBorder),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.discountText,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

class _DistanceInfo extends StatelessWidget {
  final double distanceKm;

  const _DistanceInfo({required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final label = distanceKm < 1
        ? '${(distanceKm * 1000).round()}m'
        : '${distanceKm.toStringAsFixed(1)}km';

    return Row(
      children: [
        const Icon(Icons.location_on_outlined,
            size: 13, color: AppColors.textSub),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSub),
        ),
      ],
    );
  }
}
