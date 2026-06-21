import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// 웹: 크로스 오리진 요청에 쿠키(httpOnly refreshToken)를 함께 보내는 클라이언트
http.Client createCredentialedClient() => BrowserClient()..withCredentials = true;
