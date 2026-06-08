import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/self_development.dart';
import '../../services/self_development_api.dart';

class SelfDevelopmentSection extends StatefulWidget {
  const SelfDevelopmentSection({super.key});

  @override
  State<SelfDevelopmentSection> createState() => _SelfDevelopmentSectionState();
}

class _SelfDevelopmentSectionState extends State<SelfDevelopmentSection> {
  List<SelfDevelopment> _items = [];
  int _currentPage = 0;
  int _totalPages = 1;
  bool _isLoading = false;
  String? _error;

  // 선택된 카테고리 (null = 전체)
  String? _selectedCategory;

  // 알려진 카테고리 목록 (필터 칩)
  static const _filterCategories = [
    '복지',
    '일자리',
    '주거',
    '교육',
    '참여·권리',
  ];

  // 펼침 상태 (id별)
  final Set<int> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _loadPage(0);
  }

  Future<void> _loadPage(int page) async {
    if (_isLoading) return;
    // ignore: avoid_print
    print('[self-dev] load start page=$page category=${_selectedCategory ?? 'ALL'}');

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 복지 카테고리는 금융 + 문화 모두 조회
      late SelfDevelopmentPage result;

      if (_selectedCategory == '복지') {
        final financeResult = await SelfDevelopmentApi.getList(
          page: page,
          size: 5,
          category: '금융',
        );
        final cultureResult = await SelfDevelopmentApi.getList(
          page: page,
          size: 5,
          category: '문화',
        );

        // 두 결과 합치기
        final allContent = [
          ...financeResult.content,
          ...cultureResult.content,
        ];

        result = SelfDevelopmentPage(
          content: allContent,
          hasNext: financeResult.hasNext || cultureResult.hasNext,
          pageNum: page,
          totalElements: financeResult.totalElements + cultureResult.totalElements,
          totalPages: (financeResult.totalPages + cultureResult.totalPages + 1) ~/ 2,
        );
      } else {
        result = await SelfDevelopmentApi.getList(
          page: page,
          size: 5,
          category: _selectedCategory,
        );
      }

      final all =
          result.content.map((j) => SelfDevelopment.fromApi(j)).toList();
      // ignore: avoid_print
      print('[self-dev] load success count=${all.length} totalPages=${result.totalPages}');
      if (!mounted) return;

      setState(() {
        _items = all;
        _currentPage = page;
        _totalPages = result.totalPages;
        _expandedIds.clear();
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('[self-dev] load error $e');
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectCategory(String? category) {
    if (_selectedCategory == category) return;
    // ignore: avoid_print
    print('[self-dev] select category=${category ?? 'ALL'}');

    setState(() {
      _selectedCategory = category;
    });
    _loadPage(0);
  }

  void _toggleExpand(int id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_items.isEmpty && _error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text('불러오기 실패: $_error',
              style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '복무 중 성장할 수 있는 다양한 프로그램을 지원합니다.',
            style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
          ),
        ),
        const SizedBox(height: 14),

        // ── 카테고리 필터 칩 ──────────────────────────────────────────
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _FilterChip(
                label: '전체',
                isSelected: _selectedCategory == null,
                onTap: () => _selectCategory(null),
              ),
              const SizedBox(width: 6),
              for (final c in _filterCategories) ...[
                _FilterChip(
                  label: c,
                  isSelected: _selectedCategory == c,
                  onTap: () => _selectCategory(c),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 빈 상태
        if (_items.isEmpty && !_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Center(
              child: Text(
                '해당 카테고리의 혜택이 없어요',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
              ),
            ),
          ),

        // 로딩 (필터 전환 시)
        if (_isLoading && _items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),

        ..._items.map((item) {
          final isExpanded = _expandedIds.contains(item.id);
          return _ProgramCard(
            item: item,
            isExpanded: isExpanded,
            onToggle: () => _toggleExpand(item.id),
            onApply: () => _openUrl(item.applyUrl),
            onBookmarkTap: () {
              setState(() => item.isBookmarked = !item.isBookmarked);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    item.isBookmarked
                        ? '${item.title}이(가) 저장되었습니다!'
                        : '${item.title} 저장이 취소되었습니다.',
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
          );
        }),

        // 페이지네이션
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: _Pagination(
            currentPage: _currentPage,
            totalPages: _totalPages,
            isLoading: _isLoading,
            onPageChanged: _loadPage,
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }
}

// ── 카드 위젯 (펼침/접힘 토글) ────────────────────────────────────────────────
class _ProgramCard extends StatelessWidget {
  final SelfDevelopment item;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onApply;
  final VoidCallback onBookmarkTap;

  const _ProgramCard({
    required this.item,
    required this.isExpanded,
    required this.onToggle,
    required this.onApply,
    required this.onBookmarkTap,
  });

  // 카테고리별 (텍스트색, 배경색) 매핑
  static const Map<String, (Color, Color)> _categoryColors = {
    '복지': (Color(0xFF6B9358), Color(0xFFEEF5E8)),      // 초록
    '일자리': (Color(0xFFFF6B35), Color(0xFFFFEFE8)),    // 주황
    '주거': (Color(0xFF455F3B), Color(0xFFEEF2EA)),     // 올리브
    '교육': (Color(0xFF1F5ACB), Color(0xFFDDE8FF)),     // 파랑
    '참여·권리': (Color(0xFFD4973A), Color(0xFFFFF8E7)), // 앰버
    '교통': (Color(0xFF1B7F9E), Color(0xFFE0F2F8)),    // 청록
  };

  // 기본 팔레트 (위 매핑에 없으면 카테고리 이름 해시로 선택)
  static const List<(Color, Color)> _fallbackPalette = [
    (Color(0xFF8E44AD), Color(0xFFF1E0F8)),
    (Color(0xFFE67E22), Color(0xFFFCEEDD)),
    (Color(0xFF16A085), Color(0xFFD9F0EA)),
    (Color(0xFF3D5AFE), Color(0xFFE0E5FF)),
    (Color(0xFFC0392B), Color(0xFFFAE0DD)),
  ];

  (Color, Color) get _colorPair {
    final mapped = _categoryColors[item.category];
    if (mapped != null) return mapped;
    final idx = item.category.hashCode.abs() % _fallbackPalette.length;
    return _fallbackPalette[idx];
  }

  Color get _categoryColor => _colorPair.$1;
  Color get _categoryBg => _colorPair.$2;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 (카테고리 + 북마크) ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _categoryBg,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _categoryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onBookmarkTap,
                    child: Icon(
                      item.isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      size: 22,
                      color: item.isBookmarked
                          ? const Color(0xFF6B9358)
                          : const Color(0xFFCCCCCC),
                    ),
                  ),
                ],
              ),
            ),

            // ── 본문 ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    maxLines: isExpanded ? null : 2,
                    overflow:
                        isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                      height: 1.5,
                    ),
                  ),

                  // 펼쳤을 때 지원내용
                  if (isExpanded) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '지원 내용',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.supportType,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF555555),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.applyUrl.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onApply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF455F3B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            '신청 페이지 바로가기',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            // ── 펼침 토글 버튼 ────────────────────────────────────────
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isExpanded ? '접기' : '자세히 보기',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: const Color(0xFF888888),
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

// ── 페이지네이션 (<<  <  1 2 3 ...  >  >>) ──────────────────────────────────
class _Pagination extends StatelessWidget {
  final int currentPage; // 0-based
  final int totalPages;
  final bool isLoading;
  final ValueChanged<int> onPageChanged;

  const _Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    required this.onPageChanged,
  });

  // 그룹 단위 페이지 윈도우 (1~5, 6~10, 11~15 ...)
  // 네이버/구글 등 대부분의 게시판 표준 방식
  List<int> _visiblePages() {
    const groupSize = 5;
    final groupIndex = currentPage ~/ groupSize;
    final start = groupIndex * groupSize;
    final end = (start + groupSize).clamp(0, totalPages);
    return List.generate(end - start, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final pages = _visiblePages();
    final canPrev = currentPage > 0 && !isLoading;
    final canNext = currentPage < totalPages - 1 && !isLoading;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavButton(
          icon: Icons.keyboard_double_arrow_left_rounded,
          enabled: canPrev,
          onTap: () => onPageChanged(0),
        ),
        _NavButton(
          icon: Icons.chevron_left_rounded,
          enabled: canPrev,
          onTap: () => onPageChanged(currentPage - 1),
        ),
        const SizedBox(width: 4),
        ...pages.map(
          (i) => _PageNumber(
            page: i + 1, // 표시는 1-based
            isActive: i == currentPage,
            isLoading: isLoading,
            onTap: () => onPageChanged(i),
          ),
        ),
        const SizedBox(width: 4),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          enabled: canNext,
          onTap: () => onPageChanged(currentPage + 1),
        ),
        _NavButton(
          icon: Icons.keyboard_double_arrow_right_rounded,
          enabled: canNext,
          onTap: () => onPageChanged(totalPages - 1),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF333333) : const Color(0xFFCCCCCC),
        ),
      ),
    );
  }
}

class _PageNumber extends StatelessWidget {
  final int page;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  const _PageNumber({
    required this.page,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading || isActive ? null : onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF455F3B) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}

// ── 필터 칩 ─────────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF455F3B) : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF455F3B)
                : const Color(0xFFE0E0E0),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }
}
