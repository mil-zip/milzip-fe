// 플랫폼별 구현 선택: 웹에서는 카카오 JS SDK 지도, 그 외에는 스텁.
export 'web_kakao_map_stub.dart'
    if (dart.library.js_interop) 'web_kakao_map_web.dart';
