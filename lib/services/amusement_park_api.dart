import 'api_client.dart';

/// 놀이공원 혜택 API
class AmusementParkApi {
  /// 놀이공원 혜택 목록 조회
  static Future<List<Map<String, dynamic>>> getList() async {
    final data = await ApiClient.get('/benefits/amusement-parks');
    return List<Map<String, dynamic>>.from(data);
  }
}
