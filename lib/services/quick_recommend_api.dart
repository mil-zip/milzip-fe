import 'package:milzip/models/quick_store.dart';
import 'package:milzip/services/api_client.dart';

class QuickRecommendApi {
  static Future<QuickStorePage> fetch({
    double? lat,
    double? lng,
    String? category,
    String sortBy = 'recommend',
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'size': '$size',
      'sortBy': sortBy,
      if (lat != null) 'lat': '$lat',
      if (lng != null) 'lng': '$lng',
      if (category != null) 'category': category,
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final data = await ApiClient.get('/recommendations/quick?$query');
    return QuickStorePage.fromJson(data as Map<String, dynamic>);
  }
}
