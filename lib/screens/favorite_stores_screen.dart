import 'package:flutter/material.dart';
import 'package:milzip/models/store.dart';
import 'package:milzip/screens/map/store_detail_screen.dart';
import 'package:milzip/services/user_service.dart';
import 'package:milzip/theme/app_colors.dart';

class FavoriteStoresScreen extends StatefulWidget {
  const FavoriteStoresScreen({super.key});

  @override
  State<FavoriteStoresScreen> createState() => _FavoriteStoresScreenState();
}

class _FavoriteStoresScreenState extends State<FavoriteStoresScreen> {
  List<Store> _stores = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await UserService.getFavorites();
      if (!mounted) return;
      setState(() {
        _stores = raw.map((e) => Store.fromJson(e)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeFavorite(Store store) async {
    // 낙관적 업데이트
    setState(() => _stores.removeWhere((s) => s.id == store.id));
    try {
      await UserService.removeFavorite(store.id);
    } catch (e) {
      // 실패 시 복원
      if (mounted) {
        setState(() => _stores.insert(0, store));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.6,
        shadowColor: AppColors.border,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '즐겨찾기한 매장',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryAccent),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.textSub, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _load,
              child: const Text('다시 시도',
                  style: TextStyle(
                      color: AppColors.primaryAccent, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    }

    if (_stores.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border_rounded, size: 56, color: AppColors.border),
            SizedBox(height: 16),
            Text(
              '즐겨찾기한 매장이 없습니다.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textSub,
              ),
            ),
            SizedBox(height: 6),
            Text(
              '매장 상세 페이지에서 즐겨찾기를 추가해보세요.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSub,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryAccent,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _stores.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final store = _stores[index];
          return _StoreFavoriteCard(
            store: store,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreDetailScreen(store: store),
                ),
              );
              // 상세에서 즐겨찾기 해제했을 수 있으므로 새로고침
              _load();
            },
            onRemove: () => _removeFavorite(store),
          );
        },
      ),
    );
  }
}

class _StoreFavoriteCard extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _StoreFavoriteCard({
    required this.store,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 썸네일
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 100,
                height: 100,
                child: store.imageUrls.isNotEmpty
                    ? Image.network(
                        store.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 14),
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.categoryLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSub,
                    ),
                  ),
                  if (store.benefits.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF2FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFFB3CFFF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield,
                              size: 12, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              store.benefits.first.description,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3B82F6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (store.distanceKm != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      store.distanceLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 즐겨찾기 해제 버튼
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.star_rounded,
                  color: Color(0xFFFFD600), size: 28),
              tooltip: '즐겨찾기 해제',
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceSoft,
      child: const Icon(Icons.storefront_rounded,
          size: 36, color: AppColors.border),
    );
  }
}
