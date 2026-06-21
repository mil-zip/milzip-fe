part of '../benefit_map.dart';

class _TmoInfoCard extends StatelessWidget {
  final Tmo tmo;
  final VoidCallback onClose;
  final VoidCallback onDetailTap;

  const _TmoInfoCard({
    required this.tmo,
    required this.onClose,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 16, 18),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tmo.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                _TmoStatusBadge(tmo: tmo),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoRow(label: '운영 시간', value: tmo.todayHours),
            _InfoRow(label: '현재 위치와의 거리', value: tmo.distanceLabel),
            _InfoRow(label: '전화번호', value: tmo.phoneLabel),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onDetailTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surfaceSoft,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '상세 보기',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TmoListPanel extends StatelessWidget {
  final DraggableScrollableController controller;
  final List<Tmo> tmos;
  final Tmo? selectedTmo;
  final ValueChanged<Tmo> onTapTmo;
  final ValueChanged<Tmo> onOpenDetail;

  const _TmoListPanel({
    required this.controller,
    required this.tmos,
    required this.selectedTmo,
    required this.onTapTmo,
    required this.onOpenDetail,
  });

  String _displayTmoName(Tmo tmo) {
    return tmo.name.replaceAll(' TMO', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      minChildSize: 0.16,
      initialChildSize: 0.38,
      maxChildSize: 0.86,
      snap: true,
      snapSizes: const [0.16, 0.38, 0.86],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4D4D4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'TMO 목록',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  Icon(Icons.tune, size: 18, color: AppColors.textSub),
                  SizedBox(width: 5),
                  Text(
                    '거리순',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (tmos.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      '주변 TMO 정보를 불러오는 중입니다.',
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                ...tmos.map((tmo) {
                  final selected = selectedTmo?.id == tmo.id;

                  return _TmoListItem(
                    tmo: tmo,
                    displayName: _displayTmoName(tmo),
                    selected: selected,
                    onTap: () => onTapTmo(tmo),
                    onOpenDetail: () => onOpenDetail(tmo),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _TmoListItem extends StatelessWidget {
  final Tmo tmo;
  final String displayName;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onOpenDetail;

  const _TmoListItem({
    required this.tmo,
    required this.displayName,
    required this.selected,
    required this.onTap,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceSoft : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: AppColors.border)
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: selected
                    ? AppColors.primaryAccent
                    : const Color(0xFFB8B8B8),
                size: 30,
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 58,
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '현재 위치와의 거리 ${tmo.distanceLabel}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.primaryAccent
                            : AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tmo.todayHours} · ${tmo.phoneLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOpenDetail,
                icon: const Icon(Icons.chevron_right, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TmoStatusBadge extends StatelessWidget {
  final Tmo tmo;

  const _TmoStatusBadge({required this.tmo});

  @override
  Widget build(BuildContext context) {
    final isOpen = tmo.isOpenNow;
    final hasHours = tmo.hasTodayOperatingHours;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasHours && isOpen ? AppColors.badge : const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tmo.operatingStatusLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: hasHours && isOpen ? AppColors.badgeText : AppColors.textSub,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSub,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
