import 'dart:async';
import 'package:flutter/material.dart';
import 'package:milzip/theme/app_colors.dart';

class QuickHeroSection extends StatefulWidget {
  const QuickHeroSection({super.key});

  @override
  State<QuickHeroSection> createState() => _QuickHeroSectionState();
}

class _QuickHeroSectionState extends State<QuickHeroSection>
    with TickerProviderStateMixin {
  static const _heroIcons = [
    Icons.restaurant,
    Icons.local_cafe,
    Icons.local_activity,
    Icons.hotel,
    Icons.local_offer,
  ];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _heroIconIndex = 0;
  Timer? _heroTimer;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    _heroTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      if (mounted) setState(() => _heroIconIndex = (_heroIconIndex + 1) % _heroIcons.length);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _insertOverlay());
  }

  void _insertOverlay() {
    if (!mounted) return;
    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        final statusBarH = MediaQuery.of(ctx).padding.top;
        const appBarH = kToolbarHeight;
        return Positioned(
          top: statusBarH + appBarH - 10,
          right: 0,
          child: IgnorePointer(child: _buildAnimation()),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _heroTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.white),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(20, 32, 130, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '밀집추천',
              style: TextStyle(
                fontFamily: 'TmoneyRoundWind',
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryAccent,
                height: 1.1,
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '근처 군장병 혜택을 빠르게 찾아드려요!',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSub,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimation() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, __) {
        final p = _pulseAnimation.value;
        return SizedBox(
          width: 158,
          height: 158,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 126 + p * 27,
                height: 126 + p * 27,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary2.withAlpha((7 + p * 10).toInt()),
                ),
              ),
              Container(
                width: 100 + p * 14,
                height: 100 + p * 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary2.withAlpha((16 + p * 20).toInt()),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 550),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: Tween<double>(begin: 0.18, end: 0.0).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                  ),
                  child: ScaleTransition(
                    scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                ),
                child: Container(
                  key: ValueKey(_heroIconIndex),
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryLight, AppColors.primary2],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary2.withAlpha((55 + p * 50).toInt()),
                        blurRadius: 20 + p * 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(_heroIcons[_heroIconIndex], color: Colors.white, size: 36),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
