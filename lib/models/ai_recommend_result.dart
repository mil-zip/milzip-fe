class AiCourseStore {
  final int id;
  final String name;
  final String category;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? openTime;
  final String? closeTime;
  final List<String> imageUrls;
  final int? maxDiscountRate;
  final double? distanceKm;
  final String? travelMode;
  final int? travelTimeMinutes;
  final String? reason;

  const AiCourseStore({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.openTime,
    this.closeTime,
    required this.imageUrls,
    this.maxDiscountRate,
    this.distanceKm,
    this.travelMode,
    this.travelTimeMinutes,
    this.reason,
  });

  factory AiCourseStore.fromJson(Map<String, dynamic> json) {
    return AiCourseStore(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'ETC',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      phone: json['phone'] as String?,
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      maxDiscountRate: (json['maxDiscountRate'] as num?)?.toInt(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      travelMode: json['travelMode'] as String?,
      travelTimeMinutes: (json['travelTimeMinutes'] as num?)?.toInt(),
      reason: json['reason'] as String?,
    );
  }
}

class AiCourse {
  final int courseNumber;
  final String? region;
  final List<AiCourseStore> stores;

  const AiCourse({
    required this.courseNumber,
    this.region,
    required this.stores,
  });

  factory AiCourse.fromJson(Map<String, dynamic> json) {
    return AiCourse(
      courseNumber: (json['courseNumber'] as num?)?.toInt() ?? 0,
      region: json['region'] as String?,
      stores: (json['stores'] as List<dynamic>?)
              ?.map((e) => AiCourseStore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class AiRecommendResult {
  final List<AiCourse> courses;
  final List<String> missingCategories;

  const AiRecommendResult({
    required this.courses,
    required this.missingCategories,
  });

  factory AiRecommendResult.fromJson(Map<String, dynamic> json) {
    return AiRecommendResult(
      courses: (json['courses'] as List<dynamic>?)
              ?.map((e) => AiCourse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      missingCategories: (json['missingCategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}
