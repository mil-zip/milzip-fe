import '../models/store_review.dart';
import 'api_client.dart';

class StoreReviewApi {
  static Future<StoreReviewPage> getList({
    required int storeId,
    int page = 0,
    int size = 10,
  }) async {
    final data = await ApiClient.get(
      '/stores/$storeId/reviews?page=$page&size=$size',
    );

    return StoreReviewPage.fromJson(data as Map<String, dynamic>);
  }
}
