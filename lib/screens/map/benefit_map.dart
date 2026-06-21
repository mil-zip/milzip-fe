import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../models/store.dart';
import '../../models/tmo.dart';
import '../../services/location_service.dart';
import '../../services/store_api.dart';
import '../../services/tmo_api.dart';
import '../../theme/app_colors.dart';
import 'store_detail_screen.dart';
import 'tmo_detail_screen.dart';
import 'web_kakao_map.dart';

part 'widgets/map_search_field.dart';
part 'widgets/category_chip_bar.dart';
part 'widgets/store_panels.dart';
part 'widgets/tmo_panels.dart';
part 'widgets/permission_widgets.dart';

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

  final LatLng _fallbackCenter = LatLng(37.8949, 127.2003);

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

  /// 웹 지도 이동 대상 (값이 바뀌면 WebKakaoMap이 해당 위치로 이동)
  LatLng? _focusTarget;

  /// 하단 시트가 차지하는 높이 비율 (FAB가 시트 위에 따라붙도록 추적)
  double _sheetExtent = 0.38;

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

  /// 웹 지도용 마커 데이터
  List<WebMarker> get _webMarkers {
    if (_isTmoMode) {
      return _tmos
          .map((t) =>
              WebMarker(id: 'tmo_${t.id}', lat: t.latitude, lng: t.longitude))
          .toList();
    }
    return _stores
        .map((s) =>
            WebMarker(id: 'store_${s.id}', lat: s.latitude, lng: s.longitude))
        .toList();
  }

  @override
  void initState() {
    super.initState();

    // 헤더에서 선택된 위치로 초기화 (기본: 포천시 신북읍)
    _currentLatLng = LatLng(LocationService.instance.lat, LocationService.instance.lng);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_selectedCategory == 'TMO') {
        _loadTmoList();
      } else {
        _resetAndLoadStores();
      }
      _showLocationPermissionDialogIfNeeded();
    });
    LocationService.instance.locationNotifier.addListener(_onHeaderLocationChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    LocationService.instance.locationNotifier.removeListener(_onHeaderLocationChanged);
    super.dispose();
  }

  void _onHeaderLocationChanged() {
    final svc = LocationService.instance;
    final latLng = LatLng(svc.lat, svc.lng);
    _currentLatLng = latLng;
    _mapController?.setCenter(latLng);
    _mapController?.setLevel(7);
    if (_isTmoMode) {
      _loadTmoList();
    } else {
      _resetAndLoadStores();
    }
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
      // 이미 권한 있음 — 헤더에서 선택된 위치를 유지하고 별도 이동 안 함
      return;
    }

    _permissionDialogShown = true;

    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PermissionHeroIcon(),
                const SizedBox(height: 24),
                const Text(
                  '내 주변 혜택을 찾으려면\n위치 권한이 필요해요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '현재 위치를 기반으로 가까운 군장병 혜택\n매장을 정확하게 보여드려요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSub,
                  ),
                ),
                const SizedBox(height: 28),
                _PermissionActionButton(
                  label: '위치 허용하기',
                  filled: true,
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await _requestLocationPermission();
                  },
                ),
                const SizedBox(height: 6),
                _PermissionActionButton(
                  label: '다음에 할게요',
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
        _focusTarget = LatLng(target.latitude, target.longitude);
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

  /// 지도 빈 곳 클릭 → 선택된 상세(매장/TMO) 닫기
  void _clearSelection() {
    if (_selectedStore == null && _selectedTmo == null) return;
    setState(() {
      _selectedStore = null;
      _selectedTmo = null;
    });
    _clearStoreOverlay();
  }

  void _onMarkerTap(String markerId) {
    if (markerId.startsWith('tmo_')) {
      final id = int.tryParse(markerId.replaceFirst('tmo_', ''));
      if (id == null) return;

      final tmo = _tmos.firstWhere((item) => item.id == id);

      setState(() {
        _selectedTmo = tmo;
        _selectedStore = null;
        _focusTarget = LatLng(tmo.latitude, tmo.longitude);
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
        _focusTarget = LatLng(store.latitude, store.longitude);
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
    // GPS가 아닌, 헤더에서 설정된 위치(LocationService)로 이동
    final svc = LocationService.instance;
    final latLng = LatLng(svc.lat, svc.lng);

    setState(() {
      _currentLatLng = latLng;
      _focusTarget = latLng;
      _selectedStore = null;
      _selectedTmo = null;
    });
    _clearStoreOverlay();
    _mapController?.setCenter(latLng);
    _mapController?.setLevel(5);

    if (_isTmoMode) {
      await _loadTmoList();
    } else {
      _resetAndLoadStores(keyword: _activeKeyword);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = _loadingStores || _loadingTmos;

    return LayoutBuilder(
      builder: (context, constraints) {
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (n) {
            if ((n.extent - _sheetExtent).abs() > 0.004) {
              setState(() => _sheetExtent = n.extent);
            }
            return false;
          },
          child: _buildBody(loading, constraints.maxHeight),
        );
      },
    );
  }

  Widget _buildBody(bool loading, double availableHeight) {
    return Stack(
      children: [
        Positioned.fill(
          child: kIsWeb
              ? WebKakaoMap(
                  lat: _requestCenter.latitude,
                  lng: _requestCenter.longitude,
                  level: 5,
                  markers: _webMarkers,
                  onMarkerTap: _onMarkerTap,
                  onMapTap: _clearSelection,
                  focusLat: _focusTarget?.latitude,
                  focusLng: _focusTarget?.longitude,
                )
              : KakaoMap(
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
                  onMapTap: (latLng) {
                    _clearSelection();
                  },
                ),
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
                _focusTarget = LatLng(store.latitude, store.longitude);
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
          bottom: availableHeight * _sheetExtent + 12,
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
                _selectedTmo = tmo;
                _focusTarget = LatLng(tmo.latitude, tmo.longitude);
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
