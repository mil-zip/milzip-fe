import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../data/store_dummy.dart';
import '../../models/store.dart';
import '../../theme/app_colors.dart';
import 'store_detail_screen.dart';

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
  bool _permissionDialogShown = false;

  List<Store> get _filteredStores {
    return _stores.where((store) {
      final matchesCategory = store.categoryLabel == _selectedCategory;
      final keyword = _searchText.trim().toLowerCase();

      final matchesSearch =
          keyword.isEmpty ||
          store.name.toLowerCase().contains(keyword) ||
          store.address.toLowerCase().contains(keyword) ||
          store.categoryDetail.toLowerCase().contains(keyword) ||
          store.menu.toLowerCase().contains(keyword);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<Marker> get _storeMarkers {
    return _filteredStores.map((store) {
      final selected = _selectedStore?.id == store.id;

      return Marker(
        markerId: 'store_${store.id}',
        latLng: store.latLng,
        width: selected ? 42 : 30,
        height: selected ? 52 : 38,
        zIndex: selected ? 10 : 1,
        infoWindowContent: store.name,
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _stores = getDummyStores();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLocationPermissionDialogIfNeeded();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showLocationPermissionDialogIfNeeded() async {
    if (_permissionDialogShown) return;

    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await _moveToCurrentLocation();
      return;
    }

    // 위치 권한 팝업 화면 확인을 위해 주석 처리

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
                      color: Color(0xFF168DFF),
                    ),
                    SizedBox(width: 26),
                    _PermissionIllustration(
                      icon: Icons.map_outlined,
                      label: '대략적인 위치',
                      color: Color(0xFFFFB51F),
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
                    _showSnackBar('위치 권한이 없어 포천시외버스터미널 기준으로 보여드립니다.');
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
      _moveToFallbackLocation();
      _showSnackBar('위치 서비스를 사용할 수 없어 포천시외버스터미널 기준으로 보여드립니다.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _moveToFallbackLocation();
      _showSnackBar('위치 권한이 없어 포천시외버스터미널 기준으로 보여드립니다.');
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

  void _runSearch(String keyword) {
    final trimmed = keyword.trim();

    setState(() {
      _searchText = trimmed;
      _selectedStore = null;
    });

    final results = _filteredStores;

    if (results.isEmpty) {
      _showSnackBar('검색 결과가 없습니다.');
      return;
    }

    final firstStore = results.first;

    setState(() {
      _selectedStore = firstStore;
    });

    _mapController?.setCenter(firstStore.latLng);
    _mapController?.setLevel(3);
  }

  void _selectStoreByMarkerId(String markerId) {
    final id = int.tryParse(markerId.replaceFirst('store_', ''));
    if (id == null) return;

    final matchedStores = _stores.where((store) => store.id == id).toList();
    if (matchedStores.isEmpty) return;

    final store = matchedStores.first;

    setState(() {
      _selectedStore = store;
    });

    _mapController?.setCenter(store.latLng);
    _mapController?.setLevel(3);
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
    return Stack(
      children: [
        KakaoMap(
          center: _fallbackCenter,
          currentLevel: 4,
          markers: _storeMarkers,
          zoomControl: true,
          mapTypeControl: false,
          onMapCreated: (controller) {
            _mapController = controller;
          },
          onMarkerTap: (markerId, latLng, zoomLevel) {
            _selectStoreByMarkerId(markerId);
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
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                    _selectedStore = null;
                  });
                },
                onSubmitted: _runSearch,
              ),
              const SizedBox(height: 14),
              _CategoryChipBar(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onSelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                    _selectedStore = null;
                  });
                },
              ),
            ],
          ),
        ),
        Positioned(
          right: 18,
          bottom: _selectedStore == null ? 24 : 210,
          child: FloatingActionButton.small(
            heroTag: 'current_location',
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
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
          ),
      ],
    );
  }
}

class _MapSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _MapSearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: '검색하기',
        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.surface.withOpacity(0.94),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryAccent,
            width: 2,
          ),
        ),
      ),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
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
                color: selected ? AppColors.primaryAccent : AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primaryAccent, width: 2),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? AppColors.textWhite
                      : AppColors.primaryAccent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StoreBottomSheet extends StatefulWidget {
  final Store store;
  final VoidCallback onClose;

  const _StoreBottomSheet({required this.store, required this.onClose});

  @override
  State<_StoreBottomSheet> createState() => _StoreBottomSheetState();
}

class _StoreBottomSheetState extends State<_StoreBottomSheet> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  bool _openedDetail = false;

  @override
  void initState() {
    super.initState();

    _sheetController.addListener(() {
      if (_sheetController.size >= 0.98 && !_openedDetail) {
        _openedDetail = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoreDetailScreen(store: widget.store),
            ),
          ).then((_) {
            _openedDetail = false;

            if (_sheetController.isAttached) {
              _sheetController.animateTo(
                0.32,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
              );
            }
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.32,
      minChildSize: 0.26,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.32, 1.0],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0D0D0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const _MapRecommendBadge(),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(
                      Icons.close,
                      size: 28,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 20,
                    color: AppColors.primaryAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.store.benefitDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '현재 영업 중 · ${widget.store.closeTime}에 영업 종료',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSub,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '1.2km',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSub,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapRecommendBadge extends StatelessWidget {
  const _MapRecommendBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.badge,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primaryAccent),
      ),
      child: const Text(
        '밀집추천',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.badgeText,
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
