class StoreReviewDraft {
  final String verificationMethod;
  final String benefitAnswer;
  final String waitTimeAnswer;
  final String purposeAnswer;
  final String companionAnswer;
  final double rating;
  final List<String> goodPoints;

  const StoreReviewDraft({
    required this.verificationMethod,
    required this.benefitAnswer,
    required this.waitTimeAnswer,
    required this.purposeAnswer,
    required this.companionAnswer,
    required this.rating,
    required this.goodPoints,
  });

  String get benefitSentence {
    switch (benefitAnswer) {
      case '혜택 받음':
        return '군장병 혜택 받았어요!';
      case '혜택 받지 못함':
        return '군장병 혜택을 받지 못했어요.';
      case '일부 받음':
        return '군장병 혜택을 일부 받았어요.';
      default:
        return benefitAnswer;
    }
  }
}

class SubmittedStoreReview {
  final StoreReviewDraft draft;
  final String content;
  final List<String> imagePaths;
  final DateTime createdAt;
  final String nickname;

  const SubmittedStoreReview({
    required this.draft,
    required this.content,
    required this.imagePaths,
    required this.createdAt,
    this.nickname = '나',
  });
}
