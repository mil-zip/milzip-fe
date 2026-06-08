import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Position? _position;
  String _address = '위치 확인 중...';

  Position? get position => _position;
  String get address => _address;

  Future<void> initialize() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _address = '위치 서비스 꺼짐';
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _address = '위치 권한 없음';
      return;
    }

    try {
      _position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      // ignore: avoid_print
      print('[location] position ok: ${_position!.latitude}, ${_position!.longitude}');
      await _resolveAddress();
      // ignore: avoid_print
      print('[location] address: $_address');
    } catch (e) {
      // ignore: avoid_print
      print('[location] error: $e');
      _address = '위치 불러오기 실패';
    }
  }

  Future<void> _resolveAddress() async {
    if (_position == null || kIsWeb) {
      // 웹은 geocoding 패키지 미지원
      _address = '현재 위치';
      return;
    }
    try {
      final placemarks = await placemarkFromCoordinates(
        _position!.latitude,
        _position!.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // 한국 주소: subLocality(동) → subAdministrativeArea(구) → locality(시) 순
        final dong = p.subLocality?.isNotEmpty == true
            ? p.subLocality!
            : p.subAdministrativeArea?.isNotEmpty == true
                ? p.subAdministrativeArea!
                : p.locality?.isNotEmpty == true
                    ? p.locality!
                    : null;
        _address = dong ?? '현재 위치';
      }
    } catch (e) {
      // ignore: avoid_print
      print('[location] geocoding error: $e');
      _address = '현재 위치';
    }
  }
}
