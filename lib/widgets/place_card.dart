import 'package:flutter/material.dart';
import 'package:milzip/models/place.dart';
import 'package:milzip/theme/app_colors.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final IconData categoryIcon;

  const PlaceCard({
    super.key,
    required this.place,
    this.categoryIcon = Icons.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 116,
              height: 116,
              color: AppColors.surfaceSoft,
              child: place.imageUrl != null
                  ? Image.network(place.imageUrl!, fit: BoxFit.cover)
                  : Icon(
                      categoryIcon,
                      size: 40,
                      color: AppColors.border,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  place.categories.join(', '),
                  style: const TextStyle(
                    color: AppColors.textSub,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                if (place.militaryDiscount != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.discountBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.discountBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shield,
                          size: 13,
                          color: AppColors.discountBorder,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          place.militaryDiscount!,
                          style: const TextStyle(
                            color: AppColors.discountText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  '${place.distanceKm}km',
                  style: const TextStyle(
                    color: AppColors.textSub,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
