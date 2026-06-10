import 'package:flutter/material.dart';
import 'package:milzip/models/tmo.dart';
import 'package:milzip/screens/home.dart' show homeTabNotifier, benefitCategoryNotifier;
import 'package:milzip/screens/map/tmo_detail_screen.dart';
import 'package:milzip/services/user_service.dart';
import 'package:milzip/theme/app_colors.dart';

class SavedBenefitsScreen extends StatefulWidget {
  const SavedBenefitsScreen({super.key});

  @override
  State<SavedBenefitsScreen> createState() => _SavedBenefitsScreenState();
}

class _SavedBenefitsScreenState extends State<SavedBenefitsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _benefits = [];
  List<Map<String, dynamic>> _tmos = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        UserService.getBenefitFavorites().catchError((_) => <Map<String, dynamic>>[]),
        UserService.getTmoFavorites().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _benefits = results[0];
        _tmos = results[1];
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // benefitTypeDescription → BenefitCollectionScreen 카테고리 인덱스
  int _categoryIndex(String? d) {
    if (d == null) return 1;
    if (d.contains('영화')) return 0;
    if (d.contains('놀이')) return 1;
    return 2;
  }

  // 카테고리별 색상 — 각 혜택 화면의 메인 컬러
  Color _categoryColor(String? d) {
    if (d == null) return const Color(0xFF6B9358);
    if (d.contains('영화')) return const Color(0xFFFF6B35);   // movie accent
    if (d.contains('놀이')) return const Color(0xFF6B9358);   // primaryAccent
    return const Color(0xFFD4973A);                           // secondaryDark (청년정책)
  }

  IconData _categoryIcon(String? d) {
    if (d == null) return Icons.menu_book_rounded;
    if (d.contains('영화')) return Icons.local_movies_rounded;
    if (d.contains('놀이')) return Icons.attractions_rounded;
    return Icons.menu_book_rounded;
  }

  Future<void> _removeBenefit(Map<String, dynamic> b) async {
    final id = (b['benefitId'] as num?)?.toInt() ?? 0;
    try {
      await UserService.removeBenefitFavorite(id);
      setState(() => _benefits.removeWhere(
          (item) => (item['benefitId'] as num?)?.toInt() == id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _removeTmo(Map<String, dynamic> t) async {
    final id = (t['tmoId'] as num?)?.toInt() ?? 0;
    try {
      await UserService.removeTmoFavorite(id);
      setState(() => _tmos.removeWhere(
          (item) => (item['tmoId'] as num?)?.toInt() == id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _benefits.isEmpty && _tmos.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.6,
        shadowColor: AppColors.border,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '저장한 혜택',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isEmpty
              ? Center(
                  child: Text(
                    '저장한 혜택이 없습니다.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primaryAccent,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    children: [
                      // 혜택 카드들
                      ..._benefits.map((b) => _BenefitCard(
                            data: b,
                            categoryColor: _categoryColor(b['benefitTypeDescription'] as String?),
                            categoryIcon: _categoryIcon(b['benefitTypeDescription'] as String?),
                            onTap: () {
                              final idx = _categoryIndex(b['benefitTypeDescription'] as String?);
                              benefitCategoryNotifier.value = idx;
                              homeTabNotifier.value = (tab: 3, subIndex: idx);
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
                            onRemove: () => _removeBenefit(b),
                          )),

                      // TMO 카드들
                      ..._tmos.map((t) => _TmoCard(
                            data: t,
                            onTap: () {
                              final tmo = Tmo(
                                id: (t['tmoId'] as num?)?.toInt() ?? 0,
                                name: t['name'] as String? ?? '',
                                address: t['address'] as String? ?? '',
                                latitude: 0,
                                longitude: 0,
                                distanceKm: 0,
                                locationDescription: t['address'] as String? ?? '',
                                mobile: t['isMobile'] as bool? ?? false,
                                phone: t['phone'] as String?,
                                weekdayStartTime: t['weekdayStartTime'] as String?,
                                weekdayEndTime: t['weekdayEndTime'] as String?,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TmoDetailScreen(tmo: tmo),
                                ),
                              );
                            },
                            onRemove: () => _removeTmo(t),
                          )),
                    ],
                  ),
                ),
    );
  }
}

// ── 혜택 카드 ────────────────────────────────────────────────────────────────
class _BenefitCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color categoryColor;
  final IconData categoryIcon;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _BenefitCard({
    required this.data,
    required this.categoryColor,
    required this.categoryIcon,
    required this.onTap,
    required this.onRemove,
  });

  String _displayLabel(String raw) {
    if (raw.contains('영화')) return raw;
    if (raw.contains('놀이')) return raw;
    if (raw.isNotEmpty) return '청년정책 혜택';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final rawCategory = data['benefitTypeDescription'] as String? ?? '';
    final category = _displayLabel(rawCategory);
    final title = data['title'] as String? ?? '';
    final discount = data['discountDescription'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 136,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  children: [
                    // 텍스트 영역
                    Expanded(
                      flex: 11,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: categoryColor.withAlpha(22),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: categoryColor,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMain,
                                letterSpacing: -0.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (discount.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                discount,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSub,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // 이미지 or 아이콘 배경
                    Expanded(
                      flex: 10,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _iconBackground(categoryColor, categoryIcon)),
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Color(0x66FFFFFF),
                                        Color(0x00FFFFFF),
                                      ],
                                      stops: [0.0, 0.3],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _iconBackground(categoryColor, categoryIcon),
                    ),
                  ],
                ),
              ),
              // 북마크 해제 버튼
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(220),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(14),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bookmark_rounded,
                      color: AppColors.primaryLight,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBackground(Color color, IconData icon) {
    return Container(
      color: color.withAlpha(25),
      child: Center(
        child: Icon(icon, size: 48, color: color.withAlpha(100)),
      ),
    );
  }
}

// ── TMO 카드 ─────────────────────────────────────────────────────────────────
class _TmoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  static const _color = Color(0xFF1B7F9E); // teal — 놀이공원 그린과 구분

  const _TmoCard({
    required this.data,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? '';
    final address = data['address'] as String? ?? '';
    final phone = data['phone'] as String?;
    final start = data['weekdayStartTime'] as String?;
    final end = data['weekdayEndTime'] as String?;
    final hours = (start != null && end != null) ? '$start ~ $end' : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 136,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  children: [
                    // 텍스트 영역
                    Expanded(
                      flex: 11,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: _color.withAlpha(22),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Text(
                                'TMO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _color,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMain,
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              address,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSub),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (hours != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '평일 $hours${phone != null ? '  ·  $phone' : ''}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textSub),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // 아이콘 배경 (혜택 카드와 동일한 비율)
                    Expanded(
                      flex: 10,
                      child: Container(
                        color: _color.withAlpha(20),
                        child: const Center(
                          child: Icon(
                            Icons.account_balance_rounded,
                            size: 52,
                            color: Color(0xFF1B7F9E),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 북마크 해제 버튼
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(220),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(14),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bookmark_rounded,
                      color: AppColors.primaryLight,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
