import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../data/store_dummy.dart';
import '../../models/store.dart';
import '../../models/tmo.dart';
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

  final LatLng _fallbackCenter = LatLng(37.95745120515425, 127.3174892339337);

  late final List<Store> _stores;

  final List<String> _categories = ['음식', '숙박', 'PC방', '서비스', 'TMO'];

  String _selectedCategory = '음식';
  String _searchText = '';

  Store? _selectedStore;
  Tmo? _focusedTmo;
  Tmo? _openedTmo;

  List<Tmo> _tmos = [];

  bool _loadingTmo = false;
  bool _permissionDialogShown = false;

  bool get _isTmoMode => _selectedCategory == 'TMO';

  @override
  void initState() {
    super.initState();

    _stores = getDummyStores();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLocationPermissionDialogIfNeeded();
      _moveToFirstStoreInCategory('음식');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Store> get _filteredStores {
    return _stores.where((store) {
      final categoryMatch = store.categoryLabel == _selectedCategory;
      final query = _searchText.trim().toLowerCase();

      final searchMatch =
          query.isEmpty ||
          store.name.toLowerCase().contains(query) ||
          store.address.toLowerCase().contains(query);

      return categoryMatch && searchMatch;
    }).toList();
  }

  List<Marker> get _markers {
    if (_isTmoMode) {
      return _tmos.map((tmo) {
        final selected = _focusedTmo?.id == tmo.id;

        return Marker(
          markerId: 'tmo_${tmo.id}',
          latLng: LatLng(tmo.latitude, tmo.longitude),
          width: selected ? 44 : 34,
          height: selected ? 48 : 38,
        );
      }).toList();
    }

    return _filteredStores.map((store) {
      final selected = _selectedStore?.id == store.id;

      return Marker(
        markerId: 'store_${store.id}',
        latLng: LatLng(store.latitude, store.longitude),
        width: selected ? 44 : 34,
        height: selected ? 48 : 38,
      );
    }).toList();
  }

  void _moveToFirstStoreInCategory(String category) {
    final stores = _stores
        .where((store) => store.categoryLabel == category)
        .toList();

    if (stores.isEmpty) return;

    final first = stores.first;

    _mapController?.setCenter(LatLng(first.latitude, first.longitude));
    _mapController?.setLevel(5);
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
                      color: AppColors.primaryLight,
                    ),
                    SizedBox(width: 26),
                    _PermissionIllustration(
                      icon: Icons.map_outlined,
                      label: '대략적인 위치',
                      color: AppColors.secondary,
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

  Future<LatLng> _getCurrentOrFallbackLatLng() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) return _fallbackCenter;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return _fallbackCenter;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return LatLng(position.latitude, position.longitude);
  }

  Future<void> _requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showSnackBar('기기 위치 서비스가 꺼져 있어 기본 위치로 이동합니다.');
      _moveToFallbackLocation();
      return;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showSnackBar('위치 권한이 허용되지 않아 기본 위치로 이동합니다.');
      _moveToFallbackLocation();
      return;
    }

    await _moveToCurrentLocation();
  }

  Future<void> _moveToCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final currentLatLng = LatLng(position.latitude, position.longitude);

    _mapController?.setCenter(currentLatLng);
    _mapController?.setLevel(4);
  }

  void _moveToFallbackLocation() {
    _mapController?.setCenter(_fallbackCenter);
    _mapController?.setLevel(4);
  }

  Future<void> _loadTmoList() async {
    setState(() {
      _loadingTmo = true;
      _selectedStore = null;
      _focusedTmo = null;
      _openedTmo = null;
    });

    try {
      final center = await _getCurrentOrFallbackLatLng();

      final result = await TmoApi.getList(
        lat: center.latitude,
        lng: center.longitude,
      );

      if (!mounted) return;

      setState(() {
        _tmos = result;
      });

      if (_tmos.isNotEmpty) {
        final first = _tmos.first;

        _mapController?.setCenter(LatLng(first.latitude, first.longitude));
        _mapController?.setLevel(7);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('TMO 정보를 불러오지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingTmo = false;
        });
      }
    }
  }

  void _runSearch(String value) {
    setState(() {
      _searchText = value.trim();
    });

    if (_isTmoMode) {
      if (_searchText.isEmpty) return;

      final query = _searchText.toLowerCase();

      final results = _tmos.where((tmo) {
        return tmo.name.toLowerCase().contains(query) ||
            tmo.address.toLowerCase().contains(query);
      }).toList();

      if (results.isEmpty) {
        _showSnackBar('검색 결과가 없습니다.');
        return;
      }

      final target = results.first;

      setState(() {
        _focusedTmo = target;
        _openedTmo = null;
      });

      _mapController?.setCenter(LatLng(target.latitude, target.longitude));
      _mapController?.setLevel(5);
      return;
    }

    if (_filteredStores.isEmpty) {
      _showSnackBar('검색 결과가 없습니다.');
      return;
    }

    final target = _filteredStores.first;

    setState(() {
      _selectedStore = target;
      _focusedTmo = null;
      _openedTmo = null;
    });

    _mapController?.setCenter(LatLng(target.latitude, target.longitude));
    _mapController?.setLevel(5);
  }

  void _selectMarkerById(String markerId) {
    if (markerId.startsWith('tmo_')) {
      final id = int.tryParse(markerId.replaceFirst('tmo_', ''));

      if (id == null) return;

      final matched = _tmos.where((tmo) => tmo.id == id).toList();

      if (matched.isEmpty) return;

      final selected = matched.first;

      setState(() {
        _focusedTmo = selected;
        _openedTmo = selected;
        _selectedStore = null;
      });

      _mapController?.setCenter(LatLng(selected.latitude, selected.longitude));
      _mapController?.setLevel(5);
      return;
    }

    if (markerId.startsWith('store_')) {
      final id = int.tryParse(markerId.replaceFirst('store_', ''));

      if (id == null) return;

      final matched = _stores.where((store) => store.id == id).toList();

      if (matched.isEmpty) return;

      final selected = matched.first;

      setState(() {
        _selectedStore = selected;
        _focusedTmo = null;
        _openedTmo = null;
      });

      _mapController?.setCenter(LatLng(selected.latitude, selected.longitude));
      _mapController?.setLevel(5);
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

  @override
  Widget build(BuildContext context) {
    final showTmoPanel = _isTmoMode && _tmos.isNotEmpty;

    return Stack(
      children: [
        KakaoMap(
          center: _fallbackCenter,
          currentLevel: 5,
          zoomControl: true,
          mapTypeControl: false,
          markers: _markers,
          onMapCreated: (controller) {
            _mapController = controller;

            if (!_isTmoMode) {
              _moveToFirstStoreInCategory(_selectedCategory);
            }
          },
          onMarkerTap: (markerId, latLng, zoomLevel) {
            _selectMarkerById(markerId);
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
                onSubmitted: _runSearch,
              ),
              const SizedBox(height: 14),
              _CategoryChipBar(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onSelected: (category) async {
                  setState(() {
                    _selectedCategory = category;
                    _selectedStore = null;
                    _focusedTmo = null;
                    _openedTmo = null;
                    _searchText = '';
                    _searchController.clear();
                  });

                  if (category == 'TMO') {
                    await _loadTmoList();
                  } else {
                    _moveToFirstStoreInCategory(category);
                  }
                },
              ),
            ],
          ),
        ),

        if (_loadingTmo)
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.45),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary2),
              ),
            ),
          ),

        if (_openedTmo != null)
          Positioned(
            top: 158,
            left: 28,
            right: 28,
            child: _TmoInfoCard(
              tmo: _openedTmo!,
              onClose: () {
                setState(() {
                  _openedTmo = null;
                });
              },
              onDetail: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TmoDetailScreen(tmo: _openedTmo!),
                  ),
                );
              },
            ),
          ),

        Positioned(
          right: 18,
          bottom: showTmoPanel
              ? 145
              : _selectedStore == null
              ? 24
              : 210,
          child: FloatingActionButton.small(
            heroTag: 'current_location',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary1,
            elevation: 3,
            onPressed: _requestLocationPermission,
            child: const Icon(Icons.my_location_outlined),
          ),
        ),

        if (_selectedStore != null)
          _StoreBottomSheet(
            store: _selectedStore!,
            onClose: () {
              setState(() {
                _selectedStore = null;
              });
            },
            onDetail: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreDetailScreen(store: _selectedStore!),
                ),
              );
            },
          ),

        if (showTmoPanel)
          _TmoListPanel(
            tmos: _tmos,
            focusedTmo: _focusedTmo,
            onTap: (tmo) {
              setState(() {
                _focusedTmo = tmo;
                _openedTmo = null;
              });

              _mapController?.setCenter(LatLng(tmo.latitude, tmo.longitude));
              _mapController?.setLevel(5);
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
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: '검색하기',
        prefixIcon: const Icon(Icons.search, color: AppColors.primary1),
        filled: true,
        fillColor: Colors.white.withOpacity(0.94),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary1, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary2, width: 2),
        ),
      ),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textMain,
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == category;

          return GestureDetector(
            onTap: () => onSelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary2 : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? AppColors.pressed : AppColors.primary2,
                  width: 2,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.primary2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TmoInfoCard extends StatelessWidget {
  final Tmo tmo;
  final VoidCallback onClose;
  final VoidCallback onDetail;

  const _TmoInfoCard({
    required this.tmo,
    required this.onClose,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tmo.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                _TmoStatusBadge(isOpen: _isTmoOpenNow(tmo)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(
                    Icons.close,
                    size: 24,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _TmoInfoLine(label: '운영 시간', value: _todayHours(tmo)),
            const SizedBox(height: 10),
            _TmoInfoLine(
              label: '현재 위치와의 거리',
              value: _formatDistance(tmo.distanceKm),
            ),
            const SizedBox(height: 10),
            _TmoInfoLine(label: '전화번호', value: tmo.phone ?? '전화번호 없음'),
            const SizedBox(height: 18),
            _TmoDetailButton(onTap: onDetail),
          ],
        ),
      ),
    );
  }
}

class _TmoStatusBadge extends StatelessWidget {
  final bool isOpen;

  const _TmoStatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: isOpen ? AppColors.badge : const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOpen ? '운영 중' : '운영 종료',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isOpen ? AppColors.primary2 : AppColors.textSub,
        ),
      ),
    );
  }
}

class _TmoInfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _TmoInfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w800,
              color: AppColors.textSub,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
        ),
      ],
    );
  }
}

class _TmoDetailButton extends StatelessWidget {
  final VoidCallback onTap;

  const _TmoDetailButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary1,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '상세 보기',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _TmoListPanel extends StatelessWidget {
  final List<Tmo> tmos;
  final Tmo? focusedTmo;
  final ValueChanged<Tmo> onTap;

  const _TmoListPanel({
    required this.tmos,
    required this.focusedTmo,
    required this.onTap,
  });

  static const double _minSize = 0.14;
  static const double _initialSize = 0.34;
  static const double _maxSize = 0.88;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: _initialSize,
      minChildSize: _minSize,
      maxChildSize: _maxSize,
      snap: true,
      snapSizes: const [_minSize, _initialSize, _maxSize],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0D0D0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                      child: Row(
                        children: const [
                          Expanded(
                            child: Text(
                              'TMO 목록',
                              style: TextStyle(
                                fontSize: 20,
                                color: AppColors.textMain,
                              ),
                            ),
                          ),
                          Icon(Icons.tune, size: 18, color: AppColors.textSub),
                          SizedBox(width: 4),
                          Text(
                            '거리순',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 96),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index.isOdd) {
                      return const SizedBox(height: 8);
                    }

                    final itemIndex = index ~/ 2;
                    final tmo = tmos[itemIndex];
                    final selected = focusedTmo?.id == tmo.id;

                    return _TmoListTile(
                      tmo: tmo,
                      selected: selected,
                      onTap: () => onTap(tmo),
                    );
                  }, childCount: tmos.isEmpty ? 0 : (tmos.length * 2) - 1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TmoListTile extends StatelessWidget {
  final Tmo tmo;
  final bool selected;
  final VoidCallback onTap;

  const _TmoListTile({
    required this.tmo,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final distance = _formatDistance(tmo.distanceKm);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceSoft : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.border : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                size: 31,
                color: selected
                    ? AppColors.primaryLight
                    : const Color(0xFFB8B8B8),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 64,
                child: Text(
                  tmo.name.replaceAll(' TMO', ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
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
                      '현재 위치와의 거리 $distance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? AppColors.primary2
                            : AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_todayHours(tmo)} · ${tmo.phone ?? '전화번호 없음'}',
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
              const Icon(Icons.chevron_right, color: AppColors.textMain),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreBottomSheet extends StatelessWidget {
  final Store store;
  final VoidCallback onClose;
  final VoidCallback onDetail;

  const _StoreBottomSheet({
    required this.store,
    required this.onClose,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -300) {
            onDetail();
          }
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D0D0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      store.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  const _MapRecommendBadge(),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(
                      Icons.close,
                      size: 28,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 22,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    store.benefitDescription,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '현재 영업 중 · ${store.closeTime}에 영업 종료',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSub,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '1.2km',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSub,
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapRecommendBadge extends StatelessWidget {
  const _MapRecommendBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.badge,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: const Text(
        '밀집추천',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.primary1,
        ),
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

String _formatDistance(double distanceKm) {
  if (distanceKm < 1) {
    return '${(distanceKm * 1000).round()}m';
  }

  if (distanceKm < 10) {
    return '${distanceKm.toStringAsFixed(1)}km';
  }

  return '${distanceKm.round()}km';
}

String _todayHours(Tmo tmo) {
  final now = DateTime.now();

  final isWeekend =
      now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

  final start = isWeekend ? tmo.weekendStartTime : tmo.weekdayStartTime;
  final end = isWeekend ? tmo.weekendEndTime : tmo.weekdayEndTime;

  if (start == null || end == null) {
    return tmo.mobile ? '출장형 운영' : '운영시간 없음';
  }

  return '$start ~ $end';
}

bool _isTmoOpenNow(Tmo tmo) {
  final now = DateTime.now();

  final isWeekend =
      now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

  final startRaw = isWeekend ? tmo.weekendStartTime : tmo.weekdayStartTime;
  final endRaw = isWeekend ? tmo.weekendEndTime : tmo.weekdayEndTime;

  if (startRaw == null || endRaw == null) {
    return false;
  }

  final start = _parseTime(startRaw);
  final end = _parseTime(endRaw);

  if (start == null || end == null) {
    return false;
  }

  final nowMinutes = now.hour * 60 + now.minute;
  final startMinutes = start.hour * 60 + start.minute;
  final endMinutes = end.hour * 60 + end.minute;

  if (endMinutes < startMinutes) {
    return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
  }

  return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
}

TimeOfDay? _parseTime(String value) {
  final parts = value.split(':');

  if (parts.length < 2) {
    return null;
  }

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);

  if (hour == null || minute == null) {
    return null;
  }

  return TimeOfDay(hour: hour, minute: minute);
}
