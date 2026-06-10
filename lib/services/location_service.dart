import 'package:geolocator/geolocator.dart';

// 포천시 신북읍 중심 좌표 (데이터 밀집 최다 지점)
const double _fixedLat = 37.9162;
const double _fixedLng = 127.1948;
const String _fixedAddress = '포천시 신북읍';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Position? _position;
  String _address = '위치 확인 중...';

  Position? get position => _position;
  String get address => _address;

  Future<void> initialize() async {
    _position = Position(
      latitude: _fixedLat,
      longitude: _fixedLng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    _address = _fixedAddress;
    // ignore: avoid_print
    print('[location] fixed position: $_fixedLat, $_fixedLng ($_fixedAddress)');
  }

}
