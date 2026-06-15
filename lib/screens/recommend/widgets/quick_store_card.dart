import 'package:flutter/material.dart';
import 'package:milzip/models/quick_store.dart';
import 'package:milzip/models/store.dart';
import 'package:milzip/screens/map/store_detail_screen.dart';
import 'package:milzip/theme/app_colors.dart';

class QuickStoreCard extends StatelessWidget {
  final QuickStore store;

  const QuickStoreCard({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final firstImage = store.imageUrls.isNotEmpty ? store.imageUrls.first : null;
    final icon = _iconForCategory(store.category);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StoreDetailScreen(store: _toStore(store))),
      ),
      child: Container(
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
                width: 100,
                height: 100,
                color: AppColors.surfaceSoft,
                child: firstImage != null
                    ? Image.network(
                        firstImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(icon, size: 36, color: AppColors.border),
                      )
                    : Icon(icon, size: 36, color: AppColors.border),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    store.name,
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
                    store.address,
                    style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (store.maxDiscountRate > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.discountBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.discountBorder, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield, size: 13, color: AppColors.discountBorder),
                          const SizedBox(width: 4),
                          Text(
                            _discountLabel(store.maxDiscountRate),
                            style: const TextStyle(
                              color: AppColors.discountText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (store.distanceKm != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 13, color: AppColors.textSub),
                        const SizedBox(width: 3),
                        Text(
                          _distanceLabel(store.distanceKm!),
                          style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconForCategory(String category) {
    switch (category) {
      case 'FOOD': return Icons.restaurant;
      case 'CAFE': return Icons.local_cafe;
      case 'LEISURE': return Icons.local_activity;
      case 'ACCOMMODATION': return Icons.hotel;
      default: return Icons.local_offer;
    }
  }

  static String _discountLabel(int rate) {
    if (rate > 100) {
      final formatted = rate.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '$formatted원 할인';
    }
    return '$rate% 할인';
  }

  static String _distanceLabel(double km) {
    if (km < 1) return '${(km * 1000).round()}m';
    return '${km.toStringAsFixed(1)}km';
  }

  static Store _toStore(QuickStore qs) {
    return Store(
      id: qs.id,
      name: qs.name,
      category: _mapStoreCategory(qs.category),
      address: qs.address,
      latitude: qs.latitude,
      longitude: qs.longitude,
      phone: qs.phone,
      openTime: qs.openTime,
      closeTime: qs.closeTime,
      maxDiscountRate: qs.maxDiscountRate > 0 ? qs.maxDiscountRate : null,
      militaryBenefit: qs.militaryBenefit,
      benefitVerified: qs.benefitVerified,
      imageUrls: qs.imageUrls,
      distanceKm: qs.distanceKm,
    );
  }

  static StoreCategory _mapStoreCategory(String category) {
    switch (category) {
      case 'FOOD': return StoreCategory.food;
      case 'CAFE': return StoreCategory.cafe;
      case 'LEISURE': return StoreCategory.leisure;
      case 'ACCOMMODATION': return StoreCategory.accommodation;
      default: return StoreCategory.etc;
    }
  }
}
