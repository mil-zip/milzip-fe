part of 'store_detail_screen.dart';

class _HomeTabContent extends StatelessWidget {
  final Store store;

  const _HomeTabContent({required this.store});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          _InfoLine(icon: Icons.push_pin, text: store.address),
          _InfoLine(
            icon: Icons.access_time,
            text: '운영 시간 ${store.businessHours}',
          ),
          _InfoLine(icon: Icons.phone, text: store.phoneLabel),
          _InfoLine(
            icon: Icons.local_offer_outlined,
            text: store.mainBenefitDescription,
          ),
        ],
      ),
    );
  }
}

class _BenefitTabContent extends StatelessWidget {
  final Store store;

  const _BenefitTabContent({required this.store});

  @override
  Widget build(BuildContext context) {
    final benefits = store.benefits;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '군 장병 혜택',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 14),
          if (benefits.isEmpty)
            const Text(
              '등록된 혜택 정보가 없습니다.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textSub,
              ),
            )
          else
            ...benefits.map(
              (benefit) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefit.description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    if (benefit.conditionText != null &&
                        benefit.conditionText!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        benefit.conditionText!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoTabContent extends StatelessWidget {
  final List<_StoreImageItem> images;
  final ValueChanged<int> onImageTap;

  const _PhotoTabContent({required this.images, required this.onImageTap});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Text(
          '등록된 사진이 없습니다.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textSub,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => onImageTap(index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: images[index].buildImage(BoxFit.cover),
          ),
        );
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 23, color: AppColors.textSub),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSub,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
