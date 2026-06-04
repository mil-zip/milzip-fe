import 'package:flutter/material.dart';
import 'package:milzip/theme/app_colors.dart';

class SavedBenefitsScreen extends StatefulWidget {
  const SavedBenefitsScreen({super.key});

  @override
  State<SavedBenefitsScreen> createState() => _SavedBenefitsScreenState();
}

class _SavedBenefitsScreenState extends State<SavedBenefitsScreen> {
  int _selectedFilter = 0;

  static const _filters = ['전체', '영화관', '놀이공원', '자기계발'];

  static const List<Map<String, String>> _allBenefits = [
    {
      'id': '1',
      'title': 'CGV 군인 할인',
      'category': '영화관',
      'discount': '군인증 제시 시 영화 관람권 50% 할인',
      'image': 'assets/images/movie_project.png',
    },
    {
      'id': '2',
      'title': '메가박스 군인 할인',
      'category': '영화관',
      'discount': '군인증 제시 시 영화 관람권 50% 할인',
      'image': 'assets/images/movie_kingwithman.png',
    },
    {
      'id': '3',
      'title': '롯데시네마 군인 할인',
      'category': '영화관',
      'discount': '군인증 제시 시 영화 관람권 50% 할인',
      'image': 'assets/images/movie_devilwearprada.png',
    },
    {
      'id': '4',
      'title': '씨네큐 군인 할인',
      'category': '영화관',
      'discount': '군인증 제시 시 영화 관람권 40% 할인',
      'image': 'assets/images/movie_salmokji.png',
    },
    {
      'id': '5',
      'title': '에버랜드 군인 할인',
      'category': '놀이공원',
      'discount': '군인증 제시 시 30% 할인',
      'image': 'assets/images/park_everland.png',
    },
    {
      'id': '6',
      'title': '롯데월드 군인 혜택',
      'category': '놀이공원',
      'discount': '군인 무료입장',
      'image': 'assets/images/park_lotte.png',
    },
    {
      'id': '7',
      'title': '서울랜드 군인 할인',
      'category': '놀이공원',
      'discount': '군인증 40% 할인',
      'image': 'assets/images/park_seoul.png',
    },
  ];

  // 저장된 항목 id 집합 (초기: 전부 저장됨)
  final Set<String> _savedIds = {'1', '2', '3', '4', '5', '6', '7'};

  List<Map<String, String>> get _filtered {
    if (_selectedFilter == 0) return _allBenefits;
    final f = _filters[_selectedFilter];
    return _allBenefits.where((b) => b['category'] == f).toList();
  }

  void _toggleBookmark(String id) {
    setState(() {
      if (_savedIds.contains(id)) {
        _savedIds.remove(id);
      } else {
        _savedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final benefits = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.6,
        shadowColor: AppColors.border,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: AppColors.textMain,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '저장한 혜택',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 필터 칩 ───────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = index == _selectedFilter;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < _filters.length - 1 ? 8 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary2 : Colors.white,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary2
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          _filters[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textMain,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // ── 혜택 리스트 ───────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              itemCount: benefits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final b = benefits[index];
                final isSaved = _savedIds.contains(b['id']);
                return Container(
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
                            Expanded(
                              flex: 11,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(22, 18, 12, 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.badge,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        b['category']!,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.badgeText,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      b['title']!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textMain,
                                        letterSpacing: -0.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      b['discount']!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSub,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 10,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    b['image']!,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Color(0x66FFFFFF),
                                          Color(0x22FFFFFF),
                                          Color(0x00FFFFFF),
                                        ],
                                        stops: [0.0, 0.08, 0.24],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => _toggleBookmark(b['id']!),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(238),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(14),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: isSaved
                                  ? AppColors.primaryLight
                                  : const Color(0xFFCCCCCC),
                              size: 25,
                            ),
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
}
