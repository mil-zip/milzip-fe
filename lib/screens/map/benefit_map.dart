import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../models/store.dart';
import '../../models/tmo.dart';
import '../../services/store_api.dart';
import '../../services/tmo_api.dart';
import '../../theme/app_colors.dart';
import 'store_detail_screen.dart';
import 'tmo_detail_screen.dart';

const List<double> _kRadiusOptions = [1, 3, 5, 10, 20, 50];

class BenefitMapScreen extends StatefulWidget {
  const BenefitMapScreen({super.key});

  @override
  State<BenefitMapScreen> createState() => _BenefitMapScreenState();
}

class _BenefitMapScreenState extends State<BenefitMapScreen> {
  KakaoMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  final LatLng _fallbackCenter = LatLng(37.95745120515425, 127.3174892339337);

  final List<String> _categories = ['TMO', '음식', '숙박', 'PC방', '서비스'];

  String? _selectedCategory = 'TMO';

  final List<Store> _stores = [];
  int _storePage = 0;
  bool _storeHasNext = false;
  bool _loadingStores = false;
  bool _loadingMoreStores = false;
  String _activeKeyword = '';
  double? _radius = 10.0;

  List<Tmo> _tmos = [];
  bool _loadingTmos = false;

  Store? _selectedStore;
  Tmo? _selectedTmo;

  LatLng? _currentLatLng;
  bool _permissionDialogShown = false;

  bool get _isTmoMode => _selectedCategory == 'TMO';
  bool get _isStoreMode => !_isTmoMode;

  List<Marker> get _markers {
    if (_isTmoMode) {
      return _tmos.map((tmo) {
        final selected = _selectedTmo?.id == tmo.id;

        return Marker(
          markerId: 'tmo_${tmo.id}',
          latLng: LatLng(tmo.latitude, tmo.longitude),
          width: selected ? 44 : 34,
          height: selected ? 52 : 42,
        );
      }).toList();
    }

    return _stores.map((store) {
      final selected = _selectedStore?.id == store.id;

      return Marker(
        markerId: 'store_${store.id}',
        latLng: LatLng(store.latitude, store.longitude),
        width: selected ? 44 : 34,
        height: selected ? 52 : 42,
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_selectedCategory == 'TMO') {
        _loadTmoList();
      } else {
        _resetAndLoadStores();
      }
      _showLocationPermissionDialogIfNeeded();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  String? _storeCategoryApiValue(String? categoryLabel) {
    switch (categoryLabel) {
      case '음식':
        return 'FOOD';
      case '숙박':
        return 'ACCOMMODATION';
      case 'PC방':
        return 'PC_CAFE';
      case '서비스':
        return 'SERVICE';
      default:
        return null;
    }
  }

  Future<void> _showLocationPermissionDialogIfNeeded() async {
    if (_permissionDialogShown) return;

    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await _moveToCurrentLocation();
      return;
    }

    _permissionDialogShown = true;

    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 42, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '밀집(MILZIP)에서 내 기기 위치에\n액세스하도록 허용하시겠습니까?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 34),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PermissionIllustration(
                      icon: Icons.location_on,
                      label: '정확한 위치',
                      color: AppColors.primaryAccent,
                    ),
                    SizedBox(width: 26),
                    _PermissionIllustration(
                      icon: Icons.map_outlined,
                      label: '대략적인 위치',
                      color: AppColors.secondaryDark,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _PermissionButton(
                  label: '앱 사용 중에만 허용',
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await _requestLocationPermission();
                  },
                ),
                _PermissionButton(
                  label: '이번만 허용',
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await _requestLocationPermission();
                  },
                ),
                _PermissionButton(
                  label: '허용 안 함',
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _moveToFallbackLocation();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showSnackBar('기기 위치 서비스가 꺼져 있습니다.');
      _moveToFallbackLocation();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showSnackBar('위치 권한이 허용되지 않았습니다.');
      _moveToFallbackLocation();
      return;
    }

    await _moveToCurrentLocation();
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
      final latLng = LatLng(position.latitude, position.longitude);
      _currentLatLng = latLng;
      if (mounted) {
        _mapController?.setCenter(latLng);
        _mapController?.setLevel(5);
        if (_selectedCategory == 'TMO') {
          _loadTmoList();
        } else {
          _resetAndLoadStores();
        }
      }
    } catch (_) {
      _moveToFallbackLocation();
    }
  }

  void _moveToFallbackLocation() {
    _currentLatLng = _fallbackCenter;
    _mapController?.setCenter(_fallbackCenter);
    _mapController?.setLevel(4);
  }

  LatLng get _requestCenter => _currentLatLng ?? _fallbackCenter;

  void _resetAndLoadStores({String keyword = ''}) {
    _stores.clear();
    _storePage = 0;
    _storeHasNext = false;
    _activeKeyword = keyword;
    _loadMoreStores(isFirstPage: true);
  }

  Future<void> _loadMoreStores({bool isFirstPage = false}) async {
    if (!isFirstPage && (_loadingMoreStores || !_storeHasNext)) return;
    if (isFirstPage && _loadingStores) return;

    if (isFirstPage) {
      setState(() {
        _loadingStores = true;
        _selectedStore = null;
        _selectedTmo = null;
      });
    } else {
      setState(() {
        _loadingMoreStores = true;
      });
    }

    try {
      final center = _requestCenter;
      final isKeywordSearch = _activeKeyword.isNotEmpty;

      final result = await StoreApi.getList(
        page: _storePage,
        size: 20,
        category: _storeCategoryApiValue(_selectedCategory),
        lat: center.latitude,
        lng: center.longitude,
        radius: isKeywordSearch ? null : _radius,
        keyword: isKeywordSearch ? _activeKeyword : null,
      );

      if (!mounted) return;

      setState(() {
        _stores.addAll(result.content);
        _storeHasNext = result.hasNext;
        _storePage += 1;
      });

      if (isFirstPage && result.content.isNotEmpty) {
        _mapController?.setCenter(_requestCenter);
        _mapController?.setLevel(7);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('매장 정보를 불러오지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingStores = false;
          _loadingMoreStores = false;
        });
      }
    }
  }

  Future<void> _loadTmoList() async {
    setState(() {
      _loadingTmos = true;
      _selectedStore = null;
      _selectedTmo = null;
    });

    try {
      final center = _requestCenter;

      final tmos = await TmoApi.getList(
        lat: center.latitude,
        lng: center.longitude,
      );

      if (!mounted) return;

      setState(() {
        _tmos = tmos;
      });

      if (tmos.isNotEmpty) {
        _mapController?.setCenter(_requestCenter);
        _mapController?.setLevel(8);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('TMO 정보를 불러오지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingTmos = false;
        });
      }
    }
  }

  Future<void> _runSearch() async {
    final keyword = _searchController.text.trim();

    if (keyword.isEmpty) {
      _showSnackBar('검색어를 입력해주세요.');
      return;
    }

    if (_isTmoMode) {
      final results = _tmos.where((tmo) {
        return tmo.name.contains(keyword) ||
            tmo.address.contains(keyword) ||
            tmo.locationDescription.contains(keyword);
      }).toList();

      if (results.isEmpty) {
        _showSnackBar('검색 결과가 없습니다.');
        return;
      }

      final target = results.first;

      setState(() {
        _selectedTmo = target;
      });

      _mapController?.setCenter(LatLng(target.latitude, target.longitude));
      _mapController?.setLevel(5);
      return;
    }

    _resetAndLoadStores(keyword: keyword);
  }

  String _storeOverlayHtml(Store store) {
    final name = store.name
        .replaceAll("'", "\\'")
        .replaceAll('"', '&quot;')
        .replaceAll('<', '&lt;');
    final cat = store.categoryLabel;
    final dist = store.distanceKm != null ? store.distanceLabel : '';
    final distHtml = dist.isNotEmpty
        ? '<span style="color:#5B8E63;font-weight:600;font-size:11px;margin-left:6px;">$dist</span>'
        : '';

    return '''
<div style="
  position:relative;
  display:inline-flex;
  flex-direction:column;
  align-items:center;
">
  <div style="
    background:white;
    border-radius:14px;
    padding:9px 14px 9px 10px;
    box-shadow:0 4px 20px rgba(0,0,0,0.18),0 1px 4px rgba(0,0,0,0.08);
    display:flex;
    align-items:center;
    gap:8px;
    white-space:nowrap;
    border:1.5px solid #e2ede4;
  ">
    <div style="
      background:#5B8E63;
      border-radius:50%;
      width:26px;height:26px;
      display:flex;align-items:center;justify-content:center;
      flex-shrink:0;
    ">
      <svg width='13' height='13' viewBox='0 0 24 24' fill='white'>
        <path d='M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z'/>
      </svg>
    </div>
    <div>
      <div style="font-size:13px;font-weight:700;color:#1a1a1a;line-height:1.3;font-family:-apple-system,sans-serif;">$name</div>
      <div style="font-size:11px;color:#888;font-weight:500;font-family:-apple-system,sans-serif;">$cat$distHtml</div>
    </div>
  </div>
  <div style="
    width:0;height:0;
    border-left:7px solid transparent;
    border-right:7px solid transparent;
    border-top:8px solid white;
    margin-top:-1px;
    filter:drop-shadow(0 2px 2px rgba(0,0,0,0.06));
  "></div>
</div>''';
  }

  void _showStoreOverlay(Store store) {
    _mapController?.clearCustomOverlay();
    _mapController?.addCustomOverlay(
      customOverlays: [
        CustomOverlay(
          customOverlayId: 'store_label',
          latLng: LatLng(store.latitude, store.longitude),
          content: _storeOverlayHtml(store),
          yAnchor: 1.08,
        ),
      ],
    );
  }

  void _clearStoreOverlay() {
    _mapController?.clearCustomOverlay();
  }

  void _onMarkerTap(String markerId) {
    if (markerId.startsWith('tmo_')) {
      final id = int.tryParse(markerId.replaceFirst('tmo_', ''));
      if (id == null) return;

      final tmo = _tmos.firstWhere((item) => item.id == id);

      setState(() {
        _selectedTmo = tmo;
        _selectedStore = null;
      });

      _clearStoreOverlay();
      _mapController?.setCenter(LatLng(tmo.latitude, tmo.longitude));
      return;
    }

    if (markerId.startsWith('store_')) {
      final id = int.tryParse(markerId.replaceFirst('store_', ''));
      if (id == null) return;

      final store = _stores.firstWhere((item) => item.id == id);

      setState(() {
        _selectedStore = store;
        _selectedTmo = null;
      });

      _showStoreOverlay(store);
      _mapController?.setCenter(LatLng(store.latitude, store.longitude));
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  Future<void> _handleCategorySelected(String category) async {
    final deselect = category != 'TMO' && _selectedCategory == category;
    final next = deselect ? null : category;

    setState(() {
      _selectedCategory = next;
      _searchController.clear();
      _selectedStore = null;
      _selectedTmo = null;
    });

    if (next == 'TMO') {
      await _loadTmoList();
    } else {
      _resetAndLoadStores();
    }
  }

  Future<void> _moveToMyLocationAndReload() async {
    await _requestLocationPermission();

    if (_isTmoMode) {
      await _loadTmoList();
    } else {
      _resetAndLoadStores(keyword: _activeKeyword);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = _loadingStores || _loadingTmos;

    return Stack(
      children: [
        KakaoMap(
          center: _fallbackCenter,
          currentLevel: 5,
          markers: _markers,
          zoomControl: true,
          mapTypeControl: false,
          onMapCreated: (controller) {
            _mapController = controller;
            _mapController?.setCenter(_requestCenter);
          },
          onMarkerTap: (markerId, latLng, zoomLevel) {
            _onMarkerTap(markerId);
          },
        ),
        if (_isStoreMode && _selectedStore == null)
          _StoreListPanel(
            stores: _stores,
            selectedStore: _selectedStore,
            loading: _loadingStores,
            loadingMore: _loadingMoreStores,
            hasNext: _storeHasNext,
            categoryLabel: _selectedCategory,
            activeKeyword: _activeKeyword,
            radius: _radius,
            onRadiusChanged: (r) {
              setState(() => _radius = r);
              _resetAndLoadStores(keyword: _activeKeyword);
            },
            onLoadMore: () => _loadMoreStores(),
            onTapStore: (store) {
              setState(() {
                _selectedStore = store;
                _selectedTmo = null;
              });
              _showStoreOverlay(store);
              _mapController?.setCenter(
                LatLng(store.latitude, store.longitude),
              );
              _mapController?.setLevel(5);
            },
            onOpenDetail: (store) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreDetailScreen(store: store),
                ),
              );
            },
          ),
        if (_selectedStore != null && _isStoreMode)
          _StoreBottomSheet(
            store: _selectedStore!,
            onClose: () {
              setState(() => _selectedStore = null);
              _clearStoreOverlay();
            },
            onDetailTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreDetailScreen(store: _selectedStore!),
                ),
              );
            },
          ),
        Positioned(
          top: 22,
          left: 24,
          right: 24,
          child: Column(
            children: [
              _MapSearchField(
                controller: _searchController,
                onSubmitted: (_) => _runSearch(),
                onSearch: _runSearch,
                onClear: () {
                  _searchController.clear();
                  if (_activeKeyword.isNotEmpty) {
                    _resetAndLoadStores();
                  }
                },
              ),
              const SizedBox(height: 18),
              _CategoryChipBar(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onSelected: _handleCategorySelected,
              ),
            ],
          ),
        ),
        if (loading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: Colors.transparent,
              color: AppColors.primaryAccent,
            ),
          ),
        Positioned(
          right: 18,
          bottom: 270,
          child: FloatingActionButton.small(
            heroTag: 'current_location',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            elevation: 3,
            onPressed: _moveToMyLocationAndReload,
            child: const Icon(Icons.my_location_outlined),
          ),
        ),
        if (_selectedTmo != null)
          Positioned(
            left: 22,
            right: 22,
            top: 178,
            child: _TmoInfoCard(
              tmo: _selectedTmo!,
              onClose: () {
                setState(() {
                  _selectedTmo = null;
                });
              },
              onDetailTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TmoDetailScreen(tmo: _selectedTmo!),
                  ),
                );
              },
            ),
          ),
        if (_isTmoMode)
          _TmoListPanel(
            controller: _sheetController,
            tmos: _tmos,
            selectedTmo: _selectedTmo,
            onTapTmo: (tmo) {
              setState(() {
                _selectedTmo = null;
              });
              _mapController?.setCenter(LatLng(tmo.latitude, tmo.longitude));
              _mapController?.setLevel(5);
            },
            onOpenDetail: (tmo) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TmoDetailScreen(tmo: tmo)),
              );
            },
          ),
      ],
    );
  }
}

class _MapSearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const _MapSearchField({
    required this.controller,
    required this.onSubmitted,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<_MapSearchField> createState() => _MapSearchFieldState();
}

class _MapSearchFieldState extends State<_MapSearchField> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = widget.controller.text.isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 18, right: 10),
            child: Icon(Icons.search, color: AppColors.primaryAccent, size: 30),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              textInputAction: TextInputAction.search,
              onSubmitted: widget.onSubmitted,
              decoration: const InputDecoration(
                hintText: '매장명으로 검색',
                hintStyle: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSub,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 19),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
            ),
          ),
          if (_hasText) ...[
            GestureDetector(
              onTap: widget.onClear,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.cancel, color: AppColors.textSub, size: 22),
              ),
            ),
            GestureDetector(
              onTap: widget.onSearch,
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '검색',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChipBar extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String> onSelected;

  const _CategoryChipBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  _CategoryChipData _dataFor(String category) {
    switch (category) {
      case '음식':
        return const _CategoryChipData(
          icon: Icons.restaurant_menu,
          label: '음식',
        );
      case '숙박':
        return const _CategoryChipData(icon: Icons.hotel_outlined, label: '숙박');
      case 'PC방':
        return const _CategoryChipData(
          icon: Icons.desktop_windows_outlined,
          label: 'PC방',
        );
      case '서비스':
        return const _CategoryChipData(
          icon: Icons.local_cafe_outlined,
          label: '서비스',
        );
      case 'TMO':
        return const _CategoryChipData(
          icon: Icons.train_outlined,
          label: 'TMO',
        );
      default:
        return _CategoryChipData(label: category);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == category;
          final data = _dataFor(category);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(category),
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary2 : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (data.icon != null) ...[
                      Icon(
                        data.icon,
                        size: 19,
                        color: selected
                            ? Colors.white
                            : AppColors.primaryAccent,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      data.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : AppColors.primaryAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChipData {
  final IconData? icon;
  final String label;

  const _CategoryChipData({this.icon, required this.label});
}

class _StoreListPanel extends StatefulWidget {
  final List<Store> stores;
  final Store? selectedStore;
  final bool loading;
  final bool loadingMore;
  final bool hasNext;
  final String? categoryLabel;
  final String activeKeyword;
  final double? radius;
  final ValueChanged<double?> onRadiusChanged;
  final VoidCallback onLoadMore;
  final ValueChanged<Store> onTapStore;
  final ValueChanged<Store> onOpenDetail;

  const _StoreListPanel({
    required this.stores,
    required this.selectedStore,
    required this.loading,
    required this.loadingMore,
    required this.hasNext,
    required this.categoryLabel,
    required this.activeKeyword,
    required this.radius,
    required this.onRadiusChanged,
    required this.onLoadMore,
    required this.onTapStore,
    required this.onOpenDetail,
  });

  @override
  State<_StoreListPanel> createState() => _StoreListPanelState();
}

class _StoreListPanelState extends State<_StoreListPanel> {
  ScrollController? _scrollController;

  void _onScroll() {
    final sc = _scrollController;
    if (sc == null || !sc.hasClients) return;
    if (sc.position.pixels >= sc.position.maxScrollExtent - 300) {
      widget.onLoadMore();
    }
  }

  void _attachController(ScrollController controller) {
    if (_scrollController == controller) return;
    _scrollController?.removeListener(_onScroll);
    _scrollController = controller;
    _scrollController!.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  String get _headerTitle {
    if (widget.activeKeyword.isNotEmpty) {
      return '"${widget.activeKeyword}" 검색 결과';
    }
    if (widget.categoryLabel == null || widget.categoryLabel!.isEmpty) {
      return '전체 매장';
    }
    return widget.categoryLabel!;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      minChildSize: 0.16,
      initialChildSize: 0.38,
      maxChildSize: 0.86,
      snap: true,
      snapSizes: const [0.16, 0.38, 0.86],
      builder: (context, scrollController) {
        _attachController(scrollController);

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4D4D4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _headerTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  const Icon(Icons.sort, size: 18, color: AppColors.textSub),
                  const SizedBox(width: 4),
                  const Text(
                    '거리순',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (widget.activeKeyword.isEmpty)
                Row(
                  children: [
                    const Icon(Icons.radar, size: 16, color: AppColors.textSub),
                    const SizedBox(width: 6),
                    const Text(
                      '반경',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSub,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<double?>(
                          value: widget.radius,
                          isDense: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.textSub,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                          items: [
                            const DropdownMenuItem<double?>(
                              value: null,
                              child: Text('선택 안함'),
                            ),
                            ..._kRadiusOptions.map((r) {
                              return DropdownMenuItem<double?>(
                                value: r,
                                child: Text('${r.toInt()}km'),
                              );
                            }),
                          ],
                          onChanged: (r) => widget.onRadiusChanged(r),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              if (widget.loading)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryAccent,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (widget.stores.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      '주변에 해당 매장이 없습니다.',
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else ...[
                ...widget.stores.map((store) {
                  final selected = widget.selectedStore?.id == store.id;
                  return _StoreListItem(
                    store: store,
                    selected: selected,
                    onTap: () => widget.onTapStore(store),
                    onOpenDetail: () => widget.onOpenDetail(store),
                  );
                }),
                if (widget.loadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAccent,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                if (!widget.hasNext && widget.stores.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: Text(
                        widget.radius != null
                            ? '반경 ${widget.radius!.toInt()}km 내 모든 매장을 불러왔습니다.'
                            : '모든 매장을 불러왔습니다.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StoreListItem extends StatelessWidget {
  final Store store;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onOpenDetail;

  const _StoreListItem({
    required this.store,
    required this.selected,
    required this.onTap,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceSoft : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: AppColors.border)
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: selected
                    ? AppColors.primaryAccent
                    : const Color(0xFFB8B8B8),
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.primaryAccent
                            : AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        store.categoryLabel,
                        if (store.distanceKm != null) store.distanceLabel,
                        if (store.maxDiscountRate != null)
                          '최대 ${store.maxDiscountRate}% 할인',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOpenDetail,
                icon: const Icon(Icons.chevron_right, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreBottomSheet extends StatefulWidget {
  final Store store;
  final VoidCallback onClose;
  final Future<void> Function() onDetailTap;

  const _StoreBottomSheet({
    required this.store,
    required this.onClose,
    required this.onDetailTap,
  });

  @override
  State<_StoreBottomSheet> createState() => _StoreBottomSheetState();
}

class _StoreBottomSheetState extends State<_StoreBottomSheet> {
  static const double _minSize = 0.24;
  static const double _initialSize = 0.38;
  static const double _maxSize = 0.86;
  static const double _openThreshold = 0.82;
  static const double _resetThreshold = 0.72;

  final DraggableScrollableController _dragController =
      DraggableScrollableController();

  bool _openedDetail = false;
  bool _canTriggerFromDrag = true;

  Store get store => widget.store;

  @override
  void didUpdateWidget(covariant _StoreBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store.id != widget.store.id) {
      _openedDetail = false;
      _canTriggerFromDrag = true;
      if (_dragController.isAttached) {
        _dragController.jumpTo(_initialSize);
      }
    }
  }

  bool get _hasBusinessHours {
    return store.openTime != null && store.closeTime != null;
  }

  bool get _isOpenNow {
    if (!_hasBusinessHours) return false;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final open = _parseTime(store.openTime!);
    final close = _parseTime(store.closeTime!);

    if (open == null || close == null) return false;

    final openMinutes = open.hour * 60 + open.minute;
    final closeMinutes = close.hour * 60 + close.minute;

    if (closeMinutes < openMinutes) {
      return currentMinutes >= openMinutes || currentMinutes <= closeMinutes;
    }

    return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
  }

  String get _businessStatusLabel {
    if (!_hasBusinessHours) return '운영 확인';
    return _isOpenNow ? '영업 중' : '영업 종료';
  }

  Color get _businessStatusBackground {
    if (!_hasBusinessHours) return const Color(0xFFF1F1F1);
    return _isOpenNow ? AppColors.badge : const Color(0xFFF1F1F1);
  }

  Color get _businessStatusTextColor {
    if (!_hasBusinessHours) return AppColors.textSub;
    return _isOpenNow ? AppColors.badgeText : AppColors.textSub;
  }

  ({int hour, int minute})? _parseTime(String value) {
    final parts = value.split(':');

    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    return (hour: hour, minute: minute);
  }

  Future<void> _resetSheet() async {
    if (!_dragController.isAttached) return;

    try {
      await _dragController.animateTo(
        _initialSize,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } catch (_) {
      if (_dragController.isAttached) {
        _dragController.jumpTo(_initialSize);
      }
    }
  }

  Future<void> _openDetailFromDrag() async {
    if (_openedDetail || !_canTriggerFromDrag) return;

    _openedDetail = true;
    _canTriggerFromDrag = false;

    await _resetSheet();

    try {
      await widget.onDetailTap();
    } finally {
      if (!mounted) return;

      setState(() {
        _openedDetail = false;
        _canTriggerFromDrag = true;
      });

      await _resetSheet();
    }
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        final extent = notification.extent;

        if (extent < _resetThreshold) {
          _canTriggerFromDrag = true;
        }

        if (extent >= _openThreshold && _canTriggerFromDrag && !_openedDetail) {
          _openDetailFromDrag();
        }

        return false;
      },
      child: DraggableScrollableSheet(
        controller: _dragController,
        minChildSize: _minSize,
        initialChildSize: _initialSize,
        maxChildSize: _maxSize,
        snap: true,
        snapSizes: const [_minSize, _initialSize, _maxSize],
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4D4D4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _BusinessStatusBadge(
                        label: _businessStatusLabel,
                        backgroundColor: _businessStatusBackground,
                        textColor: _businessStatusTextColor,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.primaryAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          store.mainBenefitDescription,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _hasBusinessHours
                        ? '현재 $_businessStatusLabel · ${store.closeTimeLabel}'
                        : '운영 시간 확인 필요',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSub,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    store.distanceLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSub,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await widget.onDetailTap();
                        if (mounted) {
                          await _resetSheet();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '상세 보기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BusinessStatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _BusinessStatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _TmoInfoCard extends StatelessWidget {
  final Tmo tmo;
  final VoidCallback onClose;
  final VoidCallback onDetailTap;

  const _TmoInfoCard({
    required this.tmo,
    required this.onClose,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 16, 18),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tmo.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                _TmoStatusBadge(tmo: tmo),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoRow(label: '운영 시간', value: tmo.todayHours),
            _InfoRow(label: '현재 위치와의 거리', value: tmo.distanceLabel),
            _InfoRow(label: '전화번호', value: tmo.phoneLabel),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onDetailTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surfaceSoft,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '상세 보기',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TmoListPanel extends StatelessWidget {
  final DraggableScrollableController controller;
  final List<Tmo> tmos;
  final Tmo? selectedTmo;
  final ValueChanged<Tmo> onTapTmo;
  final ValueChanged<Tmo> onOpenDetail;

  const _TmoListPanel({
    required this.controller,
    required this.tmos,
    required this.selectedTmo,
    required this.onTapTmo,
    required this.onOpenDetail,
  });

  String _displayTmoName(Tmo tmo) {
    return tmo.name.replaceAll(' TMO', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      minChildSize: 0.16,
      initialChildSize: 0.38,
      maxChildSize: 0.86,
      snap: true,
      snapSizes: const [0.16, 0.38, 0.86],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4D4D4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'TMO 목록',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  Icon(Icons.tune, size: 18, color: AppColors.textSub),
                  SizedBox(width: 5),
                  Text(
                    '거리순',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (tmos.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      '주변 TMO 정보를 불러오는 중입니다.',
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                ...tmos.map((tmo) {
                  final selected = selectedTmo?.id == tmo.id;

                  return _TmoListItem(
                    tmo: tmo,
                    displayName: _displayTmoName(tmo),
                    selected: selected,
                    onTap: () => onTapTmo(tmo),
                    onOpenDetail: () => onOpenDetail(tmo),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _TmoListItem extends StatelessWidget {
  final Tmo tmo;
  final String displayName;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onOpenDetail;

  const _TmoListItem({
    required this.tmo,
    required this.displayName,
    required this.selected,
    required this.onTap,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceSoft : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: AppColors.border)
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: selected
                    ? AppColors.primaryAccent
                    : const Color(0xFFB8B8B8),
                size: 30,
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 58,
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '현재 위치와의 거리 ${tmo.distanceLabel}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.primaryAccent
                            : AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tmo.todayHours} · ${tmo.phoneLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOpenDetail,
                icon: const Icon(Icons.chevron_right, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TmoStatusBadge extends StatelessWidget {
  final Tmo tmo;

  const _TmoStatusBadge({required this.tmo});

  @override
  Widget build(BuildContext context) {
    final isOpen = tmo.isOpenNow;
    final hasHours = tmo.hasTodayOperatingHours;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasHours && isOpen ? AppColors.badge : const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tmo.operatingStatusLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: hasHours && isOpen ? AppColors.badgeText : AppColors.textSub,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSub,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionIllustration extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PermissionIllustration({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Icon(icon, size: 48, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
          ),
        ),
      ],
    );
  }
}

class _PermissionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PermissionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textMain,
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
