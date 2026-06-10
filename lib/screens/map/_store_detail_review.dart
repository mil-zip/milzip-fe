part of 'store_detail_screen.dart';

class _ReviewTabContent extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final List<StoreReview> serverReviews;
  final List<SubmittedStoreReview> submittedReviews;

  const _ReviewTabContent({
    required this.rating,
    required this.reviewCount,
    required this.serverReviews,
    required this.submittedReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewSummary(
            rating: rating,
            reviewCount: reviewCount,
            serverReviews: serverReviews,
            submittedReviews: submittedReviews,
          ),
          const SizedBox(height: 28),
          const Divider(color: AppColors.border),
          const SizedBox(height: 22),
          if (serverReviews.isEmpty && submittedReviews.isEmpty)
            const _EmptyReviewMessage()
          else ...[
            ...serverReviews.map(_ServerReviewCard.new),
            ...submittedReviews.map(_SubmittedReviewCard.new),
          ],
        ],
      ),
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  static const Color _rankedBackgroundColor = Color(0xFFE9DDC9);
  static const Color _rankedBorderColor = Color(0xFFD4B896);
  static const Color _rankedTextColor = Color(0xFF2D3B2D);
  static const Color _normalBackgroundColor = AppColors.surfaceSoft;
  static const Color _normalTextColor = AppColors.textMain;
  static const Color _normalCountColor = AppColors.primaryAccent;

  final double rating;
  final int reviewCount;
  final List<StoreReview> serverReviews;
  final List<SubmittedStoreReview> submittedReviews;

  const _ReviewSummary({
    required this.rating,
    required this.reviewCount,
    required this.serverReviews,
    required this.submittedReviews,
  });

  Map<String, int> get _goodPointCounts {
    final counts = <String, int>{};

    for (final review in serverReviews) {
      for (final label in review.goodPointLabels) {
        counts[label] = (counts[label] ?? 0) + 1;
      }
    }

    for (final review in submittedReviews) {
      for (final label in review.draft.goodPoints) {
        counts[label] = (counts[label] ?? 0) + 1;
      }
    }

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _goodPointCounts;

    final baseItems = [
      _ReviewSummaryItem(emoji: '🍗', label: '음식이 맛있어요', order: 0),
      _ReviewSummaryItem(emoji: '🍚', label: '양이 많아요', order: 1),
      _ReviewSummaryItem(emoji: '💰', label: '가성비가 좋아요', order: 2),
      _ReviewSummaryItem(emoji: '🍽️', label: '혼밥하기 좋아요', order: 3),
      _ReviewSummaryItem(emoji: '👥', label: '단체로 오기 좋아요', order: 4),
      _ReviewSummaryItem(emoji: '🤫', label: '조용하고 좋아요', order: 5),
      _ReviewSummaryItem(emoji: '🛋️', label: '식당 분위기가 좋아요', order: 6),
      _ReviewSummaryItem(emoji: '🏃', label: '웨이팅이 없어요', order: 7),
      _ReviewSummaryItem(emoji: '💳', label: '할인율이 높아요', order: 8),
    ];

    final sortedItems = [...baseItems]
      ..sort((a, b) {
        final aCount = counts[a.label] ?? 0;
        final bCount = counts[b.label] ?? 0;

        final countCompare = bCount.compareTo(aCount);
        if (countCompare != 0) return countCompare;

        return a.order.compareTo(b.order);
      });

    final rankedLabels = sortedItems
        .where((item) => (counts[item.label] ?? 0) > 0)
        .take(3)
        .map((item) => item.label)
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⭐ ${rating.toStringAsFixed(1)} · $reviewCount명의 군인들이 참여했어요',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textSub,
          ),
        ),
        const SizedBox(height: 18),
        ...sortedItems.map((item) {
          final count = counts[item.label] ?? 0;
          final ranked = rankedLabels.contains(item.label);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: ranked ? _rankedBackgroundColor : _normalBackgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: ranked
                  ? Border.all(color: _rankedBorderColor, width: 1.4)
                  : null,
            ),
            child: Row(
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: ranked ? FontWeight.w900 : FontWeight.w800,
                      color: ranked ? _rankedTextColor : _normalTextColor,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: ranked ? _rankedTextColor : _normalCountColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ReviewSummaryItem {
  final String emoji;
  final String label;
  final int order;

  const _ReviewSummaryItem({
    required this.emoji,
    required this.label,
    required this.order,
  });
}

class _EmptyReviewMessage extends StatelessWidget {
  const _EmptyReviewMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        '아직 등록된 리뷰가 없습니다.',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textSub,
        ),
      ),
    );
  }
}

class _ServerReviewCard extends StatelessWidget {
  final StoreReview review;

  const _ServerReviewCard(this.review);

  @override
  Widget build(BuildContext context) {
    final metaItems = [
      review.waitTimeLabel,
      review.visitPurposeLabel,
      review.visitWithLabel,
    ].where((item) => item.isNotEmpty).join(' · ');

    final reviewImages = review.imageUrls
        .where((url) => url.trim().isNotEmpty)
        .map(_StoreImageItem.network)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ProfileImage(url: review.profileImageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  review.nickname,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '★${review.rating.toStringAsFixed(1)}'
            '${review.createdDateLabel.isNotEmpty ? ' · ${review.createdDateLabel}' : ''}'
            '${metaItems.isNotEmpty ? ' · $metaItems' : ''}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textSub,
            ),
          ),
          if (review.benefitStatusLabel.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.benefitStatusLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryAccent,
              ),
            ),
          ],
          if (review.goodPointLabels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: review.goodPointLabels.map((point) {
                return _ReviewTag(label: point);
              }).toList(),
            ),
          ],
          if (review.content.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              review.content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.55,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
          ],
          if (reviewImages.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ReviewImageStrip(images: reviewImages),
          ],
        ],
      ),
    );
  }
}

class _SubmittedReviewCard extends StatelessWidget {
  final SubmittedStoreReview review;

  const _SubmittedReviewCard(this.review);

  @override
  Widget build(BuildContext context) {
    final draft = review.draft;
    final reviewImages = review.imagePaths.map(_StoreImageItem.file).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review.nickname,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '★${draft.rating.toStringAsFixed(1)} · '
            '${draft.waitTimeAnswer} · '
            '${draft.purposeAnswer} · '
            '${draft.companionAnswer}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textSub,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            draft.benefitSentence,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryAccent,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: draft.goodPoints.map((point) {
              return _ReviewTag(label: point);
            }).toList(),
          ),
          if (review.content.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              review.content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.55,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
          ],
          if (reviewImages.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ReviewImageStrip(images: reviewImages),
          ],
        ],
      ),
    );
  }
}

class _ReviewImageStrip extends StatelessWidget {
  final List<_StoreImageItem> images;

  const _ReviewImageStrip({required this.images});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openImageViewer(context, images, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 96,
                height: 96,
                child: images[index].buildImage(BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReviewTag extends StatelessWidget {
  final String label;

  const _ReviewTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.badge,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.badgeText,
        ),
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  final String? url;

  const _ProfileImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return const CircleAvatar(radius: 18, backgroundColor: Color(0xFFD9D9D9));
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFD9D9D9),
      backgroundImage: NetworkImage(imageUrl),
    );
  }
}
