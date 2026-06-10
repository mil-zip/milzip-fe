import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:milzip/main.dart';
import 'package:milzip/screens/login_screen.dart';
import 'package:milzip/services/auth_service.dart';


/// API 공통 설정 — baseUrl, 공통 헤더, 응답 파싱
class ApiClient {
  static const String baseUrl = 'https://api.milzip.site';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// GET 요청 — 실패 시 최대 3회 재시도
  static Future<dynamic> get(String path, {int maxRetries = 3}) async {
    final uri = Uri.parse('$baseUrl$path');
    Exception? lastError;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .get(uri, headers: await _headers())
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body['success'] == true) return body['data'];
          throw Exception(body['message'] ?? 'API 요청 실패');
        } else if (response.statusCode == 401 && attempt == 1) {
          // 토큰 만료 시 1회 갱신 후 재시도
          try {
            await AuthService.refreshTokens();
          } catch (_) {
            // 갱신 실패 → 로그인 화면으로
            await AuthService.clearTokens();
            _goToLogin();
            throw Exception('세션이 만료되었습니다. 다시 로그인해 주세요.');
          }
          continue;
        } else if (response.statusCode == 403) {
          throw Exception('접근 권한이 없습니다.');
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
        await Future.delayed(Duration(seconds: attempt));
      }
    }

    throw lastError!;
  }

  /// POST 요청
  static Future<dynamic> post(
    String path, {
    required Map<String, dynamic> body,
    int maxRetries = 2,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    Exception? lastError;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              uri,
              headers: await _headers(),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          if (decoded['success'] == true) return decoded['data'];
          throw Exception(decoded['message'] ?? 'API 요청 실패');
        } else if ((response.statusCode == 401 || response.statusCode == 403) && attempt == 1) {
          // PUBLIC_URLS 경로에서 만료된 토큰은 403으로 오는 경우가 있어 함께 처리
          try {
            await AuthService.refreshTokens();
          } catch (_) {
            await AuthService.clearTokens();
            _goToLogin();
            throw Exception('세션이 만료되었습니다. 다시 로그인해 주세요.');
          }
          continue;
        } else if (response.statusCode == 403) {
          throw Exception('접근 권한이 없습니다.');
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
        await Future.delayed(Duration(seconds: attempt));
      }
    }

    throw lastError!;
  }

  /// PUT 요청
  static Future<dynamic> put(
    String path, {
    required Map<String, dynamic> body,
    int maxRetries = 2,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    Exception? lastError;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .put(
              uri,
              headers: await _headers(),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          if (decoded['success'] == true) return decoded['data'];
          throw Exception(decoded['message'] ?? 'API 요청 실패');
        } else if ((response.statusCode == 401 || response.statusCode == 403) && attempt == 1) {
          try {
            await AuthService.refreshTokens();
          } catch (_) {
            await AuthService.clearTokens();
            _goToLogin();
            throw Exception('세션이 만료되었습니다. 다시 로그인해 주세요.');
          }
          continue;
        } else if (response.statusCode == 403) {
          throw Exception('접근 권한이 없습니다.');
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
        await Future.delayed(Duration(seconds: attempt));
      }
    }

    throw lastError!;
  }

  /// DELETE 요청
  static Future<dynamic> delete(String path, {int maxRetries = 2}) async {
    final uri = Uri.parse('$baseUrl$path');
    Exception? lastError;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .delete(uri, headers: await _headers())
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200 || response.statusCode == 204) {
          if (response.body.isEmpty) return null;
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          if (decoded['success'] == true) return decoded['data'];
          throw Exception(decoded['message'] ?? 'API 요청 실패');
        } else if ((response.statusCode == 401 || response.statusCode == 403) && attempt == 1) {
          try {
            await AuthService.refreshTokens();
          } catch (_) {
            await AuthService.clearTokens();
            _goToLogin();
            throw Exception('세션이 만료되었습니다. 다시 로그인해 주세요.');
          }
          continue;
        } else if (response.statusCode == 403) {
          throw Exception('접근 권한이 없습니다.');
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
        await Future.delayed(Duration(seconds: attempt));
      }
    }

    throw lastError!;
  }

  static void _goToLogin() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
