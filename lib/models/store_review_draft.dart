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
}
