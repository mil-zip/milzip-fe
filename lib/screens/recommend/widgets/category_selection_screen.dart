import 'package:flutter/material.dart';

class CategorySelectionScreen extends StatelessWidget {
  final Set<String> selectedCategories;
  final ValueChanged<String> onToggleCategory;
  final VoidCallback onProceed;

  const CategorySelectionScreen({
    super.key,
    required this.selectedCategories,
    required this.onToggleCategory,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    final topCategories = [
      ('FOOD', '식사'),
      ('CAFE', '카페'),
      ('LEISURE', '여가'),
      ('ACCOMMODATION', '숙박'),
    ];

    final allCategories = [...topCategories, ('ETC', '기타')];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ...allCategories.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value;
            final isSelected = selectedCategories.contains(cat.$1);
            final isDisabled = !isSelected && selectedCategories.length >= 3;

            return Padding(
              padding: EdgeInsets.only(bottom: i < allCategories.length - 1 ? 14 : 0),
              child: GestureDetector(
                onTap: isDisabled ? null : () => onToggleCategory(cat.$1),
                child: Opacity(
                  opacity: isDisabled ? 0.4 : 1.0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6B9358) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6B9358) : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [] : [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          cat.$2,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            '최대 3개까지 선택할 수 있습니다',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
