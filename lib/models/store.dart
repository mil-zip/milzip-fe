import 'package:kakao_map_plugin/kakao_map_plugin.dart';

enum StoreCategory { food, cafe, leisure, accommodation, etc, tmo }

class StoreBenefit {
  final int id;
  final String description;
  final int? discountRate;
  final String? conditionText;

  const StoreBenefit({
    required this.id,
    required this.description,
    this.discountRate,
    this.conditionText,
  });

  factory StoreBenefit.fromJson(Map<String, dynamic> json) {
    return StoreBenefit(
      id: json['id'] ?? 0,
      description: json['description'] ?? '',
      discountRate: json['discountRate'],
      conditionText: json['conditionText'],
    );
  }
}

class Store {
  final int id;
  final String name;
  final StoreCategory category;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final int? viewCount;
  final String? openTime;
  final String? closeTime;
  final String? closeDate;
  final int? maxDiscountRate;
  final double? distanceKm;
  final List<String> imageUrls;
  final List<StoreBenefit> benefits;
  final bool militaryBenefit;
  final bool benefitVerified;

  const Store({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.viewCount,
    this.openTime,
    this.closeTime,
    this.closeDate,
    this.maxDiscountRate,
    this.distanceKm,
    this.imageUrls = const [],
    this.benefits = const [],
    this.militaryBenefit = false,
    this.benefitVerified = false,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: _parseCategory(json['category']),
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      phone: json['phone'],
      viewCount: json['viewCount'],
      openTime: json['openTime'],
      closeTime: json['closeTime'],
      closeDate: json['closeDate'],
      maxDiscountRate: json['maxDiscountRate'],
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      imageUrls:
          (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      benefits:
          (json['benefits'] as List<dynamic>?)
              ?.map((e) => StoreBenefit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      militaryBenefit: json['militaryBenefit'] ?? false,
      benefitVerified: json['benefitVerified'] ?? false,
    );
  }

  static StoreCategory _parseCategory(dynamic value) {
    switch (value) {
      case 'FOOD':
        return StoreCategory.food;
      case 'CAFE':
        return StoreCategory.cafe;
      case 'LEISURE':
        return StoreCategory.leisure;
      case 'ACCOMMODATION':
        return StoreCategory.accommodation;
      case 'ETC':
        return StoreCategory.etc;
      case 'TMO':
        return StoreCategory.tmo;
      default:
        return StoreCategory.etc;
    }
  }

  LatLng get latLng => LatLng(latitude, longitude);

  String get categoryLabel {
    switch (category) {
      case StoreCategory.food:
        return '음식';
      case StoreCategory.cafe:
        return '카페';
      case StoreCategory.leisure:
        return '레저';
      case StoreCategory.accommodation:
        return '숙박';
      case StoreCategory.etc:
        return '서비스';
      case StoreCategory.tmo:
        return 'TMO';
    }
  }

  String get categoryApiValue {
    switch (category) {
      case StoreCategory.food:
        return 'FOOD';
      case StoreCategory.cafe:
        return 'CAFE';
      case StoreCategory.leisure:
        return 'LEISURE';
      case StoreCategory.accommodation:
        return 'ACCOMMODATION';
      case StoreCategory.etc:
        return 'ETC';
      case StoreCategory.tmo:
        return 'TMO';
    }
  }

  String get phoneLabel =>
      phone == null || phone!.trim().isEmpty ? '전화번호 없음' : phone!;

  String get businessHours {
    if (openTime == null || closeTime == null) {
      return '운영시간 없음';
    }

    return '${_trimSeconds(openTime!)} ~ ${_trimSeconds(closeTime!)}';
  }

  String get closeTimeLabel {
    if (closeTime == null) return '영업 종료 시간 없음';
    return '${_trimSeconds(closeTime!)}에 영업 종료';
  }

  String get distanceLabel {
    final distance = distanceKm;

    if (distance == null) return '';

    if (distance < 1) {
      return '${(distance * 1000).round()}m';
    }

    if (distance < 10) {
      return '${distance.toStringAsFixed(1)}km';
    }

    return '${distance.round()}km';
  }

  String get mainBenefitDescription {
    if (benefits.isNotEmpty) {
      return benefits.first.description;
    }

    if (maxDiscountRate != null) {
      return '이용금액의 $maxDiscountRate% 할인';
    }

    return '군장병 혜택 제공';
  }

  static String _trimSeconds(String value) {
    final parts = value.split(':');

    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }

    return value;
  }
}
