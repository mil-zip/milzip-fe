part of '../benefit_map.dart';

class _CategoryChipBar extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String> onSelected;

  const _CategoryChipBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  _CategoryChipData _dataFor(String category) {
    switch (category) {
      case '음식':
        return const _CategoryChipData(
          icon: Icons.restaurant_menu,
          label: '음식',
        );
      case '숙박':
        return const _CategoryChipData(icon: Icons.hotel_outlined, label: '숙박');
      case 'PC방':
        return const _CategoryChipData(
          icon: Icons.desktop_windows_outlined,
          label: 'PC방',
        );
      case '서비스':
        return const _CategoryChipData(
          icon: Icons.local_cafe_outlined,
          label: '서비스',
        );
      case 'TMO':
        return const _CategoryChipData(
          icon: Icons.train_outlined,
          label: 'TMO',
        );
      default:
        return _CategoryChipData(label: category);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == category;
          final data = _dataFor(category);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(category),
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary2 : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (data.icon != null) ...[
                      Icon(
                        data.icon,
                        size: 19,
                        color: selected
                            ? Colors.white
                            : AppColors.primaryAccent,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      data.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : AppColors.primaryAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChipData {
  final IconData? icon;
  final String label;

  const _CategoryChipData({this.icon, required this.label});
}
