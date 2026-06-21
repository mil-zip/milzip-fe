import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// 지도에 표시할 마커 데이터 (플랫폼 독립)
class WebMarker {
  final String id;
  final double lat;
  final double lng;
  const WebMarker({required this.id, required this.lat, required this.lng});
}

@JS('milzipMapInit')
external void _milzipMapInit(String id, double lat, double lng, int level);
@JS('milzipMapSetCenter')
external void _milzipMapSetCenter(String id, double lat, double lng);
@JS('milzipMapSetLevel')
external void _milzipMapSetLevel(String id, int level);
@JS('milzipMapSetMarkers')
external void _milzipMapSetMarkers(String id, String markersJson);
@JS('milzipMapReady')
external bool _milzipMapReady();

@JS('milzipOnMarkerTap')
external set _milzipOnMarkerTap(JSFunction f);

@JS('milzipOnMapTap')
external set _milzipOnMapTap(JSFunction f);

int _instanceCounter = 0;

/// 카카오맵 JavaScript SDK 기반 웹 전용 지도 위젯
class WebKakaoMap extends StatefulWidget {
  final double lat;
  final double lng;
  final int level;
  final List<WebMarker> markers;
  final void Function(String id)? onMarkerTap;
  final VoidCallback? onMapTap;

  /// 특정 위치로 지도를 이동시키고 싶을 때 지정 (값이 바뀌면 이동)
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
  State<WebKakaoMap> createState() => _WebKakaoMapState();
}

class _WebKakaoMapState extends State<WebKakaoMap> {
  late final String _viewType;
  late final String _divId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final n = _instanceCounter++;
    _viewType = 'milzip-kakao-map-$n';
    _divId = 'milzip-kakao-div-$n';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final div = web.document.createElement('div') as web.HTMLDivElement;
      div.id = _divId;
      div.style.width = '100%';
      div.style.height = '100%';
      div.style.backgroundColor = '#e8efe9'; // 진단용 배경 (플랫폼 뷰 확인)
      return div;
    });

    // 마커 클릭 → Dart 콜백 브리지
    _milzipOnMarkerTap = ((JSString id) {
      widget.onMarkerTap?.call(id.toDart);
    }).toJS;

    // 지도 빈 곳 클릭 → Dart 콜백 브리지
    _milzipOnMapTap = (() {
      widget.onMapTap?.call();
    }).toJS;

    WidgetsBinding.instance.addPostFrameCallback((_) => _tryInit(0));
  }

  void _tryInit(int attempt) {
    if (!mounted || _initialized) return;

    final el = web.document.getElementById(_divId);
    bool ready = false;
    try {
      ready = _milzipMapReady();
    } catch (_) {
      ready = false;
    }

    if (el != null && ready) {
      // ignore: avoid_print
      print('[WebKakaoMap] init OK ($_divId) lat=${widget.lat} lng=${widget.lng}');
      _milzipMapInit(_divId, widget.lat, widget.lng, widget.level);
      _milzipMapSetMarkers(_divId, _markersJson());
      _initialized = true;
      return;
    }

    if (attempt < 40) {
      Future.delayed(
        const Duration(milliseconds: 150),
        () => _tryInit(attempt + 1),
      );
    } else {
      // ignore: avoid_print
      print('[WebKakaoMap] init FAILED — el=${el != null} kakaoReady=$ready');
    }
  }

  String _markersJson() {
    return jsonEncode(
      widget.markers
          .map((m) => {'id': m.id, 'lat': m.lat, 'lng': m.lng})
          .toList(),
    );
  }

  bool _sameMarkers(List<WebMarker> a, List<WebMarker> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant WebKakaoMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_initialized) return;

    if (oldWidget.lat != widget.lat || oldWidget.lng != widget.lng) {
      _milzipMapSetCenter(_divId, widget.lat, widget.lng);
    }
    if (oldWidget.level != widget.level) {
      _milzipMapSetLevel(_divId, widget.level);
    }
    // focus 좌표가 바뀌면 해당 위치로 이동 + 확대
    if (widget.focusLat != null &&
        widget.focusLng != null &&
        (oldWidget.focusLat != widget.focusLat ||
            oldWidget.focusLng != widget.focusLng)) {
      _milzipMapSetLevel(_divId, widget.focusLevel);
      _milzipMapSetCenter(_divId, widget.focusLat!, widget.focusLng!);
    }
    if (!_sameMarkers(oldWidget.markers, widget.markers)) {
      _milzipMapSetMarkers(_divId, _markersJson());
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
