class QuickStore {
  final int id;
  final String name;
  final String category;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final int maxDiscountRate;
  final int viewCount;
  final String openTime;
  final String closeTime;
  final double? distanceKm;
  final int? travelTimeMinutes;
  final String? travelMode;
  final List<String> imageUrls;
  final bool militaryBenefit;
  final bool benefitVerified;

  const QuickStore({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    required this.maxDiscountRate,
    required this.viewCount,
    required this.openTime,
    required this.closeTime,
    this.distanceKm,
    this.travelTimeMinutes,
    this.travelMode,
    required this.imageUrls,
    required this.militaryBenefit,
    required this.benefitVerified,
  });

  factory QuickStore.fromJson(Map<String, dynamic> json) {
    return QuickStore(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'ETC',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      phone: json['phone'] as String?,
      maxDiscountRate: (json['maxDiscountRate'] as num?)?.toInt() ?? 0,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      openTime: json['openTime'] as String? ?? '',
      closeTime: json['closeTime'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      travelTimeMinutes: (json['travelTimeMinutes'] as num?)?.toInt(),
      travelMode: json['travelMode'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      militaryBenefit: json['militaryBenefit'] as bool? ?? false,
      benefitVerified: json['benefitVerified'] as bool? ?? false,
    );
  }
}

class QuickStorePage {
  final List<QuickStore> content;
  final int totalElements;
  final int totalPages;
  final int pageNum;
  final int pageSize;
  final bool last;
  final bool hasNext;

  const QuickStorePage({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.pageNum,
    required this.pageSize,
    required this.last,
    required this.hasNext,
  });

  factory QuickStorePage.fromJson(Map<String, dynamic> json) {
    return QuickStorePage(
      content: (json['content'] as List<dynamic>?)
              ?.map((e) => QuickStore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      pageNum: (json['pageNum'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
      last: json['last'] as bool? ?? false,
      hasNext: json['hasNext'] as bool? ?? false,
    );
  }
}
