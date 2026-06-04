import 'package:flutter/material.dart';
import 'package:milzip/models/place.dart';
import 'package:milzip/theme/app_colors.dart';
import 'package:milzip/widgets/place_card.dart';

class FavoriteStoresScreen extends StatelessWidget {
  const FavoriteStoresScreen({super.key});

  static const _mockPlaces = [
    Place(
      id: '1',
      name: '우즈마키 문정본점',
      categories: ['일본식라멘', '돈코츠'],
      militaryDiscount: '군장병 10% 할인',
      distanceKm: 0.8,
      isMilzipRecommended: true,
    ),
    Place(
      id: '2',
      name: '굿모닝쌀국수',
      categories: ['베트남음식', '쌀국수'],
      militaryDiscount: '군장병 15% 할인',
      distanceKm: 1.2,
      isMilzipRecommended: false,
    ),
    Place(
      id: '3',
      name: '버텍스 미국식 덮밥 하월곡점',
      categories: ['덮밥', '미국식'],
      militaryDiscount: '군장병 20% 할인',
      distanceKm: 2.1,
      isMilzipRecommended: true,
    ),
    Place(
      id: '4',
      name: '로이파스타',
      categories: ['파스타', '이탈리안'],
      militaryDiscount: '군장병 10% 할인',
      distanceKm: 1.5,
      isMilzipRecommended: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.6,
        shadowColor: AppColors.border,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '즐겨찾기한 매장',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _mockPlaces.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => PlaceCard(place: _mockPlaces[index]),
      ),
    );
  }
}
