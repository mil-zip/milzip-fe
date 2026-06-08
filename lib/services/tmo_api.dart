import '../models/tmo.dart';
import 'api_client.dart';

class TmoApi {
  static Future<List<Tmo>> getList({
    required double lat,
    required double lng,
  }) async {
    final data = await ApiClient.get('/benefits/tmo?lat=$lat&lng=$lng');

    return List<Map<String, dynamic>>.from(data).map(Tmo.fromJson).toList();
  }
}
