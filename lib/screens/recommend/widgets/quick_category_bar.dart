import 'package:flutter/material.dart';
import 'package:milzip/theme/app_colors.dart';

class QuickCategoryBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const QuickCategoryBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  static const _icons = [
    Icons.restaurant,
    Icons.local_cafe,
    Icons.local_activity,
    Icons.hotel,
    Icons.more_horiz,
  ];

  static const _labels = ['음식', '카페', '여가', '숙박', '기타'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_labels.length, _buildItem),
      ),
    );
  }

  Widget _buildItem(int index) {
    final isSelected = index == selectedIndex;
    return GestureDetector(
      onTap: () {
        if (selectedIndex != index) onSelect(index);
      },
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.surfaceSoft : const Color(0xFFF7F7F7),
                border: Border.all(
                  color: isSelected ? AppColors.primary2 : AppColors.border,
                  width: isSelected ? 2.0 : 1.2,
                ),
              ),
              child: Icon(
                _icons[index],
                size: 26,
                color: isSelected ? AppColors.primary2 : const Color(0xFFBBBBBB),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _labels[index],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primary2 : const Color(0xFFAAAAAA),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
