import 'package:milzip/models/ai_recommend_result.dart';
import 'package:milzip/services/api_client.dart';

class AiRecommendApi {
  static Future<AiRecommendResult> fetch({
    required String freeText,
    String? companion,
    List<String>? categories,
    double? lat,
    double? lng,
  }) async {
    final body = <String, dynamic>{
      'freeText': freeText,
      if (companion != null) 'companion': companion,
      if (categories != null && categories.isNotEmpty) 'categories': categories,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
    final data = await ApiClient.post('/recommendations/ai', body: body);
    return AiRecommendResult.fromJson(data as Map<String, dynamic>);
  }
}
