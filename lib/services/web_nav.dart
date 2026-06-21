// 플랫폼별 구현 선택: 웹에서는 브라우저 navigation, 그 외에는 스텁.
export 'web_nav_stub.dart'
    if (dart.library.js_interop) 'web_nav_web.dart';
