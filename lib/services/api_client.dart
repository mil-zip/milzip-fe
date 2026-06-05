import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// API 공통 설정 — baseUrl, 공통 헤더, 응답 파싱
class ApiClient {
  static const String baseUrl = 'https://api.milzip.site';

  /// GET 요청 후 data 필드 반환
  static Future<dynamic> get(String path) async {
    http.Response response;
    final uri = Uri.parse('$baseUrl$path');

    try {
      response = await http.get(uri).timeout(const Duration(seconds: 10));
    } on SocketException catch (e) {
      throw Exception('네트워크 연결에 실패했습니다: ${e.message}');
    } on HandshakeException catch (e) {
      throw Exception('보안 연결에 실패했습니다: $e');
    } on TimeoutException {
      throw Exception('요청 시간이 초과되었습니다: $uri');
    }

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return body['data'];
      } else {
        throw Exception(body['message'] ?? 'API 요청 실패');
      }
    } else {
      throw Exception('서버 오류: ${response.statusCode}');
    }
  }
}
