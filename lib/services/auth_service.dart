import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'http_client.dart';
import 'web_nav.dart';

class AuthService {
  static const String _baseUrl = 'https://api.milzip.site';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _emailKey = 'user_email';
  static const String _nicknameKey = 'user_nickname';
  static const String _militaryStatusKey = 'user_military_status';
  static const String _profileImageUrlKey = 'user_profile_image_url';

  // ── 토큰 관리 ──────────────────────────────────────────

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── 유저 정보 관리 ─────────────────────────────────────

  static Future<void> saveUserInfo({
    required String email,
    required String nickname,
    required String militaryStatus,
    String? profileImageUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    await prefs.setString(_nicknameKey, nickname);
    await prefs.setString(_militaryStatusKey, militaryStatus);
    if (profileImageUrl != null) {
      await prefs.setString(_profileImageUrlKey, profileImageUrl);
    }
  }

  static Future<Map<String, String?>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_emailKey),
      'nickname': prefs.getString(_nicknameKey),
      'militaryStatus': prefs.getString(_militaryStatusKey),
      'profileImageUrl': prefs.getString(_profileImageUrlKey),
    };
  }

  static Future<String?> getStoredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  /// GET /users/me — 내 정보 조회 후 로컬 저장
  static Future<Map<String, dynamic>> fetchAndSaveMyInfo() async {
    final token = await getAccessToken();
    final response = await http
        .get(
          Uri.parse('$_baseUrl/users/me'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 12));

    _checkStatus(response, '사용자 정보 조회 실패');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] ?? body) as Map<String, dynamic>;

    await saveUserInfo(
      email: data['email'] ?? '',
      nickname: data['nickname'] ?? '',
      militaryStatus: data['militaryStatus'] ?? data['military_status'] ?? 'NOT_VERIFIED',
      profileImageUrl: data['profileImageUrl'] ?? data['profile_image_url'],
    );
    return data;
  }

  // ── API 호출 ──────────────────────────────────────────

  // ── 군인 인증 ─────────────────────────────────────────

  /// POST /military/verifications — 군인 인증 1차 요청 (카카오톡 발송)
  static Future<void> requestMilitaryVerification({
    required String identity,
    required String phoneNo,
    required String addrSido,
    required String addrSigungu,
  }) async {
    final token = await getAccessToken();
    final response = await http
        .post(
          Uri.parse('$_baseUrl/military/verifications'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'identity': identity,
            'phoneNo': phoneNo,
            'addrSido': addrSido,
            'addrSigungu': addrSigungu,
          }),
        )
        .timeout(const Duration(seconds: 30));
    _checkStatus(response, '군인 인증 요청 실패');
  }

  /// POST /military/verifications/confirm — 군인 인증 2차 확인
  static Future<void> confirmMilitaryVerification() async {
    final token = await getAccessToken();
    final response = await http
        .post(
          Uri.parse('$_baseUrl/military/verifications/confirm'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 30));
    _checkStatus(response, '군인 인증 확인 실패');
  }

  /// GET /users/nickname/availability — 닉네임 사용 가능 여부 (true: 사용 가능)
  static Future<bool> checkNicknameAvailability(String nickname) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/users/nickname/availability?nickname=${Uri.encodeComponent(nickname)}'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 409) return false;
    if (response.statusCode == 200) return true;
    _checkStatus(response, '닉네임 확인 실패');
    return false;
  }

  /// GET /users/email/availability — 이메일 사용 가능 여부 (true: 사용 가능)
  static Future<bool> checkEmailAvailability(String email) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/users/email/availability?email=${Uri.encodeComponent(email)}'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 409) return false;
    if (response.statusCode == 200) return true;
    _checkStatus(response, '이메일 확인 실패');
    return false;
  }

  /// POST /auth/email-verifications — 이메일 인증 코드 발송
  static Future<void> sendEmailVerification(String email) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/email-verifications'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 12));

    _checkStatus(response, '인증번호 발송 실패');
  }

  /// PATCH /auth/email-verifications — 이메일 인증 코드 확인
  static Future<void> verifyEmailCode(String email, String code) async {
    final response = await http
        .patch(
          Uri.parse('$_baseUrl/auth/email-verifications'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'code': code}),
        )
        .timeout(const Duration(seconds: 12));

    _checkStatus(response, '인증번호 확인 실패');
  }

  /// POST /auth/register — 회원가입 (multipart/form-data)
  static Future<void> register({
    required String email,
    required String password,
    required String nickname,
    required String name,
    Uint8List? profileImageBytes,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/auth/register'),
    );

    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['nickname'] = nickname;
    request.fields['name'] = name;

    if (profileImageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'profileImage',
        profileImageBytes,
        filename: 'profile.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    _checkStatus(response, '회원가입 실패');
  }

  /// POST /auth/logout — 로그아웃 후 로컬 토큰 삭제
  static Future<void> logout() async {
    final token = await getAccessToken();
    try {
      await http.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // 서버 오류여도 로컬 토큰은 반드시 삭제
    }
    await clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_nicknameKey);
    await prefs.remove(_militaryStatusKey);
    await prefs.remove(_profileImageUrlKey);
  }

  /// GET /auth/kakao — 카카오 OAuth 로그인
  ///
  /// - 웹: 전체 페이지를 `/auth/kakao?platform=web`로 리다이렉트한다.
  ///   (이후 `https://milzip.site/auth/callback?accessToken=...`로 돌아오며,
  ///    돌아온 뒤 [handleWebKakaoCallback]에서 토큰을 저장한다.)
  /// - 앱: flutter_web_auth_2로 커스텀 스킴 콜백을 받아 토큰을 저장한다.
  static Future<void> kakaoLogin() async {
    if (kIsWeb) {
      // 페이지가 이동하므로 이 함수는 정상 반환되지 않는다.
      webRedirect('$_baseUrl/auth/kakao?platform=web');
      return;
    }

    final result = await FlutterWebAuth2.authenticate(
      url: '$_baseUrl/auth/kakao?platform=app',
      callbackUrlScheme: 'milzip',
    );

    final uri = Uri.parse(result);

    if (uri.queryParameters.containsKey('error')) {
      throw Exception('카카오 로그인에 실패했습니다.');
    }

    final accessToken = uri.queryParameters['accessToken'];
    final refreshToken = uri.queryParameters['refreshToken'];

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('카카오 로그인에 실패했습니다.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  /// 웹 카카오 로그인 콜백 처리 결과
  /// - [success]: 토큰 저장 성공 여부
  /// - [needsName]: 본명 입력 필요 여부 (신규 유저)
  /// - [error]: 실패 메시지 (있으면 실패)

  /// 웹에서 `/auth/callback?accessToken=...&needsName=...` 으로 돌아왔을 때 호출.
  /// URL에서 토큰을 파싱·저장하고, 주소창을 정리한다.
  /// refreshToken은 httpOnly 쿠키에 있으므로 파싱하지 않는다.
  ///
  /// 반환: 'home' | 'name' | 'error' | 'none'
  static Future<String> handleWebKakaoCallback() async {
    if (!kIsWeb) return 'none';

    final uri = Uri.base;
    if (!uri.path.contains('/auth/callback')) return 'none';

    final params = uri.queryParameters;

    // 주소창에서 토큰 등 민감 정보 제거
    webReplacePath('/');

    if (params.containsKey('error')) {
      return 'error';
    }

    final accessToken = params['accessToken'];
    if (accessToken == null || accessToken.isEmpty) {
      return 'error';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);

    final needsName = params['needsName'] == 'true';
    return needsName ? 'name' : 'home';
  }

  /// PATCH /users/me/name — 카카오 최초 가입 유저 본명 등록
  static Future<void> updateName(String name) async {
    final token = await getAccessToken();
    final response = await http
        .patch(
          Uri.parse('$_baseUrl/users/me/name?name=${Uri.encodeComponent(name)}'),
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 12));
    _checkStatus(response, '이름 저장 실패');
  }

  /// POST /auth/login — 로그인 후 토큰 저장
  static Future<void> login(String email, String password) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 12));

    _checkStatus(response, '로그인 실패');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] ?? body) as Map<String, dynamic>;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, data['accessToken'] ?? data['access_token'] ?? '');
    await prefs.setString(_emailKey, email);

    // Set-Cookie 헤더에서 refreshToken 추출 후 저장
    final rawCookie = response.headers['set-cookie'] ?? '';
    final cookieMatch = RegExp(r'refreshToken=([^;,\s]+)').firstMatch(rawCookie);
    if (cookieMatch != null) {
      await prefs.setString(_refreshTokenKey, cookieMatch.group(1)!);
    }
  }

  // ── 비밀번호 재설정 ───────────────────────────────────

  /// POST /auth/password-resets/verifications — 비밀번호 재설정 인증코드 발송
  static Future<void> sendPasswordResetCode(String email) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/password-resets/verifications'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 12));
    _checkStatus(response, '인증코드 발송 실패');
  }

  /// PATCH /auth/password-resets/verifications — 인증코드 확인
  static Future<void> verifyPasswordResetCode(String email, String code) async {
    final response = await http
        .patch(
          Uri.parse('$_baseUrl/auth/password-resets/verifications'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'code': code}),
        )
        .timeout(const Duration(seconds: 12));
    _checkStatus(response, '인증코드 확인 실패');
  }

  /// PUT /auth/password-resets — 비밀번호 변경 (email + newPassword)
  static Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/auth/password-resets'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'newPassword': newPassword}),
        )
        .timeout(const Duration(seconds: 12));
    _checkStatus(response, '비밀번호 변경 실패');
  }

  /// POST /auth/tokens/refresh — 액세스 토큰 갱신
  ///
  /// - 웹: refreshToken은 httpOnly 쿠키에 있으므로, withCredentials 클라이언트로
  ///   요청하면 브라우저가 쿠키를 자동 전송한다. (Cookie 헤더 수동 설정 X)
  /// - 앱: prefs에 저장된 refreshToken을 Cookie 헤더로 보낸다.
  static Future<void> refreshTokens() async {
    final prefs = await SharedPreferences.getInstance();

    late final http.Response response;

    if (kIsWeb) {
      final client = createCredentialedClient();
      try {
        response = await client
            .post(
              Uri.parse('$_baseUrl/auth/tokens/refresh'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 12));
      } finally {
        client.close();
      }
    } else {
      final refreshToken = prefs.getString(_refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        throw Exception('세션이 만료되었습니다.');
      }
      response = await http
          .post(
            Uri.parse('$_baseUrl/auth/tokens/refresh'),
            headers: {
              'Content-Type': 'application/json',
              'Cookie': 'refreshToken=$refreshToken',
            },
          )
          .timeout(const Duration(seconds: 12));
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      await clearTokens();
      throw Exception('세션이 만료되었습니다.');
    }

    _checkStatus(response, '토큰 갱신 실패');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] ?? body) as Map<String, dynamic>;
    await prefs.setString(_accessTokenKey, data['accessToken'] ?? data['access_token'] ?? '');

    // 앱: 새 refreshToken 쿠키 저장 (웹은 브라우저가 쿠키를 자동 갱신)
    if (!kIsWeb) {
      final rawCookie = response.headers['set-cookie'] ?? '';
      final cookieMatch = RegExp(r'refreshToken=([^;,\s]+)').firstMatch(rawCookie);
      if (cookieMatch != null) {
        await prefs.setString(_refreshTokenKey, cookieMatch.group(1)!);
      }
    }
  }

  // ── 공통 헬퍼 ─────────────────────────────────────────

  static void _checkStatus(http.Response response, String fallbackMessage) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? fallbackMessage);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('$fallbackMessage (${response.statusCode})');
    }
  }
}
