import 'package:flutter/material.dart';
import 'package:milzip/models/quick_store.dart';
import 'package:milzip/services/location_service.dart';
import 'package:milzip/services/quick_recommend_api.dart';
import 'package:milzip/theme/app_colors.dart';
import 'widgets/quick_category_bar.dart';
import 'widgets/quick_hero_section.dart';
import 'widgets/quick_sort_button.dart';
import 'widgets/quick_store_card.dart';

class QuickRecommendScreen extends StatefulWidget {
  const QuickRecommendScreen({super.key});

  @override
  State<QuickRecommendScreen> createState() => _QuickRecommendScreenState();
}

class _QuickRecommendScreenState extends State<QuickRecommendScreen> {
  int _selectedCategory = 0;
  String _sortBy = 'recommend';
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTop = false;

  List<QuickStore> _stores = [];
  int _page = 0;
  bool _hasNext = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _requestGeneration = 0; // 요청마다 증가 — 이전 응답 무시용

  // API에 넘길 카테고리 값 (QuickCategoryBar의 index와 1:1 대응)
  static const _categoryValues = [
    'FOOD', 'CAFE', 'LEISURE', 'ACCOMMODATION', 'ETC',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    LocationService.instance.locationNotifier.addListener(_onLocationChanged);
    _loadData(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    LocationService.instance.locationNotifier.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() {
    _scrollController.jumpTo(0);
    _loadData(reset: true);
  }

  void _onScroll() {
    final px = _scrollController.position.pixels;
    final shouldShow = px > 300;
    if (shouldShow != _showScrollTop) {
      setState(() => _showScrollTop = shouldShow);
    }
    if (px >= _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasNext) {
      _loadMore();
    }
  }

  Future<void> _loadData({bool reset = false}) async {
    final generation = ++_requestGeneration;
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
        lat: pos.latitude,
        lng: pos.longitude,
        category: _categoryValues[_selectedCategory],
        sortBy: _sortBy,
        page: 0,
        size: 20,
      );
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _stores = result.content;
        _page = 0;
        _hasNext = result.hasNext;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || generation != _requestGeneration) return;
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
        lat: pos.latitude,
        lng: pos.longitude,
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            const SliverToBoxAdapter(child: QuickHeroSection()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: QuickCategoryBar(
                  selectedIndex: _selectedCategory,
                  onSelect: (i) {
                    setState(() => _selectedCategory = i);
                    _loadData(reset: true);
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    QuickSortButton(
                      sortBy: _sortBy,
                      onChanged: (v) {
                        setState(() => _sortBy = v);
                        _loadData(reset: true);
                      },
                    ),
                  ],
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
                      color: AppColors.primaryAccent,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(hasScrollBody: false, child: _buildError())
            else if (_stores.isEmpty)
              const SliverFillRemaining(hasScrollBody: false, child: _EmptyView())
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: QuickStoreCard(store: _stores[index]),
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
                        color: AppColors.primaryAccent,
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
                        style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
        // 맨 위로 버튼
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          bottom: _showScrollTop ? 24 : -72,
          right: 20,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showScrollTop ? 1.0 : 0.0,
            child: GestureDetector(
              onTap: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
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
      ],
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
              style: const TextStyle(color: AppColors.textSub, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _loadData(reset: true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_mall_directory_outlined, size: 48, color: AppColors.border),
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
}
