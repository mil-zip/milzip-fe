import '../models/store.dart';

/// 세션 만료(리프레시 토큰까지 만료)로 재로그인이 필요한 경우
class AuthExpiredException implements Exception {
  const AuthExpiredException();
}

/// 로그인 후 되돌아갈 매장 정보를 임시 보관
class PendingNavigation {
  PendingNavigation._();
  static Store? returnStore;
}
