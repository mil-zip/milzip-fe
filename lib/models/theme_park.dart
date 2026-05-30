import 'package:flutter/material.dart';

// 할인 종류 (백엔드 discount_type과 매핑)
enum DiscountType { free, amount, percentage }

class ThemePark {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String benefit;
  final DiscountType discountType;
  final int originalPrice;
  final int discountedPrice;
  final String requiredDocument;
  final DateTime? validUntil;
  final String? imageAsset;
  bool isBookmarked;

  ThemePark({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.benefit,
    required this.discountType,
    required this.originalPrice,
    required this.discountedPrice,
    required this.requiredDocument,
    this.validUntil,
    this.imageAsset,
    this.isBookmarked = false,
  });

  // ─── JSON → ThemePark 객체 변환 ─────────────────────────────────────────
  factory ThemePark.fromJson(Map<String, dynamic> json) {
    return ThemePark(
      id: json['id'],
      name: json['themepark_name'],
      address: json['address'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      benefit: json['benefit'],
      discountType: _parseDiscountType(json['discount_type']),
      originalPrice: json['original_price'],
      discountedPrice: json['discounted_price'],
      requiredDocument: json['required_document'],
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'])
          : null,
      imageAsset: json['image_asset'],
    );
  }

  static DiscountType _parseDiscountType(String value) {
    switch (value) {
      case 'FREE':
        return DiscountType.free;
      case 'AMOUNT':
        return DiscountType.amount;
      case 'PERCENTAGE':
        return DiscountType.percentage;
      default:
        return DiscountType.amount;
    }
  }

  // ─── UI에서 쓰는 헬퍼 ────────────────────────────────────────────────────

  // 할인 라벨 ("무료", "30,000원 할인", "70%")
  String get discountLabel {
    switch (discountType) {
      case DiscountType.free:
        return '무료';
      case DiscountType.amount:
        final saved = originalPrice - discountedPrice;
        return '${_formatPrice(saved)}원 할인';
      case DiscountType.percentage:
        final rate = ((originalPrice - discountedPrice) / originalPrice * 100)
            .round();
        return '$rate%';
    }
  }

  // 주소에서 지역 추출 ("수도권", "경상권" 등)
  String get region {
    if (address.contains('서울') ||
        address.contains('경기') ||
        address.contains('인천')) {
      return '수도권';
    }
    if (address.contains('부산') ||
        address.contains('대구') ||
        address.contains('경북') ||
        address.contains('경남')) {
      return '경상권';
    }
    if (address.contains('광주') ||
        address.contains('전북') ||
        address.contains('전남')) {
      return '전라권';
    }
    if (address.contains('대전') ||
        address.contains('충북') ||
        address.contains('충남')) {
      return '충청권';
    }
    if (address.contains('강원')) return '강원권';
    if (address.contains('제주')) return '제주권';
    return '기타';
  }

  // 짧은 주소 표시 ("경기 용인" 등)
  String get shortAddress {
    final parts = address.split(' ');
    if (parts.length >= 2) {
      final province = parts[0].replaceAll(RegExp(r'(도|특별시|광역시)$'), '');
      final city = parts[1].replaceAll(RegExp(r'(시|군|구)$'), '');
      return '$province $city';
    }
    return address;
  }

  // 만료일 표시 (없으면 "연중무휴")
  String get validUntilLabel {
    if (validUntil == null) return '연중무휴';
    return '${validUntil!.year}.${validUntil!.month.toString().padLeft(2, '0')}.${validUntil!.day.toString().padLeft(2, '0')}까지';
  }

  // 카드 색상 (이미지가 없을 때 폴백 배경색)
  Color get cardColor {
    switch (id) {
      case 1:
        return const Color(0xFFD0312D);
      case 2:
        return const Color(0xFF1A3A8F);
      case 3:
        return const Color(0xFF2E7D32);
      default:
        const palette = [
          Color(0xFF8E44AD),
          Color(0xFFE67E22),
          Color(0xFF16A085),
          Color(0xFFC0392B),
        ];
        return palette[id % palette.length];
    }
  }

  // 가격을 1,000 단위 콤마 처리
  static String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  // 인스턴스용 포맷터 (UI에서 사용)
  String formatPrice(int price) => _formatPrice(price);
}
