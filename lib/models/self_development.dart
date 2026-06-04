class SelfDevelopment {
  final int id;
  final String title;
  final String category;
  final String description;
  final String supportType;
  final String? imageUrl;
  final String applyUrl;
  bool isBookmarked;

  SelfDevelopment({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.supportType,
    required this.applyUrl,
    this.imageUrl,
    this.isBookmarked = false,
  });

  factory SelfDevelopment.fromApi(Map<String, dynamic> json) {
    return SelfDevelopment(
      id: json['id'] ?? 0,
      title: _clean(json['title'] ?? ''),
      category: json['category'] ?? '',
      description: _clean(json['description'] ?? ''),
      supportType: _clean(json['supportType'] ?? ''),
      applyUrl: json['applyUrl'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }

  /// 안 보이는 유니코드 결합 문자 → 일반 사각형으로 치환
  static String _clean(String text) {
    return text
        // U+20DE 결합 사각형(앞 글자 덮어씀, 단독으로 안 그려짐) → ■
        .replaceAll('⃞', '■');
  }
}
