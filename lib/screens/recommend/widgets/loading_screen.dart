import 'dart:async';
import 'package:flutter/material.dart';
import 'package:milzip/models/ai_recommend_result.dart';
import 'package:milzip/theme/app_colors.dart';

class LoadingScreen extends StatefulWidget {
  final Future<AiRecommendResult> future;
  final ValueChanged<AiRecommendResult> onDone;
  final ValueChanged<String> onError;

  const LoadingScreen({
    super.key,
    required this.future,
    required this.onDone,
    required this.onError,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  static const _stepMs = 2000;
  static const _items = [
    '현재 위치 기준 거리 분석',
    '군장병 혜택 적용 매장 확인',
    'AI가 최적 코스 생성 중',
  ];

  static const _heroIcons = [
    Icons.restaurant,
    Icons.local_cafe,
    Icons.local_activity,
    Icons.hotel,
    Icons.local_offer,
  ];

  // 1단계: 0→80% (phase1)
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // 2단계: 80→100% (completion)
  late AnimationController _completionController;
  late Animation<double> _completionAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _heroIconIndex = 0;
  int _visibleCount = 0;
  Timer? _heroTimer;

  bool _animDone = false;
  bool _completing = false;
  AiRecommendResult? _result;

  @override
  void initState() {
    super.initState();

    // 펄스 아이콘
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation =
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

    // 1단계 프로그레스: 0→1 (표시는 *0.8 = 80%)
    final totalMs = _stepMs * (_items.length + 1); // 4000ms
    _progressController = AnimationController(
      duration: Duration(milliseconds: totalMs),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );
    _progressController.forward();

    // 2단계 프로그레스: 80→100%, API완료+1단계완료 후 시작
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _completionAnimation = CurvedAnimation(
      parent: _completionController,
      curve: Curves.easeOut,
    );
    _completionController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && _result != null) {
        widget.onDone(_result!);
      }
    });

    // 아이콘 순환
    _heroTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (mounted) {
        setState(
            () => _heroIconIndex = (_heroIconIndex + 1) % _heroIcons.length);
      }
    });

    // 체크리스트 항목 순차 표시
    for (int i = 0; i < _items.length; i++) {
      Future.delayed(Duration(milliseconds: _stepMs * (i + 1)), () {
        if (mounted) setState(() => _visibleCount = i + 1);
      });
    }

    // 1단계 완료 시점
    Future.delayed(Duration(milliseconds: totalMs), () {
      if (mounted) {
        _animDone = true;
        _tryComplete();
      }
    });

    // API 완료 대기
    widget.future.then((result) {
      _result = result;
      _tryComplete();
    }).catchError((Object e) {
      if (mounted) widget.onError(e.toString().replaceFirst('Exception: ', ''));
    });
  }

  void _tryComplete() {
    if (_animDone && _result != null && !_completing && mounted) {
      _completing = true;
      _completionController.forward();
    }
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildPulseIcon(),
                const SizedBox(height: 18),
                const Text(
                  'AI가 코스를 만들고 있어요',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '위치, 혜택, 만족도를 기준으로\n가장 알맞은 코스를 분석 중이에요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                // 진행도 바: 1단계(0→80%) + 2단계(80→100%)
                AnimatedBuilder(
                  animation: Listenable.merge(
                      [_progressAnimation, _completionAnimation]),
                  builder: (context, _) {
                    final val = _progressAnimation.value * 0.8 +
                        _completionAnimation.value * 0.2;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: val,
                        minHeight: 8,
                        backgroundColor: Colors.grey[100],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),
                Column(
                  children: [
                    for (int i = 0; i < _items.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == _items.length - 1 ? 0 : 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              i < _visibleCount
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 21,
                              color: i < _visibleCount
                                  ? AppColors.primary2
                                  : Colors.grey[300],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _items[i],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: i < _visibleCount
                                      ? Colors.grey[800]
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary2.withAlpha(18),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary2,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '잠시만 기다리면\n추천 코스를 바로 확인할 수 있어요',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        final p = _pulseAnimation.value;
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 92 + p * 18,
                height: 92 + p * 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary2.withAlpha(18),
                ),
              ),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary2,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary2.withAlpha(45),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: CurvedAnimation(
                        parent: anim, curve: Curves.easeOutBack),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    _heroIcons[_heroIconIndex],
                    key: ValueKey(_heroIconIndex),
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
