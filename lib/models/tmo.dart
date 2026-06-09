import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class Tmo {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final String locationDescription;
  final bool mobile;
  final String? note;
  final String? phone;
  final String? weekdayStartTime;
  final String? weekdayEndTime;
  final String? weekendStartTime;
  final String? weekendEndTime;

  const Tmo({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.locationDescription,
    required this.mobile,
    this.note,
    this.phone,
    this.weekdayStartTime,
    this.weekdayEndTime,
    this.weekendStartTime,
    this.weekendEndTime,
  });

  factory Tmo.fromJson(Map<String, dynamic> json) {
    return Tmo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      locationDescription: json['locationDescription'] ?? '',
      mobile: json['mobile'] ?? false,
      note: json['note'],
      phone: json['phone'],
      weekdayStartTime: json['weekdayStartTime'],
      weekdayEndTime: json['weekdayEndTime'],
      weekendStartTime: json['weekendStartTime'],
      weekendEndTime: json['weekendEndTime'],
    );
  }

  LatLng get latLng => LatLng(latitude, longitude);

  String get distanceLabel {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    }
    return '${distanceKm.toStringAsFixed(distanceKm >= 10 ? 0 : 1)}km';
  }

  String get phoneLabel => phone ?? '전화번호 없음';

  String get todayHours {
    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    final start = isWeekend ? weekendStartTime : weekdayStartTime;
    final end = isWeekend ? weekendEndTime : weekdayEndTime;

    if (start == null || end == null) {
      return mobile ? '출장형 운영' : '운영 시간 확인 필요';
    }

    return '$start ~ $end';
  }

  String get weekdayHours {
    if (weekdayStartTime == null || weekdayEndTime == null) {
      return mobile ? '출장형 운영' : '운영 시간 확인 필요';
    }
    return '$weekdayStartTime ~ $weekdayEndTime';
  }

  String get weekendHours {
    if (weekendStartTime == null || weekendEndTime == null) {
      return '주말 운영 정보 없음';
    }
    return '$weekendStartTime ~ $weekendEndTime';
  }

  bool get hasTodayOperatingHours {
    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    final start = isWeekend ? weekendStartTime : weekdayStartTime;
    final end = isWeekend ? weekendEndTime : weekdayEndTime;

    return start != null && end != null;
  }

  bool get isOpenNow {
    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    final startText = isWeekend ? weekendStartTime : weekdayStartTime;
    final endText = isWeekend ? weekendEndTime : weekdayEndTime;

    if (startText == null || endText == null) return false;

    final start = _parseTime(startText);
    final end = _parseTime(endText);

    if (start == null || end == null) return false;

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (endMinutes < startMinutes) {
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  String get operatingStatusLabel {
    if (!hasTodayOperatingHours) {
      return mobile ? '출장형' : '운영 확인';
    }

    return isOpenNow ? '운영 중' : '운영 종료';
  }

  String get kakaoMapUrl {
    final encodedName = Uri.encodeComponent(name);
    return 'https://map.kakao.com/link/map/$encodedName,$latitude,$longitude';
  }

  static ({int hour, int minute})? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    return (hour: hour, minute: minute);
  }
}
