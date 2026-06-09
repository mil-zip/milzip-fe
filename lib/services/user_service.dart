import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:milzip/services/auth_service.dart';

class UserService {
  static const String _baseUrl = 'https://api.milzip.site';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getAccessToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// PATCH /users/me/nickname — 닉네임 변경
  static Future<void> updateNickname(String nickname) async {
    final token = await AuthService.getAccessToken();
    final response = await http
        .patch(
          Uri.parse('$_baseUrl/users/me/nickname?nickname=${Uri.encodeComponent(nickname)}'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 12));
    _checkStatus(response, '닉네임 변경 실패');
    // 로컬 캐시 갱신
    final info = await AuthService.getUserInfo();
    await AuthService.saveUserInfo(
      email: info['email'] ?? '',
      nickname: nickname,
      militaryStatus: info['militaryStatus'] ?? 'NOT_VERIFIED',
      profileImageUrl: info['profileImageUrl'],
    );
  }

  /// GET /users/me — 내 정보 조회 + 로컬 저장
  static Future<Map<String, dynamic>> getMyInfo() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/users/me'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 12));

    _checkStatus(response, '내 정보 조회 실패');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] ?? body) as Map<String, dynamic>;

    // 로컬 캐시 갱신
    await AuthService.saveUserInfo(
      email: data['email'] ?? '',
      nickname: data['nickname'] ?? '',
      militaryStatus: (data['militaryStatus'] as String?) ?? 'NOT_VERIFIED',
      profileImageUrl: data['profileImageUrl'] as String?,
    );
    return data;
  }

  /// GET /users/favorites — 즐겨찾기 목록
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/users/favorites'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 12));

    _checkStatus(response, '즐겨찾기 조회 실패');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['data'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// POST /users/favorites/{storeId} — 즐겨찾기 추가
  static Future<void> addFavorite(int storeId) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/users/favorites/$storeId'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 12));
    _checkStatus(response, '즐겨찾기 추가 실패');
  }

  // ── 혜택 즐겨찾기 ─────────────────────────────────────

  /// GET /users/favorites/benefits — 저장한 혜택 목록
  static Future<List<Map<String, dynamic>>> getBenefitFavorites() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/users/favorites/benefits'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 12));
    _checkStatus(response, '저장한 혜택 조회 실패');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['data'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// POST /users/favorites/benefits/{benefitId} — 혜택 즐겨찾기 추가
  static Future<void> addBenefitFavorite(int benefitId) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/users/favorites/benefits/$benefitId'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 12));
    _checkStatus(response, '혜택 즐겨찾기 추가 실패');
  }

  /// DELETE /users/favorites/benefits/{benefitId} — 혜택 즐겨찾기 해제
  static Future<void> removeBenefitFavorite(int benefitId) async {
    final response = await http
        .delete(
          Uri.parse('$_baseUrl/users/favorites/benefits/$benefitId'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 12));
    _checkStatus(response, '혜택 즐겨찾기 해제 실패');
  }

  // ── TMO 즐겨찾기 ──────────────────────────────────────

  /// GET /users/favorites/tmos — 저장한 TMO 목록
  static Future<List<Map<String, dynamic>>> getTmoFavorites() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/users/favorites/tmos'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 12));
    _checkStatus(response, 'TMO 즐겨찾기 조회 실패');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['data'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// POST /users/favorites/tmos/{tmoId} — TMO 즐겨찾기 추가
  static Future<void> addTmoFavorite(int tmoId) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/users/favorites/tmos/$tmoId'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 12));
    _checkStatus(response, 'TMO 즐겨찾기 추가 실패');
  }

  /// DELETE /users/favorites/tmos/{tmoId} — TMO 즐겨찾기 해제
  static Future<void> removeTmoFavorite(int tmoId) async {
    final response = await http
        .delete(
          Uri.parse('$_baseUrl/users/favorites/tmos/$tmoId'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 12));
    _checkStatus(response, 'TMO 즐겨찾기 해제 실패');
  }

  /// DELETE /users/favorites/{storeId} — 즐겨찾기 해제
  static Future<void> removeFavorite(int storeId) async {
    final response = await http
        .delete(
          Uri.parse('$_baseUrl/users/favorites/$storeId'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 12));
    _checkStatus(response, '즐겨찾기 해제 실패');
  }

  /// GET /users/reviews — 내 리뷰 목록
  static Future<List<Map<String, dynamic>>> getMyReviews({int page = 0, int size = 10}) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/users/reviews?page=$page&size=$size'),
          headers: await _authHeaders(),
        )
        .timeout(const Duration(seconds: 12));

    _checkStatus(response, '내 리뷰 조회 실패');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final list = data['content'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// PATCH /users/me/profile-image — 프로필 이미지 변경
  static Future<Map<String, dynamic>> updateProfileImage(Uint8List imageBytes) async {
    final token = await AuthService.getAccessToken();
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$_baseUrl/users/me/profile-image'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'profileImage',
      imageBytes,
      filename: 'profile.jpg',
    ));

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    _checkStatus(response, '프로필 이미지 변경 실패');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] ?? body) as Map<String, dynamic>;

    // 로컬 캐시 갱신
    await AuthService.saveUserInfo(
      email: data['email'] ?? '',
      nickname: data['nickname'] ?? '',
      militaryStatus: (data['militaryStatus'] as String?) ?? 'NOT_VERIFIED',
      profileImageUrl: data['profileImageUrl'] as String?,
    );
    return data;
  }

  static void _checkStatus(http.Response response, String fallback) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? fallback);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('$fallback (${response.statusCode})');
    }
  }
}
