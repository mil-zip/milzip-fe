import 'api_client.dart';

/// 영화·영화관 혜택 API
class MovieApi {
  /// 영화 박스오피스 목록
  static Future<List<Map<String, dynamic>>> getBoxOffice() async {
    final data = await ApiClient.get('/benefits/movies/boxoffice');
    return List<Map<String, dynamic>>.from(data);
  }

  /// 영화관별 혜택 목록 (CGV, 메가박스, 롯데시네마)
  static Future<List<Map<String, dynamic>>> getCinemas() async {
    final data = await ApiClient.get('/benefits/movies');
    return List<Map<String, dynamic>>.from(data);
  }
}
