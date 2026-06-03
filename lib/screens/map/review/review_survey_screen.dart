import 'package:flutter/material.dart';

import '../../../models/store.dart';
import '../../../models/store_review_draft.dart';
import 'review_submit_screen.dart';

class ReviewSurveyScreen extends StatefulWidget {
  final Store store;
  final String verificationMethod;

  const ReviewSurveyScreen({
    super.key,
    required this.store,
    required this.verificationMethod,
  });

  @override
  State<ReviewSurveyScreen> createState() => _ReviewSurveyScreenState();
}

class _ReviewSurveyScreenState extends State<ReviewSurveyScreen> {
  String? benefitAnswer;
  String? waitTimeAnswer;
  String? purposeAnswer;
  String? companionAnswer;
  double rating = 0;
  final Set<String> goodPoints = {};

  bool get canSubmit =>
      benefitAnswer != null &&
      waitTimeAnswer != null &&
      purposeAnswer != null &&
      companionAnswer != null &&
      rating > 0 &&
      goodPoints.isNotEmpty;

  void _complete() {
    if (!canSubmit) return;

    final draft = StoreReviewDraft(
      verificationMethod: widget.verificationMethod,
      benefitAnswer: benefitAnswer!,
      waitTimeAnswer: waitTimeAnswer!,
      purposeAnswer: purposeAnswer!,
      companionAnswer: companionAnswer!,
      rating: rating,
      goodPoints: goodPoints.toList(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewSubmitScreen(
          store: widget.store,
          draft: draft,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goodPointOptions = [
      '음식이 맛있어요',
      '양이 많아요',
      '가성비가 좋아요',
      '혼밥하기 좋아요',
      '단체로 오기 좋아요',
      '조용하고 좋아요',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(34, 10, 34, 18),
        child: Align(
          alignment: Alignment.centerRight,
          heightFactor: 1,
          child: ElevatedButton(
            onPressed: canSubmit ? _complete : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8FE0A6),
              disabledBackgroundColor: const Color(0xFFE5E5E5),
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '선택 완료',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 28),
                  ),
                  const Spacer(),
                  const Icon(Icons.star_border, size: 36),
                  const SizedBox(width: 18),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 36),
                  ),
                ],
              ),
            ),
            _QuestionBlock(
              title: '군인 할인 혜택 또는 관련 혜택을 받으셨나요?',
              options: const ['혜택 받음', '혜택 받지 못함', '일부 받음'],
              selected: benefitAnswer,
              onSelected: (value) => setState(() => benefitAnswer = value),
            ),
            if (benefitAnswer != null)
              _QuestionBlock(
                title: '대기 시간은 어떠셨나요?',
                options: const ['바로 입장', '30분 이내', '1시간 이내', '1시간 이상'],
                selected: waitTimeAnswer,
                onSelected: (value) => setState(() => waitTimeAnswer = value),
              ),
            if (waitTimeAnswer != null)
              _QuestionBlock(
                title: '방문하신 목적은 무엇인가요?',
                options: const ['데이트', '외출', '휴가', '회식'],
                selected: purposeAnswer,
                onSelected: (value) => setState(() => purposeAnswer = value),
              ),
            if (purposeAnswer != null)
              _QuestionBlock(
                title: '누구와 함께했나요?',
                options: const ['애인', '혼자', '동기', '선후임'],
                selected: companionAnswer,
                onSelected: (value) => setState(() => companionAnswer = value),
              ),
            if (companionAnswer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(34, 28, 34, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '얼마나 만족하셨나요?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _HalfStarRating(
                      rating: rating,
                      onChanged: (value) => setState(() => rating = value),
                    ),
                  ],
                ),
              ),
            if (rating > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(34, 20, 34, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '어떤 점이 좋았나요?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: goodPointOptions.map((option) {
                        final selected = goodPoints.contains(option);
                        return _PinkChoiceChip(
                          label: option,
                          selected: selected,
                          onTap: () {
                            setState(() {
                              selected
                                  ? goodPoints.remove(option)
                                  : goodPoints.add(option);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuestionBlock extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _QuestionBlock({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(34, 26, 34, 28),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 14,
            children: options.map((option) {
              final isSelected = selected == option;
              return _GreenChoiceChip(
                label: option,
                selected: isSelected,
                onTap: () => onSelected(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _GreenChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GreenChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE9FFF4) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF00C878) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _PinkChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PinkChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF6F89) : const Color(0xFFFFE6EA),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFFE93055) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _HalfStarRating extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onChanged;

  const _HalfStarRating({
    required this.rating,
    required this.onChanged,
  });

  void _updateRating(BuildContext context, Offset localPosition) {
    final box = context.findRenderObject() as RenderBox;
    final width = box.size.width;
    final value = (localPosition.dx / width * 5).clamp(0.5, 5.0);
    onChanged((value * 2).ceil() / 2);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _updateRating(context, details.localPosition),
      onHorizontalDragUpdate: (details) =>
          _updateRating(context, details.localPosition),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (index) {
          final starValue = index + 1;
          final filled = rating >= starValue;
          final halfFilled = rating >= starValue - 0.5 && rating < starValue;

          return Icon(
            halfFilled ? Icons.star_half : Icons.star,
            size: 54,
            color: filled || halfFilled
                ? const Color(0xFFFF5A4F)
                : const Color(0xFFF0F0F0),
          );
        }),
      ),
    );
  }
}