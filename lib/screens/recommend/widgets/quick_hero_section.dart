import 'dart:async';
import 'package:flutter/material.dart';
import 'package:milzip/main.dart';
import 'package:milzip/theme/app_colors.dart';

class QuickHeroSection extends StatefulWidget {
  const QuickHeroSection({super.key});

  @override
  State<QuickHeroSection> createState() => _QuickHeroSectionState();
}

class _QuickHeroSectionState extends State<QuickHeroSection>
    with TickerProviderStateMixin
    implements RouteAware {
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void didPushNext() {
    _pulseController.stop();
    _heroTimer?.cancel();
    _heroTimer = null;
  }

  @override
  void didPopNext() {
    _pulseController.repeat(reverse: true);
    _heroTimer ??= Timer.periodic(const Duration(milliseconds: 2000), (_) {
      if (mounted) setState(() => _heroIconIndex = (_heroIconIndex + 1) % _heroIcons.length);
    });
  }

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _heroTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(40, 40, 130, 0),
            child: const Column(
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
          // 애니메이션 — 우측 세로 중앙
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.centerRight,
              child: IgnorePointer(child: _buildAnimation()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimation() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, __) {
        final p = _pulseAnimation.value;
        return SizedBox(
          width: 138,
          height: 138,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110 + p * 22,
                height: 110 + p * 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary2.withAlpha((7 + p * 10).toInt()),
                ),
              ),
              Container(
                width: 86 + p * 12,
                height: 86 + p * 12,
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
                  width: 62,
                  height: 62,
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
