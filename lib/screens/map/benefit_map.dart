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

  String _selectedCategory = 'TMO';

  List<Store> _stores = [];
  List<Tmo> _tmos = [];

  Store? _selectedStore;
  Tmo? _selectedTmo;

  LatLng? _currentLatLng;

  bool _loadingStores = false;
  bool _loadingTmos = false;
  bool _permissionDialogShown = false;

  bool get _isTmoMode => _selectedCategory == 'TMO';

  List<Store> get _filteredStores {
    final keyword = _searchController.text.trim();

    if (keyword.isEmpty) return _stores;

    return _stores.where((store) {
      return store.name.contains(keyword) ||
          store.address.contains(keyword) ||
          store.categoryLabel.contains(keyword);
    }).toList();
  }

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

    return _filteredStores.map((store) {
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
      // 폴백 좌표로 즉시 데이터 로드 (위치 취득 기다리지 않음)
      if (_selectedCategory == 'TMO') {
        _loadTmoList();
      } else {
        _loadStoresByCategory(_selectedCategory);
      }
      // 위치 권한 확인 및 취득은 병렬로 처리
      _showLocationPermissionDialogIfNeeded();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  String? _storeCategoryApiValue(String categoryLabel) {
    switch (categoryLabel) {
      case '음식':
        return 'FOOD';
      case '숙박':
        return 'ACCOMMODATION';
      case 'PC방':
        return 'ETC';
      case '서비스':
        return 'ETC';
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
        // 실제 위치로 데이터 재로드
        if (_selectedCategory == 'TMO') {
          _loadTmoList();
        } else {
          _loadStoresByCategory(_selectedCategory);
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

  Future<void> _loadStoresByCategory(String categoryLabel) async {
    if (categoryLabel == 'TMO') return;

    setState(() {
      _loadingStores = true;
      _selectedStore = null;
      _selectedTmo = null;
    });

    try {
      final center = _requestCenter;

      final stores = await StoreApi.getList(
        page: 0,
        size: 50,
        category: _storeCategoryApiValue(categoryLabel),
        lat: center.latitude,
        lng: center.longitude,
      );

      if (!mounted) return;

      setState(() {
        _stores = stores;
      });

      if (stores.isNotEmpty) {
        final first = stores.first;
        _mapController?.setCenter(LatLng(first.latitude, first.longitude));
        _mapController?.setLevel(4);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('매장 정보를 불러오지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingStores = false;
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

    var results = _filteredStores;

    if (results.isEmpty) {
      setState(() {
        _loadingStores = true;
        _selectedStore = null;
      });

      try {
        final center = _requestCenter;

        results = await StoreApi.searchByKeyword(
          keyword: keyword,
          category: _storeCategoryApiValue(_selectedCategory),
          lat: center.latitude,
          lng: center.longitude,
        );

        if (!mounted) return;

        if (results.isNotEmpty) {
          setState(() {
            final existingIds = _stores.map((store) => store.id).toSet();
            final newStores = results
                .where((store) => !existingIds.contains(store.id))
                .toList();

            _stores = [...results, ...newStores, ..._stores];
          });
        }
      } catch (_) {
        if (!mounted) return;
        _showSnackBar('검색 중 오류가 발생했습니다.');
        return;
      } finally {
        if (mounted) {
          setState(() {
            _loadingStores = false;
          });
        }
      }
    }

    if (results.isEmpty) {
      _showSnackBar('검색 결과가 없습니다.');
      return;
    }

    final target = results.first;

    setState(() {
      _selectedStore = target;
      _selectedTmo = null;
    });

    _mapController?.setCenter(LatLng(target.latitude, target.longitude));
    _mapController?.setLevel(4);
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
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
      _selectedStore = null;
      _selectedTmo = null;
    });

    if (category == 'TMO') {
      await _loadTmoList();
    } else {
      await _loadStoresByCategory(category);
    }
  }

  Future<void> _moveToMyLocationAndReload() async {
    await _requestLocationPermission();

    if (_isTmoMode) {
      await _loadTmoList();
    } else {
      await _loadStoresByCategory(_selectedCategory);
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
        Positioned(
          top: 22,
          left: 24,
          right: 24,
          child: Column(
            children: [
              _MapSearchField(
                controller: _searchController,
                onSubmitted: (_) => _runSearch(),
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
          bottom: _isTmoMode ? 270 : 24,
          child: FloatingActionButton.small(
            heroTag: 'current_location',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            elevation: 3,
            onPressed: _moveToMyLocationAndReload,
            child: const Icon(Icons.my_location_outlined),
          ),
        ),
        if (_selectedStore != null && !_isTmoMode)
          _StoreBottomSheet(
            store: _selectedStore!,
            onClose: () {
              setState(() {
                _selectedStore = null;
              });
            },
            onDetailTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreDetailScreen(store: _selectedStore!),
                ),
              );
            },
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

class _MapSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  const _MapSearchField({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(32),
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        decoration: const InputDecoration(
          hintText: '검색하기',
          hintStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textSub,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 18, right: 10),
            child: Icon(Icons.search, color: AppColors.primaryAccent, size: 30),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 64),
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
    );
  }
}

class _CategoryChipBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
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
        return _CategoryChipData(icon: Icons.circle_outlined, label: category);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary2 : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      data.icon,
                      size: 21,
                      color: selected ? Colors.white : AppColors.primaryAccent,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      data.label,
                      style: TextStyle(
                        fontSize: 16,
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
  final IconData icon;
  final String label;

  const _CategoryChipData({required this.icon, required this.label});
}

class _StoreBottomSheet extends StatefulWidget {
  final Store store;
  final VoidCallback onClose;
  final VoidCallback onDetailTap;

  const _StoreBottomSheet({
    required this.store,
    required this.onClose,
    required this.onDetailTap,
  });

  @override
  State<_StoreBottomSheet> createState() => _StoreBottomSheetState();
}

class _StoreBottomSheetState extends State<_StoreBottomSheet> {
  bool _openedDetail = false;

  Store get store => widget.store;

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

  void _openDetailFromDrag() {
    if (_openedDetail) return;

    _openedDetail = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onDetailTap();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        if (notification.extent >= 0.82) {
          _openDetailFromDrag();
        }

        return false;
      },
      child: DraggableScrollableSheet(
        minChildSize: 0.24,
        initialChildSize: 0.38,
        maxChildSize: 0.86,
        snap: true,
        snapSizes: const [0.24, 0.38, 0.86],
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
                      onPressed: widget.onDetailTap,
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
