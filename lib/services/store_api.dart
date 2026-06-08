import '../models/store.dart';
import 'api_client.dart';

class StoreApi {
  static Future<List<Store>> getList({
    int page = 0,
    int size = 20,
    String? category,
    double? lat,
    double? lng,
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

    final queryString = Uri(queryParameters: query).query;
    final data = await ApiClient.get('/stores?$queryString');

    final content = data['content'] as List<dynamic>? ?? [];

    return content
        .map((json) => Store.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Store>> searchByKeyword({
    required String keyword,
    String? category,
    double? lat,
    double? lng,
    int size = 100,
    int maxPages = 20,
  }) async {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      return const [];
    }

    final results = <Store>[];
    var page = 0;
    var hasNext = true;

    while (hasNext && page < maxPages) {
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

      final queryString = Uri(queryParameters: query).query;
      final data = await ApiClient.get('/stores?$queryString');

      final content = data['content'] as List<dynamic>? ?? [];
      final stores = content
          .map((json) => Store.fromJson(json as Map<String, dynamic>))
          .toList();

      results.addAll(
        stores.where((store) {
          return store.name.contains(trimmedKeyword) ||
              store.address.contains(trimmedKeyword) ||
              store.categoryLabel.contains(trimmedKeyword);
        }),
      );

      hasNext = data['hasNext'] == true;
      page += 1;
    }

    return results;
  }

  static Future<Store> getDetail(int id) async {
    final data = await ApiClient.get('/stores/$id');

    return Store.fromJson(data as Map<String, dynamic>);
  }
}
