import 'package:flutter/material.dart';
import 'package:milzip/theme/app_colors.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String location;
  final VoidCallback? onLocationTap;

  const AppHeader({
    super.key,
    this.location = '정릉동 산16-46',
    this.onLocationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0.6,
      shadowColor: AppColors.border,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 로고 — 좌측
            const Text(
              'MIL.ZIP',
              style: TextStyle(
                fontFamily: 'TmoneyRoundWind',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary2,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
            // 위치 — 우측 끝
            GestureDetector(
              onTap: onLocationTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.textSub,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
