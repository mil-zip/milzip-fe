import 'package:kakao_map_plugin/kakao_map_plugin.dart';

enum StoreCategory { food, lodging, pc, service, tmo }

class Store {
  final int id;
  final String name;
  final StoreCategory category;
  final String categoryDetail;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String openTime;
  final String closeTime;
  final String menu;
  final String benefitDescription;
  final int? discountRate;
  final bool isMilitaryBenefit;
  final bool isBenefitVerified;
  final List<String> imageUrls;
  final double? distanceKm;

  const Store({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryDetail,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.openTime,
    required this.closeTime,
    required this.menu,
    required this.benefitDescription,
    this.discountRate,
    required this.isMilitaryBenefit,
    required this.isBenefitVerified,
    this.imageUrls = const [],
    this.distanceKm,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'],
      category: _parseCategory(json['category']),
      categoryDetail: json['category_detail'],
      address: json['address'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'],
      openTime: json['open_time'],
      closeTime: json['close_time'],
      menu: json['menu'],
      benefitDescription: json['benefit_description'],
      discountRate: json['discount_rate'],
      isMilitaryBenefit: json['is_military_benefit'] ?? false,
      isBenefitVerified: json['is_benefit_verified'] ?? false,
    );
  }

  static StoreCategory _parseCategory(String value) {
    switch (value) {
      case 'FOOD':
        return StoreCategory.food;
      case 'LODGING':
        return StoreCategory.lodging;
      case 'PC':
        return StoreCategory.pc;
      case 'SERVICE':
        return StoreCategory.service;
      case 'TMO':
        return StoreCategory.tmo;
      default:
        return StoreCategory.service;
    }
  }

  LatLng get latLng => LatLng(latitude, longitude);

  String get categoryLabel {
    switch (category) {
      case StoreCategory.food:
        return '음식';
      case StoreCategory.lodging:
        return '숙박';
      case StoreCategory.pc:
        return 'PC방';
      case StoreCategory.service:
        return '서비스';
      case StoreCategory.tmo:
        return 'TMO';
    }
  }

  String get businessHours => '$openTime ~ $closeTime';
}
