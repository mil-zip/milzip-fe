import 'package:flutter/widgets.dart';

/// 지도에 표시할 마커 데이터 (플랫폼 독립)
class WebMarker {
  final String id;
  final double lat;
  final double lng;
  const WebMarker({required this.id, required this.lat, required this.lng});
}

/// 모바일(비-웹) 빌드용 스텁. 웹에서만 실제 구현이 사용된다.
class WebKakaoMap extends StatelessWidget {
  final double lat;
  final double lng;
  final int level;
  final List<WebMarker> markers;
  final void Function(String id)? onMarkerTap;
  final VoidCallback? onMapTap;
  final double? focusLat;
  final double? focusLng;
  final int focusLevel;

  const WebKakaoMap({
    super.key,
    required this.lat,
    required this.lng,
    this.level = 5,
    this.markers = const [],
    this.onMarkerTap,
    this.onMapTap,
    this.focusLat,
    this.focusLng,
    this.focusLevel = 3,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
