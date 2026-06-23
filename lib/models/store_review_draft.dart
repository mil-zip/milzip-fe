import 'package:image_picker/image_picker.dart';

class StoreReviewDraft {
  final String verificationMethod;
  final String benefitAnswer;   // 군인만 사용, 일반 유저는 ''
  final String visitTypeAnswer;
  final String waitTimeAnswer;
  final String purposeAnswer;
  final String companionAnswer;
  final double rating;
  final List<String> goodPoints; // 한글 표시 레이블로 저장

  const StoreReviewDraft({
    required this.verificationMethod,
    required this.benefitAnswer,
    required this.visitTypeAnswer,
    required this.waitTimeAnswer,
    required this.purposeAnswer,
    required this.companionAnswer,
    required this.rating,
    required this.goodPoints,
  });

  // ── 표시용 문장 ──────────────────────────────────────────

  String get benefitSentence {
    switch (benefitAnswer) {
      case '혜택 받음':
        return '군장병 혜택 받았어요!';
      case '혜택 받지 못함':
        return '군장병 혜택을 받지 못했어요.';
      case '일부 받음':
        return '군장병 혜택을 일부 받았어요.';
      default:
        return '';
    }
  }

  // ── API enum 변환 ─────────────────────────────────────────

  String get benefitStatusEnum {
    switch (benefitAnswer) {
      case '혜택 받음':   return 'RECEIVED';
      case '혜택 받지 못함': return 'NOT_RECEIVED';
      case '일부 받음':  return 'PARTIAL';
      default:           return '';
    }
  }

  String get visitTypeEnum {
    switch (visitTypeAnswer) {
      case '예약 없이 이용':  return 'WALK_IN';
      case '예약 후 이용':    return 'RESERVED';
      case '포장·배달 이용': return 'TAKEOUT_DELIVERY';
      default:                return 'WALK_IN';
    }
  }

  String get waitTimeEnum {
    switch (waitTimeAnswer) {
      case '바로 입장':   return 'IMMEDIATE';
      case '10분 이내':  return 'WITHIN_10_MIN';
      case '30분 이내':  return 'WITHIN_30_MIN';
      case '1시간 이내': return 'WITHIN_1_HOUR';
      case '1시간 이상': return 'OVER_1_HOUR';
      default:            return 'IMMEDIATE';
    }
  }

  String get visitPurposeEnum {
    switch (purposeAnswer) {
      case '데이트': return 'DATE';
      case '외출':   return 'OUTING';
      case '외박':   return 'OVERNIGHT_PASS';
      case '휴가':   return 'VACATION';
      case '회식':   return 'GATHERING';
      default:        return 'OUTING';
    }
  }

  String get visitWithEnum {
    switch (companionAnswer) {
      case '연인': return 'COUPLE';
      case '가족': return 'FAMILY';
      case '친구': return 'FRIEND';
      case '혼자': return 'ALONE';
      default:      return 'ALONE';
    }
  }

  List<String> get goodPointEnums {
    const mapping = {
      '음식이 맛있어요':    'TASTY',
      '양이 많아요':        'LARGE_PORTION',
      '가성비가 좋아요':    'GOOD_VALUE',
      '혼밥하기 좋아요':   'GOOD_FOR_SOLO',
      '단체로 오기 좋아요': 'GOOD_FOR_GROUPS',
      '조용하고 좋아요':   'QUIET',
      '식당 분위기가 좋아요': 'GOOD_ATMOSPHERE',
      '웨이팅이 없어요':   'NO_WAITING',
      '할인율이 높아요':   'HIGH_DISCOUNT',
    };
    return goodPoints.map((p) => mapping[p] ?? p).toList();
  }
}

class SubmittedStoreReview {
  final StoreReviewDraft draft;
  final String content;
  final List<XFile> imageFiles;
  final DateTime createdAt;
  final String nickname;

  const SubmittedStoreReview({
    required this.draft,
    required this.content,
    required this.imageFiles,
    required this.createdAt,
    this.nickname = '나',
  });

  bool get isMilitaryUser {
    if (draft.benefitAnswer.isNotEmpty) return true;
    final p = draft.purposeAnswer;
    return p == '외출' || p == '외박' || p == '휴가';
  }
}
