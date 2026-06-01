import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class BenefitMapScreen extends StatefulWidget {
  const BenefitMapScreen({super.key});

  @override
  State<BenefitMapScreen> createState() => _BenefitMapScreenState();
}

class _BenefitMapScreenState extends State<BenefitMapScreen> {
  KakaoMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  final LatLng _defaultCenter = LatLng(37.5665, 126.9780);
  final LatLng _fallbackCenter = LatLng(37.95745120515425, 127.3174892339337);

  final List<String> _categories = ['음식', '숙박', 'PC방', '서비스', 'TMO'];
  String _selectedCategory = '음식';

  bool _permissionDialogShown = false;

  @override
  void initState() {
    super.initState();

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
                    color: Color(0xFF111111),
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
          center: _defaultCenter,
          currentLevel: 7,
          zoomControl: true,
          mapTypeControl: false,
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),

        Positioned(
          top: 22,
          left: 24,
          right: 24,
          child: Column(
            children: [
              _MapSearchField(controller: _searchController),
              const SizedBox(height: 14),
              _CategoryChipBar(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onSelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
            ],
          ),
        ),

        Positioned(
          right: 18,
          bottom: 24,
          child: FloatingActionButton.small(
            heroTag: 'current_location',
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF222222),
            elevation: 3,
            onPressed: _requestLocationPermission,
            child: const Icon(Icons.my_location_outlined),
          ),
        ),
      ],
    );
  }
}

class _MapSearchField extends StatelessWidget {
  final TextEditingController controller;

  const _MapSearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: '검색하기',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF222222)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.94),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF222222), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF00C878), width: 2),
        ),
      ),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                color: selected ? const Color(0xFF00C878) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF00C878), width: 2),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : const Color(0xFF00C878),
                ),
              ),
            ),
          );
        },
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
            color: Color(0xFF333333),
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
          foregroundColor: Colors.black,
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
