import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

const double _defaultLat = 37.9162;
const double _defaultLng = 127.1948;
const String _defaultAddress = '포천시 신북읍';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  double _lat = _defaultLat;
  double _lng = _defaultLng;
  String _address = _defaultAddress;

  /// 위치가 변경될 때마다 값이 증가합니다. 화면에서 addListener로 구독하세요.
  final locationNotifier = ValueNotifier<int>(0);

  double get lat => _lat;
  double get lng => _lng;
  String get address => _address;

  Position get position => Position(
        latitude: _lat,
        longitude: _lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

  Future<void> initialize() async {
    // 기본값(포천시 신북읍)으로 초기화
  }

  void useDefault() {
    _lat = _defaultLat;
    _lng = _defaultLng;
    _address = _defaultAddress;
    locationNotifier.value++;
  }

  void setLocation({
    required double lat,
    required double lng,
    required String address,
  }) {
    _lat = lat;
    _lng = lng;
    _address = address;
    locationNotifier.value++;
  }

  /// GPS로 현재 위치를 가져와 반환합니다. 실패 시 예외를 던집니다.
  Future<String> useCurrentGPS() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('위치 서비스가 비활성화되어 있습니다.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 없습니다.');
    }

    // 실제 현재 위치 요청 (network/cell 기반)
    // timeLimit은 일부 Android 기기에서 즉시 실패하므로 Dart 타임아웃만 사용
    final LocationSettings locationSettings =
        defaultTargetPlatform == TargetPlatform.android
            ? AndroidSettings(
                accuracy: LocationAccuracy.lowest,
                forceLocationManager: true, // Google Play Services 없이도 동작
              )
            : const LocationSettings(accuracy: LocationAccuracy.lowest);

    debugPrint('[GPS] getCurrentPosition 시작 (accuracy=lowest)');
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception(
          '위치를 가져오는 데 시간이 초과되었습니다.\n위치 서비스가 켜져 있는지 확인해주세요.'),
    );

    debugPrint('[GPS] 좌표 취득 성공: lat=${pos.latitude}, lng=${pos.longitude}, accuracy=${pos.accuracy}m');

    _lat = pos.latitude;
    _lng = pos.longitude;
    _address = await _reverseGeocode(pos.latitude, pos.longitude);
    debugPrint('[GPS] 역지오코딩 결과: $_address');
    debugPrint('[GPS] locationNotifier 발행 → 화면 갱신 트리거');
    locationNotifier.value++;
    return _address;
  }

  /// 주소 문자열로 검색하여 위치 목록을 반환합니다. (백엔드 Kakao 프록시)
  Future<List<({String address, double lat, double lng})>> searchByQuery(
      String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final uri = Uri.parse('${ApiClient.baseUrl}/location/geocode')
        .replace(queryParameters: {'query': trimmed});
    final res = await http.get(uri).timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) return [];
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] != true) return [];

    final list = (body['data'] as List).cast<Map<String, dynamic>>();
    return list
        .take(5)
        .map((e) => (
              address: e['address'] as String,
              lat: (e['lat'] as num).toDouble(),
              lng: (e['lng'] as num).toDouble(),
            ))
        .toList();
  }

  /// 좌표 → 한국어 주소 (백엔드 Kakao 프록시)
  static Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
          '${ApiClient.baseUrl}/location/reverse-geocode?lat=$lat&lng=$lng');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final address = (body['data'] as Map<String, dynamic>)['address'];
          if (address is String && address.isNotEmpty) return address;
        }
      }
    } catch (_) {}
    return '현재 위치';
  }
}
