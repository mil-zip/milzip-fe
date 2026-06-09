import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/tmo.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import 'tmo_service_guide_screen.dart';

class TmoDetailScreen extends StatefulWidget {
  final Tmo tmo;

  const TmoDetailScreen({super.key, required this.tmo});

  @override
  State<TmoDetailScreen> createState() => _TmoDetailScreenState();
}

class _TmoDetailScreenState extends State<TmoDetailScreen> {
  static const Color kakaoYellow = Color(0xFFFEE500);
  static const Color korailBlue = Color(0xFF0047BA);

  bool _isFavorite = false;

  Tmo get tmo => widget.tmo;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    try {
      final list = await UserService.getTmoFavorites();
      final ids = list.map((e) => (e['tmoId'] as num).toInt()).toSet();
      if (mounted) setState(() => _isFavorite = ids.contains(tmo.id));
    } catch (_) {}
  }

  Future<void> _openKakaoMap(BuildContext context) async {
    final uri = Uri.parse(tmo.kakaoMapUrl);

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      _showSnackBar(context, '카카오맵을 열 수 없습니다.');
    }
  }

  Future<void> _openKorailTalk(BuildContext context) async {
    final intentUri = Uri.parse(
      'intent://korailtalk#Intent;package=com.korail.talk;end',
    );

    final storeUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.korail.talk',
    );

    try {
      final opened = await launchUrl(
        intentUri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(storeUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _toggleFavorite() async {
    final newState = !_isFavorite;
    setState(() => _isFavorite = newState);
    try {
      if (newState) {
        await UserService.addTmoFavorite(tmo.id);
      } else {
        await UserService.removeTmoFavorite(tmo.id);
      }
      if (mounted) {
        _showSnackBar(
          context,
          newState ? 'TMO가 즐겨찾기에 저장되었습니다.' : 'TMO 즐겨찾기가 해제되었습니다.',
        );
      }
    } catch (e) {
      // 실패 시 원상복구
      if (mounted) setState(() => _isFavorite = !newState);
      if (mounted) {
        _showSnackBar(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              isFavorite: _isFavorite,
              onBack: () => Navigator.pop(context),
              onFavoriteTap: _toggleFavorite,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tmo.name,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      _StatusBadge(tmo: tmo),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.near_me_outlined,
                        size: 18,
                        color: AppColors.primaryAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '현재 위치와의 거리 ${tmo.distanceLabel}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    '운영 정보',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SimpleTableRow(label: '운영 시간', value: tmo.todayHours),
                  _SimpleTableRow(label: '평일 운영', value: tmo.weekdayHours),
                  _SimpleTableRow(label: '주말 운영', value: tmo.weekendHours),
                  _SimpleTableRow(label: '전화번호', value: tmo.phoneLabel),
                  _SimpleTableRow(
                    label: '운영 형태',
                    value: tmo.mobile ? '출장형 TMO' : '상시 운영 TMO',
                  ),
                  _SimpleTableRow(label: '점심 시간', value: '12:00 ~ 13:00'),
                  _SimpleTableRow(
                    label: '휴무일',
                    value: tmo.mobile ? '소요 시 운영' : '연중무휴',
                  ),
                  _SimpleTableRow(label: '기타 정보', value: '신분증 지참 필수'),
                  if (tmo.note != null && tmo.note!.trim().isNotEmpty)
                    _SimpleTableRow(label: '비고', value: tmo.note!),
                  const SizedBox(height: 26),
                  _PrimaryActionButton(
                    label: '카카오맵으로 이동',
                    icon: Icons.location_on,
                    backgroundColor: kakaoYellow,
                    foregroundColor: AppColors.textMain,
                    onTap: () => _openKakaoMap(context),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryActionButton(
                    label: '코레일톡으로 바로 예매하기',
                    icon: Icons.train_outlined,
                    backgroundColor: korailBlue,
                    foregroundColor: Colors.white,
                    onTap: () => _openKorailTalk(context),
                  ),
                  const SizedBox(height: 12),
                  _GuideEntryCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TmoServiceGuideScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SmallActionButton(
                          icon: _isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          label: _isFavorite ? '해제하기' : '즐겨찾기',
                          onTap: _toggleFavorite,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SmallActionButton(
                          icon: Icons.phone_outlined,
                          label: '전화하기',
                          onTap: () async {
                            if (tmo.phone == null) {
                              _showSnackBar(context, '전화번호가 없습니다.');
                              return;
                            }

                            final uri = Uri.parse('tel:${tmo.phone}');
                            await launchUrl(uri);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    '위치',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tmo.address,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSub,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 42,
                            color: AppColors.primaryAccent,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tmo.locationDescription,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _TopBar extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFavoriteTap;

  const _TopBar({
    required this.isFavorite,
    required this.onBack,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 26),
          ),
          const Spacer(),
          IconButton(
            onPressed: onFavoriteTap,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 26,
              color: isFavorite ? AppColors.primaryAccent : AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Tmo tmo;

  const _StatusBadge({required this.tmo});

  @override
  Widget build(BuildContext context) {
    final isOpen = tmo.isOpenNow;
    final hasHours = tmo.hasTodayOperatingHours;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasHours && isOpen ? AppColors.badge : const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tmo.operatingStatusLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: hasHours && isOpen ? AppColors.badgeText : AppColors.textSub,
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 22, color: foregroundColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: AppColors.textMain),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleTableRow extends StatelessWidget {
  final String label;
  final String value;

  const _SimpleTableRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSub,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideEntryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _GuideEntryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 24,
                color: AppColors.primaryAccent,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'TMO 이용 방법',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 26, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
