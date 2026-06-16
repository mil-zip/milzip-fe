import 'package:flutter/material.dart';
import 'package:milzip/services/location_service.dart';
import 'package:milzip/theme/app_colors.dart';

class LocationPickerSheet extends StatefulWidget {
  final void Function(String address) onLocationSelected;

  const LocationPickerSheet({super.key, required this.onLocationSelected});

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final _searchController = TextEditingController();
  bool _isLoadingGPS = false;
  bool _isSearching = false;
  List<({String address, double lat, double lng})> _searchResults = [];
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onGPSTap() async {
    setState(() {
      _isLoadingGPS = true;
      _errorMessage = null;
    });
    try {
      final address = await LocationService.instance.useCurrentGPS();
      if (mounted) widget.onLocationSelected(address);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingGPS = false);
    }
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });
    try {
      final results = await LocationService.instance.searchByQuery(query);
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = '검색 결과를 불러오지 못했습니다.');
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectResult(({String address, double lat, double lng}) result) {
    LocationService.instance.setLocation(
      lat: result.lat,
      lng: result.lng,
      address: result.address,
    );
    widget.onLocationSelected(result.address);
  }

  void _selectDefault() {
    LocationService.instance.useDefault();
    widget.onLocationSelected('포천시 신북읍');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Material(
          color: Colors.white,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 핸들 + 타이틀
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '지역 선택',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.textSub,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 기본 위치 버튼
            _ListTileOption(
              icon: Icons.home_outlined,
              label: '포천시 신북읍',
              badge: '기본',
              onTap: _selectDefault,
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),

            // 현재 위치 버튼
            _ListTileOption(
              icon: Icons.my_location_rounded,
              label: '현재 위치 사용',
              trailing: _isLoadingGPS
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryAccent,
                      ),
                    )
                  : null,
              onTap: _isLoadingGPS ? null : _onGPSTap,
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),

            // 검색창
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _onSearch,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '지역명 검색 (예: 동두천시, 의정부시)',
                          hintStyle: const TextStyle(
                              fontSize: 14, color: AppColors.textSub),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 20,
                            color: AppColors.textSub,
                          ),
                          suffixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryAccent,
                                    ),
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSearching
                          ? null
                          : () => _onSearch(_searchController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        elevation: 0,
                      ),
                      child: const Text(
                        '검색',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 오류 메시지
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),

            // 검색 결과
            if (_searchResults.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, i) =>
                      const Divider(height: 1, indent: 20, endIndent: 20),
                  itemBuilder: (_, i) {
                    final r = _searchResults[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.textSub,
                      ),
                      title: Text(
                        r.address,
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () => _selectResult(r),
                    );
                  },
                ),
              ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
        ),
      ),
    );
  }
}

class _ListTileOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ListTileOption({
    required this.icon,
    required this.label,
    this.badge,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 20, color: AppColors.textSub),
      title: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textMain,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: trailing,
    );
  }
}
