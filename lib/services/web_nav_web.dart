import 'package:web/web.dart' as web;

/// 전체 페이지 리다이렉트 (OAuth 진입용)
void webRedirect(String url) {
  web.window.location.href = url;
}

/// 현재 브라우저 URL의 경로를 쿼리 없이 교체 (히스토리 정리)
void webReplacePath(String path) {
  web.window.history.replaceState(null, '', path);
}
