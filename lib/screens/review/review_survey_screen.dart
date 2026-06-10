import 'package:flutter/material.dart';

import '../../models/store.dart';
import '../../models/store_review_draft.dart';
import '../../theme/app_colors.dart';
import 'review_submit_screen.dart';

class ReviewSurveyScreen extends StatefulWidget {
  final Store store;
  final String verificationMethod;
  final bool isMilitary;

  const ReviewSurveyScreen({
    super.key,
    required this.store,
    required this.verificationMethod,
    this.isMilitary = false,
  });

  @override
  State<ReviewSurveyScreen> createState() => _ReviewSurveyScreenState();
}

class _ReviewSurveyScreenState extends State<ReviewSurveyScreen> {
  final ScrollController _scrollController = ScrollController();

  String? benefitAnswer;
  String? visitTypeAnswer;
  String? waitTimeAnswer;
  String? purposeAnswer;
  String? companionAnswer;
  double rating = 0;
  final Set<String> goodPoints = {};

  bool get canSubmit =>
      (widget.isMilitary ? benefitAnswer != null : true) &&
      visitTypeAnswer != null &&
      waitTimeAnswer != null &&
      purposeAnswer != null &&
      companionAnswer != null &&
      rating > 0 &&
      goodPoints.isNotEmpty;

  void _autoAdvance() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _complete() async {
    if (!canSubmit) return;

    final draft = StoreReviewDraft(
      verificationMethod: widget.verificationMethod,
      benefitAnswer: widget.isMilitary ? (benefitAnswer ?? '') : '',
      visitTypeAnswer: visitTypeAnswer!,
      waitTimeAnswer: waitTimeAnswer!,
      purposeAnswer: purposeAnswer!,
      companionAnswer: companionAnswer!,
      rating: rating,
      goodPoints: goodPoints.toList(),
    );

    final result = await Navigator.push<SubmittedStoreReview>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewSubmitScreen(store: widget.store, draft: draft),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    const goodPointOptions = [
      '음식이 맛있어요',
      '양이 많아요',
      '가성비가 좋아요',
      '혼밥하기 좋아요',
      '단체로 오기 좋아요',
      '조용하고 좋아요',
    ];

    // 이전 답변이 바뀌면 이후 답변 초기화
    bool showVisitType = !widget.isMilitary || benefitAnswer != null;
    bool showWaitTime  = showVisitType && visitTypeAnswer != null;
    bool showPurpose   = showWaitTime  && waitTimeAnswer != null;
    bool showWith      = showPurpose   && purposeAnswer != null;
    bool showRating    = showWith      && companionAnswer != null;
    bool showGoodPoints = showRating   && rating > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(34, 10, 34, 18),
        child: Align(
          alignment: Alignment.centerRight,
          heightFactor: 1,
          child: ElevatedButton(
            onPressed: canSubmit ? _complete : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              disabledBackgroundColor: AppColors.surfaceSoft,
              foregroundColor: AppColors.textWhite,
              disabledForegroundColor: AppColors.textSub,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
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
          controller: _scrollController,
          padding: EdgeInsets.zero,
          children: [
            // 헤더
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 28),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 36),
                  ),
                ],
              ),
            ),

            // 1. 군인 혜택 (군인만)
            if (widget.isMilitary)
              _QuestionBlock(
                title: '군인 할인 혜택을 받으셨나요?',
                options: const ['혜택 받음', '혜택 받지 못함', '일부 받음'],
                selected: benefitAnswer,
                onSelected: (value) {
                  setState(() {
                    benefitAnswer = value;
                    visitTypeAnswer = null;
                    waitTimeAnswer = null;
                    purposeAnswer = null;
                    companionAnswer = null;
                  });
                  _autoAdvance();
                },
              ),

            // 2. 이용 방식
            if (showVisitType)
              _QuestionBlock(
                title: '어떻게 이용하셨나요?',
                options: const ['예약 없이 이용', '예약 후 이용', '포장·배달 이용'],
                selected: visitTypeAnswer,
                onSelected: (value) {
                  setState(() {
                    visitTypeAnswer = value;
                    waitTimeAnswer = null;
                    purposeAnswer = null;
                    companionAnswer = null;
                  });
                  _autoAdvance();
                },
              ),

            // 3. 대기 시간
            if (showWaitTime)
              _QuestionBlock(
                title: '대기 시간은 어떠셨나요?',
                options: const ['바로 입장', '10분 이내', '30분 이내', '1시간 이내', '1시간 이상'],
                selected: waitTimeAnswer,
                onSelected: (value) {
                  setState(() {
                    waitTimeAnswer = value;
                    purposeAnswer = null;
                    companionAnswer = null;
                  });
                  _autoAdvance();
                },
              ),

            // 4. 방문 목적
            if (showPurpose)
              _QuestionBlock(
                title: '방문하신 목적은 무엇인가요?',
                options: const ['데이트', '외출', '외박', '휴가', '회식'],
                selected: purposeAnswer,
                onSelected: (value) {
                  setState(() {
                    purposeAnswer = value;
                    companionAnswer = null;
                  });
                  _autoAdvance();
                },
              ),

            // 5. 동행자
            if (showWith)
              _QuestionBlock(
                title: '누구와 함께했나요?',
                options: const ['연인', '가족', '친구', '혼자'],
                selected: companionAnswer,
                onSelected: (value) {
                  setState(() => companionAnswer = value);
                  _autoAdvance();
                },
              ),

            // 6. 별점
            if (showRating)
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(34, 28, 34, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '얼마나 만족하셨나요?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    HalfStarRating(
                      rating: rating,
                      onChanged: (value) {
                        setState(() => rating = value);
                        _autoAdvance();
                      },
                    ),
                  ],
                ),
              ),

            // 7. 좋았던 점
            if (showGoodPoints)
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(34, 20, 34, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '어떤 점이 좋았나요?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 14,
                      children: goodPointOptions.map((option) {
                        final selected = goodPoints.contains(option);
                        return _MilitaryChoiceChip(
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
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 14,
            children: options.map((option) {
              return _MilitaryChoiceChip(
                label: option,
                selected: selected == option,
                onTap: () => onSelected(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MilitaryChoiceChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MilitaryChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_MilitaryChoiceChip> createState() => _MilitaryChoiceChipState();
}

class _MilitaryChoiceChipState extends State<_MilitaryChoiceChip> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = pressed
        ? AppColors.pressed
        : widget.selected
        ? AppColors.selected
        : AppColors.surfaceSoft;

    final borderColor = widget.selected ? AppColors.pressed : AppColors.border;
    final textColor = pressed || widget.selected
        ? AppColors.textWhite
        : AppColors.textMain;

    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapCancel: () => setState(() => pressed = false),
      onTapUp: (_) => setState(() => pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minWidth: 118),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: borderColor,
              width: widget.selected ? 2.5 : 1.5,
            ),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class HalfStarRating extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onChanged;

  const HalfStarRating({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  void _updateRating(BuildContext context, Offset localPosition) {
    final box = context.findRenderObject() as RenderBox;
    final width = box.size.width;
    final raw = (localPosition.dx / width * 5).clamp(0.5, 5.0);
    onChanged((raw * 2).ceil() / 2);
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
          final fill = (rating - index).clamp(0.0, 1.0);
          return _PartialStar(fill: fill);
        }),
      ),
    );
  }
}

class _PartialStar extends StatelessWidget {
  final double fill;

  const _PartialStar({required this.fill});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        children: [
          const Icon(Icons.star, size: 56, color: Color(0xFFF0F0F0)),
          ClipRect(
            clipper: _StarClipper(fill),
            child: const Icon(Icons.star, size: 56, color: Color(0xFFFFD600)),
          ),
        ],
      ),
    );
  }
}

class _StarClipper extends CustomClipper<Rect> {
  final double fill;
  _StarClipper(this.fill);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fill, size.height);

  @override
  bool shouldReclip(covariant _StarClipper old) => old.fill != fill;
}
