import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';

class TmoServiceGuideScreen extends StatelessWidget {
  const TmoServiceGuideScreen({super.key});

  Future<void> _openKorailTalk(BuildContext context) async {
    final appScheme = Uri.parse('korailtalk://');
    final androidStore = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.korail.talk',
    );
    final iosStore = Uri.parse(
      'https://apps.apple.com/kr/app/%EC%BD%94%EB%A0%88%EC%9D%BC%ED%86%A1/id1000558562',
    );

    try {
      if (await canLaunchUrl(appScheme)) {
        await launchUrl(appScheme, mode: LaunchMode.externalApplication);
        return;
      }

      final fallbackUrl = Theme.of(context).platform == TargetPlatform.iOS
          ? iosStore
          : androidStore;

      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('코레일톡을 열 수 없습니다. 앱 설치 여부를 확인해주세요.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 28,
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),
            ),

            InkWell(
              onTap: () => _openKorailTalk(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
                color: const Color(0xFFEAF3FF),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Image.asset(
                        'assets/images/train.png',
                        height: 84,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.train,
                            size: 74,
                            color: Color(0xFF666666),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 18),
                    const Expanded(
                      flex: 5,
                      child: Text(
                        'KTX · SRT\n좌석 확인 후\n코레일톡 예매',
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF486B9E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 34, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TMO 이용 방법',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMain,
                      ),
                    ),

                    const SizedBox(height: 32),

                    Row(
                      children: const [
                        Expanded(
                          child: _GuideStep(
                            icon: Icons.description_outlined,
                            title: '휴가증\n발급',
                            subtitle: '소속 부대',
                          ),
                        ),
                        _StepLine(),
                        Expanded(
                          child: _GuideStep(
                            icon: Icons.train_outlined,
                            title: 'TMO\n방문',
                            subtitle: '인근 역',
                          ),
                        ),
                        _StepLine(),
                        Expanded(
                          child: _GuideStep(
                            icon: Icons.confirmation_number_outlined,
                            title: '열차\n예매',
                            subtitle: '휴가증 제시',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            Icons.info_outline,
                            size: 24,
                            color: Color(0xFF2468D8),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'TMO 방문 전 운영 시간을 확인하고, 코레일톡 예매 후 TMO에서 승차권 교환이 가능합니다.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2468D8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text(
                        'TMO는 군 장병의 이동 편의를 지원하는 교통 안내 창구입니다. 방문 전 운영 여부와 필요 서류를 확인하면 더 빠르게 이용할 수 있습니다.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.55,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSub,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _GuideStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F4),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD6D6D0)),
          ),
          child: Icon(icon, size: 32, color: AppColors.textMain),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFFAAAAAA),
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 54),
      color: const Color(0xFFD6D6D0),
    );
  }
}
