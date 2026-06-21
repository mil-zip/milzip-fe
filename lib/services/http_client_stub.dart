import 'package:http/http.dart' as http;

/// 비-웹: 기본 클라이언트 (쿠키 개념 없음)
http.Client createCredentialedClient() => http.Client();
