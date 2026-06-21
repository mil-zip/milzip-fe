// 플랫폼별 HTTP 클라이언트 선택: 웹은 withCredentials 클라이언트, 그 외 기본.
export 'http_client_stub.dart'
    if (dart.library.js_interop) 'http_client_web.dart';
