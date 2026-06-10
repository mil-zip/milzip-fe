class StoreReviewPage {
  final List<StoreReview> content;
  final bool hasNext;
  final bool last;
  final int pageNum;
  final int pageSize;
  final int totalElements;
  final int totalPages;

  const StoreReviewPage({
    required this.content,
    required this.hasNext,
    required this.last,
    required this.pageNum,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
  });

  factory StoreReviewPage.fromJson(Map<String, dynamic> json) {
    final contentJson = json['content'] as List<dynamic>? ?? [];

    return StoreReviewPage(
      content: contentJson
          .map((item) => StoreReview.fromJson(item as Map<String, dynamic>))
          .toList(),
      hasNext: json['hasNext'] ?? false,
      last: json['last'] ?? true,
      pageNum: json['pageNum'] ?? 0,
      pageSize: json['pageSize'] ?? 10,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

class StoreReview {
  final int id;
  final int storeId;
  final int userId;
  final String nickname;
  final String? profileImageUrl;
  final double rating;
  final String? benefitStatus;
  final String? visitType;
  final String? waitTime;
  final String? visitPurpose;
  final String? visitWith;
  final List<String> goodPoints;
  final String content;
  final String status;
  final List<String> imageUrls;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  const StoreReview({
    required this.id,
    required this.storeId,
    required this.userId,
    required this.nickname,
    required this.rating,
    required this.goodPoints,
    required this.content,
    required this.status,
    required this.imageUrls,
    this.profileImageUrl,
    this.benefitStatus,
    this.visitType,
    this.waitTime,
    this.visitPurpose,
    this.visitWith,
    this.createdAt,
    this.modifiedAt,
  });

  factory StoreReview.fromJson(Map<String, dynamic> json) {
    return StoreReview(
      id: json['id'] ?? 0,
      storeId: json['storeId'] ?? 0,
      userId: json['userId'] ?? 0,
      nickname: json['nickname'] ?? '익명',
      profileImageUrl: json['profileImageUrl'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      benefitStatus: json['benefitStatus'],
      visitType: json['visitType'],
      waitTime: json['waitTime'],
      visitPurpose: json['visitPurpose'],
      visitWith: json['visitWith'],
      goodPoints:
          (json['goodPoints'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      content: json['content'] ?? '',
      status: json['status'] ?? '',
      imageUrls:
          (json['imageUrls'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.tryParse(json['modifiedAt'])
          : null,
    );
  }

  String get createdDateLabel {
    final date = createdAt;
    if (date == null) return '';

    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String get benefitStatusLabel {
    switch (benefitStatus) {
      case 'RECEIVED':
        return '군장병 혜택 받았어요!';
      case 'NOT_RECEIVED':
        return '군장병 혜택을 받지 못했어요.';
      case 'PARTIAL':
        return '군장병 혜택을 일부 받았어요.';
      default:
        return '';
    }
  }

  String get waitTimeLabel {
    switch (waitTime) {
      case 'IMMEDIATE':
        return '바로 입장';
      case 'UNDER_30_MIN':
        return '30분 이내';
      case 'UNDER_1_HOUR':
        return '1시간 이내';
      case 'OVER_1_HOUR':
        return '1시간 이상';
      default:
        return '';
    }
  }

  String get visitPurposeLabel {
    switch (visitPurpose) {
      case 'DATE':
        return '데이트';
      case 'OUTING':
        return '외출';
      case 'VACATION':
        return '휴가';
      case 'DINING':
        return '식사';
      case 'GATHERING':
        return '회식';
      default:
        return '';
    }
  }

  String get visitWithLabel {
    switch (visitWith) {
      case 'FRIEND':
        return '친구';
      case 'COUPLE':
        return '애인';
      case 'ALONE':
        return '혼자';
      case 'COLLEAGUE':
        return '동기';
      case 'SENIOR_JUNIOR':
        return '선후임';
      default:
        return '';
    }
  }

  List<String> get goodPointLabels {
    return goodPoints.map(goodPointLabel).toList();
  }

  static String goodPointLabel(String value) {
    switch (value) {
      case 'TASTY':
        return '음식이 맛있어요';
      case 'LARGE_PORTION':
        return '양이 많아요';
      case 'GOOD_VALUE':
        return '가성비가 좋아요';
      case 'GOOD_ATMOSPHERE':
        return '식당 분위기가 좋아요';
      case 'NO_WAITING':
        return '웨이팅이 없어요';
      case 'GOOD_FOR_GROUP':
        return '단체로 오기 좋아요';
      case 'GOOD_FOR_SOLO':
        return '혼밥하기 좋아요';
      case 'QUIET':
        return '조용하고 좋아요';
      case 'HIGH_DISCOUNT':
        return '할인율이 높아요';
      default:
        return value;
    }
  }
}
