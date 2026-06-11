import '../models/store.dart';
import 'api_client.dart';

class StorePageResult {
  final List<Store> content;
  final bool hasNext;

  const StorePageResult({required this.content, required this.hasNext});
}

class StoreApi {
  static Future<StorePageResult> getList({
    int page = 0,
    int size = 20,
    String? category,
    double? lat,
    double? lng,
    double? radius,
    String? keyword,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };

    if (category != null && category.isNotEmpty) {
      query['category'] = category;
    }

    if (lat != null && lng != null) {
      query['lat'] = lat.toString();
      query['lng'] = lng.toString();
    }

    if (radius != null && lat != null && lng != null) {
      query['radius'] = radius.toString();
    }

    if (keyword != null && keyword.isNotEmpty) {
      query['keyword'] = keyword;
    }

    final queryString = Uri(queryParameters: query).query;
    final data = await ApiClient.get('/stores?$queryString');

    final content = data['content'] as List<dynamic>? ?? [];
    final stores = content
        .map((json) => Store.fromJson(json as Map<String, dynamic>))
        .toList();

    return StorePageResult(
      content: stores,
      hasNext: data['hasNext'] == true,
    );
  }

  static Future<Store> getDetail(int id) async {
    final data = await ApiClient.get('/stores/$id');

    return Store.fromJson(data as Map<String, dynamic>);
  }
}
