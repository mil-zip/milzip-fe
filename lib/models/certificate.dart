class Certificate {
  final int id;
  final String examName;
  final int originalPrice;
  final int discountPrice;
  final int discountRate;
  final String eligibility;
  final String requiredDoc;

  Certificate({
    required this.id,
    required this.examName,
    required this.originalPrice,
    required this.discountPrice,
    required this.discountRate,
    required this.eligibility,
    required this.requiredDoc,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: (json['id'] as num?)?.toInt() ?? 0,
      examName: json['exam_name'],
      originalPrice: json['original_price'],
      discountPrice: json['discount_price'],
      discountRate: json['discount_rate'],
      eligibility: json['eligibility'],
      requiredDoc: json['required_doc'],
    );
  }

  String get originalPriceLabel => '${_formatPrice(originalPrice)}원';
  String get discountPriceLabel => '${_formatPrice(discountPrice)}원';
  String get discountRateLabel => '$discountRate% 할인';

  static String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }
}
