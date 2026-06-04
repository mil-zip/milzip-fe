import 'package:flutter/material.dart';

// 영화관 할인 종류
enum TheaterDiscountType { amount, voucher }

class Theater {
  final int id;
  final String brand;
  final String benefit;
  final String requiredDocument;
  final TheaterDiscountType discountType;
  final String externalLink;
  bool isBookmarked;

  Theater({
    required this.id,
    required this.brand,
    required this.benefit,
    required this.requiredDocument,
    required this.discountType,
    required this.externalLink,
    this.isBookmarked = false,
  });

  factory Theater.fromJson(Map<String, dynamic> json) {
    return Theater(
      id: json['id'],
      brand: json['theater_brand'],
      benefit: json['benefit'],
      requiredDocument: json['required_document'],
      discountType: _parseDiscountType(json['discount_type']),
      externalLink: json['external_link'] ?? '',
    );
  }

  /// 실제 API 응답용
  factory Theater.fromApi(Map<String, dynamic> json) {
    return Theater(
      id: json['id'] ?? 0,
      brand: json['cinemaChain'] ?? '',
      benefit: json['description'] ?? '',
      requiredDocument: '나라사랑카드',
      discountType: TheaterDiscountType.amount,
      externalLink: '',
    );
  }

  /// 브랜드별 로고 에셋 이미지
  String? get logoAsset {
    switch (brand) {
      case 'CGV':
        return 'assets/images/cgv_logo.png';
      case '롯데시네마':
        return 'assets/images/lotte_logo.png';
      case '메가박스':
        return 'assets/images/megabox_logo.jpg';
      default:
        return null;
    }
  }

  static TheaterDiscountType _parseDiscountType(String value) {
    switch (value) {
      case 'AMOUNT':
        return TheaterDiscountType.amount;
      case 'VOUCHER':
        return TheaterDiscountType.voucher;
      default:
        return TheaterDiscountType.amount;
    }
  }

  // 브랜드별 로고 색상 - 나중에 assets 이미지 사용 시 교체 가능
  Color get brandColor {
    switch (brand) {
      case 'CGV':
        return const Color(0xFFE60012);
      case '롯데시네마':
        return const Color(0xFFE40521);
      case '메가박스':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF555555);
    }
  }

  // 로고 표시 텍스트 (이미지 없을 때 사용)
  String get logoText {
    switch (brand) {
      case 'CGV':
        return 'CGV';
      case '롯데시네마':
        return 'LOTTE\nCINEMA';
      case '메가박스':
        return 'MEGABOX';
      default:
        return brand;
    }
  }
}
