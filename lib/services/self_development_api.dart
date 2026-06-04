import 'api_client.dart';

/// 자기계발 혜택 페이지네이션 응답
class SelfDevelopmentPage {
  final List<Map<String, dynamic>> content;
  final bool hasNext;
  final int pageNum;
  final int totalElements;
  final int totalPages;

  SelfDevelopmentPage({
    required this.content,
    required this.hasNext,
    required this.pageNum,
    required this.totalElements,
    required this.totalPages,
  });
}

class SelfDevelopmentApi {
  /// 자기계발 혜택 목록 (페이지네이션)
  static Future<SelfDevelopmentPage> getList({
    int page = 0,
    int size = 5,
    String? category,
  }) async {
    final query = StringBuffer('/benefits/self-developments?page=$page&size=$size');
    if (category != null && category.isNotEmpty) {
      query.write('&category=${Uri.encodeQueryComponent(category)}');
    }

    final path = query.toString();
    // Temporary debug log for device-side API tracing.
    // ignore: avoid_print
    print('[self-dev-api] GET $path');

    final data = await ApiClient.get(
      path,
    );
    final map = data as Map<String, dynamic>;
    return SelfDevelopmentPage(
      content: List<Map<String, dynamic>>.from(map['content'] ?? []),
      hasNext: map['hasNext'] ?? false,
      pageNum: map['pageNum'] ?? 0,
      totalElements: map['totalElements'] ?? 0,
      totalPages: map['totalPages'] ?? 1,
    );
  }
}
