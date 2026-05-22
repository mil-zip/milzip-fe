import 'package:flutter/material.dart';
import '../../data/certificate_dummy.dart';
import '../../models/certificate.dart';

class SelfDevelopmentSection extends StatefulWidget {
  const SelfDevelopmentSection({super.key});

  @override
  State<SelfDevelopmentSection> createState() => _SelfDevelopmentSectionState();
}

class _SelfDevelopmentSectionState extends State<SelfDevelopmentSection> {
  late List<Certificate> _certificates;
  bool _isELearningBookmarked = false;
  bool _isCertificateBookmarked = false;

  @override
  void initState() {
    super.initState();
    _certificates = getDummyCertificates();
  }

  @override
  Widget build(BuildContext context) {
    final minRate = _certificates
        .map((certificate) => certificate.discountRate)
        .reduce((a, b) => a < b ? a : b);
    final maxRate = _certificates
        .map((certificate) => certificate.discountRate)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '복무 중 성장할 수 있는 다양한 프로그램을 지원합니다.',
            style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
          ),
        ),

        const SizedBox(height: 24),

        _BenefitCard(
          icon: Icons.school,
          iconColor: const Color(0xFF1F5ACB),
          iconBackgroundColor: const Color(0xFFDDE8FF),
          title: '군 e-러닝 (나라사랑포털)',
          description1: '어학 · 자격증 · 취업 · IT 등',
          description2: '1만여 강좌 무료',
          tag: '학업',
          isBookmarked: _isELearningBookmarked,
          onBookmarkTap: () {
            setState(() {
              _isELearningBookmarked = !_isELearningBookmarked;
            });

            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isELearningBookmarked
                      ? '군 e-러닝이(가) 저장되었습니다!'
                      : '군 e-러닝 저장이 취소되었습니다.',
                ),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 22),

        _BenefitCard(
          icon: Icons.check_box,
          iconColor: const Color(0xFF3A8A4A),
          iconBackgroundColor: const Color(0xFFDDF3D5),
          title: '어학 자격증 응시료 할인',
          description1: '토익 · 토플 · OPIC 등',
          description2: '$minRate~$maxRate% 할인',
          tag: '자격증',
          isBookmarked: _isCertificateBookmarked,
          onBookmarkTap: () {
            setState(() {
              _isCertificateBookmarked = !_isCertificateBookmarked;
            });

            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isCertificateBookmarked
                      ? '어학 자격증 할인이(가) 저장되었습니다!'
                      : '어학 자격증 할인 저장이 취소되었습니다.',
                ),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 30),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '신청 방법',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
            ),
          ),
        ),

        const SizedBox(height: 18),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _ApplySteps(),
        ),

        const SizedBox(height: 28),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _NoticeBox(),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String title;
  final String description1;
  final String description2;
  final String tag;
  final bool isBookmarked;
  final VoidCallback onBookmarkTap;

  const _BenefitCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.title,
    required this.description1,
    required this.description2,
    required this.tag,
    required this.isBookmarked,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFDADADA)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 28, 24, 28),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: iconBackgroundColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, size: 36, color: iconColor),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          description1,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF777777),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description2,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF777777),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF888888),
                    size: 28,
                  ),
                ],
              ),
            ),
            Container(
              height: 46,
              color: const Color(0xFFEDEDED),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9D9999),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onBookmarkTap,
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      size: 23,
                      color: const Color(0xFF222222),
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

class _ApplySteps extends StatelessWidget {
  const _ApplySteps();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ApplyStep(
          number: '1',
          title: '프로그램 선택',
          subtitle: '원하는 분야 선택',
          showLine: true,
        ),
        _ApplyStep(
          number: '2',
          title: '부대 행정 통해 신청',
          subtitle: '행정반 또는 복지 담당관에게 문의',
          showLine: true,
        ),
        _ApplyStep(
          number: '3',
          title: '지원금 수령 및 수강',
          subtitle: '승인 후 수강 시작',
          showLine: false,
        ),
      ],
    );
  }
}

class _ApplyStep extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final bool showLine;

  const _ApplyStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAF6),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFC9C9C9)),
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(width: 1, color: const Color(0xFFC9C9C9)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  const _NoticeBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '유의사항',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
            ),
          ),
          SizedBox(height: 12),
          Text(
            '• 프로그램별 신청 기간 및 정원이 다르므로 사전에 별도로\n'
            '  확인하시는 것을 권유하고 있습니다.\n'
            '• 지원금은 부대 예산에 따라 변동될 수 있습니다.\n'
            '• 중복 지원은 일부 프로그램에서 제한될 수 있습니다.',
            style: TextStyle(
              fontSize: 12,
              height: 1.7,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }
}
