import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// API 공통 설정 — baseUrl, 공통 헤더, 응답 파싱
class ApiClient {
  static const String baseUrl = 'https://api.milzip.site';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static http.Client _newClient() {
    final inner = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..badCertificateCallback = (cert, host, port) => true;
    return http.Client()..hashCode; // fallback to default if IOClient unavailable
  }

  /// GET 요청 — 실패 시 최대 3회 재시도
  static Future<dynamic> get(String path, {int maxRetries = 3}) async {
    final uri = Uri.parse('$baseUrl$path');
    Exception? lastError;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body['success'] == true) return body['data'];
          throw Exception(body['message'] ?? 'API 요청 실패');
        } else {
          throw Exception('서버 오류: ${response.statusCode}');
        }
      } on SocketException catch (e) {
        lastError = Exception('네트워크 연결 실패: ${e.message}');
      } on HandshakeException catch (e) {
        lastError = Exception('보안 연결 실패: $e');
      } on TimeoutException {
        lastError = Exception('요청 시간 초과');
      } catch (e) {
        lastError = Exception('$e');
      }

      // ignore: avoid_print
      print('[api] attempt $attempt/$maxRetries failed for $uri → $lastError');

      if (attempt < maxRetries) {
        await Future.delayed(Duration(seconds: attempt)); // 1s, 2s 대기 후 재시도
      }
    }

    throw lastError!;
  }
}
