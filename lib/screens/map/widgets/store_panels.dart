part of '../benefit_map.dart';

class _StoreListPanel extends StatefulWidget {
  final List<Store> stores;
  final Store? selectedStore;
  final bool loading;
  final bool loadingMore;
  final bool hasNext;
  final String? categoryLabel;
  final String activeKeyword;
  final double? radius;
  final ValueChanged<double?> onRadiusChanged;
  final VoidCallback onLoadMore;
  final ValueChanged<Store> onTapStore;
  final ValueChanged<Store> onOpenDetail;

  const _StoreListPanel({
    required this.stores,
    required this.selectedStore,
    required this.loading,
    required this.loadingMore,
    required this.hasNext,
    required this.categoryLabel,
    required this.activeKeyword,
    required this.radius,
    required this.onRadiusChanged,
    required this.onLoadMore,
    required this.onTapStore,
    required this.onOpenDetail,
  });

  @override
  State<_StoreListPanel> createState() => _StoreListPanelState();
}

class _StoreListPanelState extends State<_StoreListPanel> {
  ScrollController? _scrollController;

  void _onScroll() {
    final sc = _scrollController;
    if (sc == null || !sc.hasClients) return;
    if (sc.position.pixels >= sc.position.maxScrollExtent - 300) {
      widget.onLoadMore();
    }
  }

  void _attachController(ScrollController controller) {
    if (_scrollController == controller) return;
    _scrollController?.removeListener(_onScroll);
    _scrollController = controller;
    _scrollController!.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  String get _headerTitle {
    if (widget.activeKeyword.isNotEmpty) {
      return '"${widget.activeKeyword}" 검색 결과';
    }
    if (widget.categoryLabel == null || widget.categoryLabel!.isEmpty) {
      return '전체 매장';
    }
    return widget.categoryLabel!;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      minChildSize: 0.16,
      initialChildSize: 0.38,
      maxChildSize: 0.86,
      snap: true,
      snapSizes: const [0.16, 0.38, 0.86],
      builder: (context, scrollController) {
        _attachController(scrollController);

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
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _headerTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  const Icon(Icons.sort, size: 18, color: AppColors.textSub),
                  const SizedBox(width: 4),
                  const Text(
                    '거리순',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (widget.activeKeyword.isEmpty)
                Row(
                  children: [
                    const Icon(Icons.radar, size: 16, color: AppColors.textSub),
                    const SizedBox(width: 6),
                    const Text(
                      '반경',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSub,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<double?>(
                          value: widget.radius,
                          isDense: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.textSub,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                          items: [
                            const DropdownMenuItem<double?>(
                              value: null,
                              child: Text('선택 안함'),
                            ),
                            ..._kRadiusOptions.map((r) {
                              return DropdownMenuItem<double?>(
                                value: r,
                                child: Text('${r.toInt()}km'),
                              );
                            }),
                          ],
                          onChanged: (r) => widget.onRadiusChanged(r),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              if (widget.loading)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryAccent,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (widget.stores.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      '주변에 해당 매장이 없습니다.',
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else ...[
                ...widget.stores.map((store) {
                  final selected = widget.selectedStore?.id == store.id;
                  return _StoreListItem(
                    store: store,
                    selected: selected,
                    onTap: () => widget.onTapStore(store),
                    onOpenDetail: () => widget.onOpenDetail(store),
                  );
                }),
                if (widget.loadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAccent,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                if (!widget.hasNext && widget.stores.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: Text(
                        widget.radius != null
                            ? '반경 ${widget.radius!.toInt()}km 내 모든 매장을 불러왔습니다.'
                            : '모든 매장을 불러왔습니다.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StoreListItem extends StatelessWidget {
  final Store store;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onOpenDetail;

  const _StoreListItem({
    required this.store,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.primaryAccent
                            : AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        store.categoryLabel,
                        if (store.distanceKm != null) store.distanceLabel,
                        if (store.maxDiscountRate != null)
                          '최대 ${store.maxDiscountRate}% 할인',
                      ].join(' · '),
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

class _StoreBottomSheet extends StatefulWidget {
  final Store store;
  final VoidCallback onClose;
  final Future<void> Function() onDetailTap;

  const _StoreBottomSheet({
    required this.store,
    required this.onClose,
    required this.onDetailTap,
  });

  @override
  State<_StoreBottomSheet> createState() => _StoreBottomSheetState();
}

class _StoreBottomSheetState extends State<_StoreBottomSheet> {
  static const double _minSize = 0.24;
  static const double _initialSize = 0.38;
  static const double _maxSize = 0.86;
  static const double _openThreshold = 0.82;
  static const double _resetThreshold = 0.72;

  final DraggableScrollableController _dragController =
      DraggableScrollableController();

  bool _openedDetail = false;
  bool _canTriggerFromDrag = true;

  Store get store => widget.store;

  @override
  void didUpdateWidget(covariant _StoreBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store.id != widget.store.id) {
      _openedDetail = false;
      _canTriggerFromDrag = true;
      if (_dragController.isAttached) {
        _dragController.jumpTo(_initialSize);
      }
    }
  }

  bool get _hasBusinessHours {
    return store.openTime != null && store.closeTime != null;
  }

  bool get _isOpenNow {
    if (!_hasBusinessHours) return false;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final open = _parseTime(store.openTime!);
    final close = _parseTime(store.closeTime!);

    if (open == null || close == null) return false;

    final openMinutes = open.hour * 60 + open.minute;
    final closeMinutes = close.hour * 60 + close.minute;

    if (closeMinutes < openMinutes) {
      return currentMinutes >= openMinutes || currentMinutes <= closeMinutes;
    }

    return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
  }

  String get _businessStatusLabel {
    if (!_hasBusinessHours) return '운영 확인';
    return _isOpenNow ? '영업 중' : '영업 종료';
  }

  Color get _businessStatusBackground {
    if (!_hasBusinessHours) return const Color(0xFFF1F1F1);
    return _isOpenNow ? AppColors.badge : const Color(0xFFF1F1F1);
  }

  Color get _businessStatusTextColor {
    if (!_hasBusinessHours) return AppColors.textSub;
    return _isOpenNow ? AppColors.badgeText : AppColors.textSub;
  }

  ({int hour, int minute})? _parseTime(String value) {
    final parts = value.split(':');

    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    return (hour: hour, minute: minute);
  }

  Future<void> _resetSheet() async {
    if (!_dragController.isAttached) return;

    try {
      await _dragController.animateTo(
        _initialSize,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } catch (_) {
      if (_dragController.isAttached) {
        _dragController.jumpTo(_initialSize);
      }
    }
  }

  Future<void> _openDetailFromDrag() async {
    if (_openedDetail || !_canTriggerFromDrag) return;

    _openedDetail = true;
    _canTriggerFromDrag = false;

    await _resetSheet();

    try {
      await widget.onDetailTap();
    } finally {
      if (!mounted) return;

      setState(() {
        _openedDetail = false;
        _canTriggerFromDrag = true;
      });

      await _resetSheet();
    }
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        final extent = notification.extent;

        if (extent < _resetThreshold) {
          _canTriggerFromDrag = true;
        }

        if (extent >= _openThreshold && _canTriggerFromDrag && !_openedDetail) {
          _openDetailFromDrag();
        }

        return false;
      },
      child: DraggableScrollableSheet(
        controller: _dragController,
        minChildSize: _minSize,
        initialChildSize: _initialSize,
        maxChildSize: _maxSize,
        snap: true,
        snapSizes: const [_minSize, _initialSize, _maxSize],
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _BusinessStatusBadge(
                        label: _businessStatusLabel,
                        backgroundColor: _businessStatusBackground,
                        textColor: _businessStatusTextColor,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.primaryAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          store.mainBenefitDescription,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _hasBusinessHours
                        ? '현재 $_businessStatusLabel · ${store.closeTimeLabel}'
                        : '운영 시간 확인 필요',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSub,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    store.distanceLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSub,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await widget.onDetailTap();
                        if (mounted) {
                          await _resetSheet();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '상세 보기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BusinessStatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _BusinessStatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
