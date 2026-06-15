import 'package:flutter/material.dart';
import 'package:milzip/theme/app_colors.dart';

class QuickSortButton extends StatefulWidget {
  final String sortBy;
  final ValueChanged<String> onChanged;

  const QuickSortButton({
    super.key,
    required this.sortBy,
    required this.onChanged,
  });

  @override
  State<QuickSortButton> createState() => _QuickSortButtonState();
}

class _QuickSortButtonState extends State<QuickSortButton> {
  static const _options = [
    ('recommend', '추천순'),
    ('discount', '할인율순'),
    ('distance', '거리순'),
  ];

  final _buttonKey = GlobalKey();

  String get _currentLabel =>
      _options.firstWhere((o) => o.$1 == widget.sortBy).$2;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _buttonKey,
      onTap: () => _showDropdown(context),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textSub,
            ),
          ],
        ),
      ),
    );
  }

  void _showDropdown(BuildContext context) {
    final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screenWidth = MediaQuery.of(context).size.width;

    showMenu<String>(
      context: context,
      color: AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        screenWidth - (offset.dx + size.width),
        0,
      ),
      items: _options.map((opt) {
        final (value, label) = opt;
        final isSelected = widget.sortBy == value;
        return PopupMenuItem<String>(
          value: value,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? AppColors.primary2 : AppColors.textMain,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_rounded, color: AppColors.primaryAccent, size: 16),
              ],
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null && value != widget.sortBy) widget.onChanged(value);
    });
  }
}
